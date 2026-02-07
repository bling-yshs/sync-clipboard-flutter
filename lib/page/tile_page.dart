import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:sync_clipboard_flutter/constants/paths.dart';
import 'package:sync_clipboard_flutter/dio/sync_clipboard_client.dart';
import 'package:sync_clipboard_flutter/model/clipboard/clipboard.dart' as clipboard_model;
import 'package:sync_clipboard_flutter/utils/clipboard_utils.dart';

/// 磁贴透明页面 - 上传剪贴板
class TileUploadPage extends StatefulWidget {
  const TileUploadPage({super.key});

  @override
  State<TileUploadPage> createState() => _TileUploadPageState();
}

class _TileUploadPageState extends State<TileUploadPage> {
  final Logger _log = Logger();
  String _message = '正在上传剪贴板...';
  bool _isUploading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _uploadClipboard();
  }

  /// 轮询获取剪贴板内容，每200毫秒重试一次，最多3秒
  Future<ClipboardData?> _getClipboardWithRetry() async {
    const maxAttempts = 15; // 3秒 / 200毫秒 = 15次
    for (int i = 0; i < maxAttempts; i++) {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData != null && clipboardData.text != null && clipboardData.text!.isNotEmpty) {
        _log.i('第 ${i + 1} 次尝试获取剪贴板成功');
        return clipboardData;
      }
      _log.d('第 ${i + 1} 次尝试获取剪贴板失败，200毫秒后重试...');
      await Future.delayed(const Duration(milliseconds: 200));
    }
    return null;
  }

  Future<void> _uploadClipboard() async {
    try {
      _log.i('开始上传剪贴板...');
      
      // 轮询获取剪贴板内容
      final clipboardData = await _getClipboardWithRetry();
      
      if (clipboardData == null) {
        setState(() {
          _message = '剪贴板为空';
          _isUploading = false;
          _hasError = true;
        });
        _log.w('剪贴板为空（已重试3秒）');
        return;
      }
      
      final clipboardText = clipboardData.text!;
      _log.d('读取到剪贴板内容，长度: ${clipboardText.length}');
      
      // 2. 创建 Clipboard 对象
      final payload = buildTextClipboardPayload(clipboardText);

      // 3. 上传到服务器
      final client = await SyncClipboardClient.create();
      _log.i('开始上传到服务器: ${client.config.url}');
      if (payload.hasDataFile) {
        await client.putSyncClipboardFile(
          payload.dataName!,
          payload.dataBytes!,
        );
      }
      await client.putSyncClipboardJson(payload.clipboard);
      
      _log.i('上传剪贴板成功');
      
      // 显示成功提示并立即退出
      Fluttertoast.showToast(
        msg: '剪贴版内容上传成功！🎉',
      );
      SystemNavigator.pop();
    } on SyncClipboardException catch (e) {
      _log.e('上传剪贴板失败 - 业务异常', error: e);
      setState(() {
        _message = '上传失败：${e.message}';
        _isUploading = false;
        _hasError = true;
      });
    } catch (e) {
      _log.e('上传剪贴板失败 - 未知错误', error: e);
      setState(() {
        _message = '上传失败：$e';
        _isUploading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TileOverlayPage(
      message: _message,
      icon: _hasError ? Icons.error : Icons.upload,
      isLoading: _isUploading,
      iconColor: _hasError ? Colors.red : Colors.white,
    );
  }
}

/// 磁贴透明页面 - 下载剪贴板
class TileDownloadPage extends StatefulWidget {
  const TileDownloadPage({super.key});

  @override
  State<TileDownloadPage> createState() => _TileDownloadPageState();
}

class _TileDownloadPageState extends State<TileDownloadPage> {
  final Logger _log = Logger();
  String _message = '正在下载剪贴板...';
  bool _isDownloading = true;
  bool _hasError = false;
  double _downloadProgress = 0.0;
  bool _showProgress = false;

  @override
  void initState() {
    super.initState();
    _downloadClipboard();
  }

  /// 获取唯一的文件名
  Future<String> _getUniqueFilename(String directory, String originalFilename) async {
    final lastDotIndex = originalFilename.lastIndexOf('.');
    String baseName;
    String extension;
    
    if (lastDotIndex != -1 && lastDotIndex > 0) {
      baseName = originalFilename.substring(0, lastDotIndex);
      extension = originalFilename.substring(lastDotIndex);
    } else {
      baseName = originalFilename;
      extension = '';
    }
    
    String candidatePath = '$directory/$originalFilename';
    if (!await File(candidatePath).exists()) {
      return originalFilename;
    }
    
    int counter = 1;
    while (true) {
      final newFilename = '${baseName}_$counter$extension';
      candidatePath = '$directory/$newFilename';
      if (!await File(candidatePath).exists()) {
        return newFilename;
      }
      counter++;
      if (counter > 99) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        return '${baseName}_$timestamp$extension';
      }
    }
  }

  Future<void> _downloadClipboard() async {
    try {
      _log.i('开始下载剪贴板...');
      
      // 1. 从服务器获取剪贴板数据
      final client = await SyncClipboardClient.create();
      _log.i('开始从服务器下载: ${client.config.url}');
      final clipboard = await client.getSyncClipboardJson();
      
      _log.d('下载到剪贴板数据 - 类型: ${clipboard.type.name}, 预览长度: ${clipboard.text.length}');

      // 2. 根据类型处理剪贴板数据
      switch (clipboard.type) {
        case clipboard_model.ClipboardType.text:
          // 文本类型：必要时下载完整内容并校验 hash
          var resolvedText = clipboard.text;
          if (clipboard.hasData) {
            final dataName = clipboard.dataName;
            if (dataName == null || dataName.isEmpty) {
              throw SyncClipboardException('缺少 dataName，无法下载文本内容');
            }
            final dataBytes = await client.getSyncClipboardFile(dataName);
            resolvedText = utf8.decode(dataBytes);
          }

          await Clipboard.setData(ClipboardData(text: resolvedText));
          _log.i('已将文本写入系统剪贴板');

          // 显示成功提示并立即退出
          Fluttertoast.showToast(
            msg: '已将以下内容写入剪贴版:\n$resolvedText',
          );
          SystemNavigator.pop();
          break;

        case clipboard_model.ClipboardType.image:
        case clipboard_model.ClipboardType.file:
          // 图片和文件类型：从服务器下载文件并保存到 Download 文件夹
          final filename = clipboard.dataName ?? '';

          if (filename.isEmpty) {
            _log.w('文件名为空，无法下载');
            setState(() {
              _message = '错误：文件名为空';
              _isDownloading = false;
              _hasError = true;
            });
            return;
          }

          setState(() {
            _message = '正在下载文件...';
            _showProgress = true;
          });

          _log.i('开始下载文件: $filename');
          final fileBytes = await client.getSyncClipboardFile(
            filename,
            onReceiveProgress: (received, total) {
              if (total != -1) {
                setState(() {
                  _downloadProgress = received / total;
                  _message = '正在下载：${(received / 1024 / 1024).toStringAsFixed(1)}MB / ${(total / 1024 / 1024).toStringAsFixed(1)}MB';
                });
              }
            },
          );

          // 获取唯一的文件名
          final uniqueFilename = await _getUniqueFilename(AppPaths.androidDownloadDir, filename);

          // 保存文件到 Download 文件夹
          final downloadPath = '${AppPaths.androidDownloadDir}/$uniqueFilename';
          final file = File(downloadPath);
          await file.writeAsBytes(fileBytes);

          // 通知 Android 系统扫描文件
          await MediaScanner.loadMedia(path: downloadPath);

          _log.i('文件已下载到 Download 文件夹: $downloadPath');

          // 显示成功提示并立即退出
          Fluttertoast.showToast(
            msg: '文件已下载到 Download 文件夹\n$uniqueFilename',
          );
          SystemNavigator.pop();
          break;

        case clipboard_model.ClipboardType.group:
          // Group 类型：下载 zip 文件并解压到带时间戳的文件夹
          final filename = clipboard.dataName ?? '';

          if (filename.isEmpty) {
            _log.w('文件名为空，无法下载');
            setState(() {
              _message = '错误：文件名为空';
              _isDownloading = false;
              _hasError = true;
            });
            return;
          }

          setState(() {
            _message = '正在下载压缩包...';
            _showProgress = true;
          });

          _log.i('开始下载 group 文件: $filename');
          final fileBytes = await client.getSyncClipboardFile(
            filename,
            onReceiveProgress: (received, total) {
              if (total != -1) {
                setState(() {
                  _downloadProgress = received / total;
                  _message = '正在下载：${(received / 1024 / 1024).toStringAsFixed(1)}MB / ${(total / 1024 / 1024).toStringAsFixed(1)}MB';
                });
              }
            },
          );

          setState(() {
            _message = '正在解压文件...';
            _showProgress = false;
          });

          // 创建带时间戳的文件夹名
          final now = DateTime.now();
          final formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
          final folderName = 'SyncClipboard_${formatter.format(now)}';
          final extractPath = '${AppPaths.androidDownloadDir}/$folderName';

          // 创建解压目标文件夹
          final extractDir = Directory(extractPath);
          await extractDir.create(recursive: true);
          _log.i('创建解压目录: $extractPath');

          // 解压 zip 文件
          try {
            final archive = ZipDecoder().decodeBytes(fileBytes);

            for (final file in archive) {
              final filePath = '$extractPath/${file.name}';

              if (file.isFile) {
                final outFile = File(filePath);
                await outFile.create(recursive: true);
                await outFile.writeAsBytes(file.content as List<int>);
                _log.d('解压文件: ${file.name}');
              } else {
                await Directory(filePath).create(recursive: true);
                _log.d('创建目录: ${file.name}');
              }
            }

            _log.i('解压完成，共 ${archive.length} 个文件/文件夹');

            // 通知 Android 系统扫描整个文件夹
            await MediaScanner.loadMedia(path: extractPath);

            // 显示成功提示并立即退出
            Fluttertoast.showToast(
              msg: '已解压到 Download 文件夹！\n$folderName',
              toastLength: Toast.LENGTH_LONG,
            );
            SystemNavigator.pop();
          } catch (e) {
            _log.e('解压失败', error: e);
            setState(() {
              _message = '解压失败：$e';
              _isDownloading = false;
              _hasError = true;
            });
          }
          break;
      }
    } on SyncClipboardException catch (e) {
      _log.e('下载剪贴板失败 - 业务异常', error: e);
      setState(() {
        _message = '下载失败：${e.message}';
        _isDownloading = false;
        _hasError = true;
        _showProgress = false;
      });
    } catch (e) {
      _log.e('下载剪贴板失败 - 未知错误', error: e);
      setState(() {
        _message = '下载失败：$e';
        _isDownloading = false;
        _hasError = true;
        _showProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TileOverlayPage(
      message: _message,
      icon: _hasError ? Icons.error : Icons.download,
      isLoading: _isDownloading,
      downloadProgress: _showProgress ? _downloadProgress : null,
      iconColor: _hasError ? Colors.red : Colors.white,
    );
  }
}

/// 磁贴透明页面的通用实现
/// 
/// 显示一个居中的半透明卡片，背景完全透明
class _TileOverlayPage extends StatelessWidget {
  final String message;
  final IconData icon;
  final bool isLoading;
  final double? downloadProgress;
  final Color iconColor;

  const _TileOverlayPage({
    required this.message,
    required this.icon,
    this.isLoading = false,
    this.downloadProgress,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 关键：背景设为完全透明
      backgroundColor: Colors.transparent,
      // 点击空白区域关闭页面
      body: GestureDetector(
        onTap: () {
          if (!isLoading) {
            SystemNavigator.pop();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: GestureDetector(
              // 阻止点击卡片时触发外层的 onTap
              onTap: () {},
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  // 半透明黑色背景
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  // 添加阴影效果
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 图标或加载指示器
                    if (isLoading)
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    else
                      Icon(
                        icon,
                        size: 48,
                        color: iconColor,
                      ),
                    const SizedBox(height: 16),
                    
                    // 文本消息
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    // 下载进度条
                    if (downloadProgress != null) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: downloadProgress,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(downloadProgress! * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                    
                    // 提示文本
                    if (!isLoading) ...[
                      const SizedBox(height: 16),
                      Text(
                        '点击空白处关闭',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
