import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_clipboard_flutter/constants/paths.dart';
import 'package:sync_clipboard_flutter/dio/sync_clipboard_client.dart';
import 'package:sync_clipboard_flutter/model/app_settings/app_settings.dart';
import 'package:sync_clipboard_flutter/model/clipboard/clipboard.dart' as clipboard_model;

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  // 创建 Logger 实例 - 用于记录日志
  final Logger _log = Logger();
  
  // 手动上传相关状态
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadingFileName = '';

  /// 获取唯一的文件名，如果存在同名文件则在文件名后添加 _1, _2, _3...
  /// 
  /// 例如：
  /// - 如果 test.txt 已存在，返回 test_1.txt
  /// - 如果 test_1.txt 也存在，返回 test_2.txt
  /// - 以此类推
  Future<String> _getUniqueFilename(String directory,
      String originalFilename) async {
    // 分离文件名和扩展名
    final lastDotIndex = originalFilename.lastIndexOf('.');
    String baseName;
    String extension;
    
    if (lastDotIndex != -1 && lastDotIndex > 0) {
      // 有扩展名的情况，例如 "test.txt"
      baseName = originalFilename.substring(0, lastDotIndex);
      extension = originalFilename.substring(lastDotIndex); // 包含点号，例如 ".txt"
    } else {
      // 没有扩展名的情况
      baseName = originalFilename;
      extension = '';
    }
    
    // 检查原始文件名是否存在
    String candidatePath = '$directory/$originalFilename';
    if (!await File(candidatePath).exists()) {
      _log.d('文件不存在，使用原始文件名: $originalFilename');
      return originalFilename;
    }
    
    // 文件存在，尝试添加递增数字后缀
    int counter = 1;
    while (true) {
      final newFilename = '${baseName}_$counter$extension';
      candidatePath = '$directory/$newFilename';

      if (!await File(candidatePath).exists()) {
        _log.i('找到可用文件名: $newFilename (原文件名: $originalFilename)');
        return newFilename;
      }
      
      counter++;
      
      // 安全检查：避免无限循环（虽然理论上不太可能）
      if (counter > 99) {
        _log.w('文件重命名尝试次数过多，使用时间戳');
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        return '${baseName}_$timestamp$extension';
      }
    }
  }


  // 上传剪贴板
  Future<void> _uploadClipboard() async {
    try {
      _log.i('开始上传剪贴板...');
      
      // 1. 读取系统剪贴板内容
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      
      if (clipboardData == null || clipboardData.text == null || clipboardData.text!.isEmpty) {
        Fluttertoast.showToast(
          msg: '剪贴板为空，没有可上传的内容',
        );
        _log.w('剪贴板为空');
        return;
      }
      
      final clipboardText = clipboardData.text!;
      _log.d('读取到剪贴板内容，长度: ${clipboardText.length}');
      
      // 2. 创建 Clipboard 对象
      final clipboard = clipboard_model.Clipboard(
        file: '',  // 文本类型不需要文件路径
        clipboard: clipboardText,
        type: clipboard_model.ClipboardType.text,
      );
      
      // 3. 上传到服务器
      final client = await SyncClipboardClient.create();
      _log.i('开始上传到服务器: ${client.config.url}');
      await client.putSyncClipboardJson(clipboard);
      
      _log.i('上传剪贴板成功');
      
      Fluttertoast.showToast(
        msg: '剪贴版内容上传成功！🎉',
      );
    } on SyncClipboardException catch (e) {
      _log.e('上传剪贴板失败 - 业务异常', error: e);
      
      Fluttertoast.showToast(
        msg: '上传失败：${e.message}',
      );
    } catch (e) {
      _log.e('上传剪贴板失败 - 未知错误', error: e);
      
      Fluttertoast.showToast(
        msg: '上传失败：$e',
      );
    }
  }

  // 下载剪贴板
  Future<void> _downloadClipboard() async {
    try {
      _log.i('开始下载剪贴板...');
      
      // 1. 从服务器获取剪贴板数据
      final client = await SyncClipboardClient.create();
      _log.i('开始从服务器下载: ${client.config.url}');
      final clipboard = await client.getSyncClipboardJson();
      
      _log.d('下载到剪贴板数据 - 类型: ${clipboard.type.name}, 内容长度: ${clipboard.clipboard.length}');

      // 2. 根据类型处理剪贴板数据
      switch (clipboard.type) {
        case clipboard_model.ClipboardType.text:
        // 文本类型：将内容写入系统剪贴板
          await Clipboard.setData(ClipboardData(text: clipboard.clipboard));
          _log.i('已将文本写入系统剪贴板');

          Fluttertoast.showToast(
            msg: '已将以下内容写入剪贴版:\n${clipboard.clipboard}',
          );
          break;

        case clipboard_model.ClipboardType.image:
        case clipboard_model.ClipboardType.file:
        // 图片和文件类型：从服务器下载文件并保存到 Download 文件夹
          final filename = clipboard.file;

          if (filename.isEmpty) {
            _log.w('文件名为空，无法下载');
            Fluttertoast.showToast(
              msg: '错误：文件名为空',
            );
            return;
          }

          _log.i('开始下载文件: $filename');
          final fileBytes = await client.getSyncClipboardFile(filename);

          // 获取唯一的文件名（如果存在同名文件，会自动添加 _1, _2, _3... 后缀）
          final uniqueFilename = await _getUniqueFilename(
              AppPaths.androidDownloadDir, filename);
          
          // 保存文件到 Download 文件夹
          final downloadPath = '${AppPaths.androidDownloadDir}/$uniqueFilename';
          final file = File(downloadPath);
          await file.writeAsBytes(fileBytes);

          // 通知 Android 系统扫描文件
          await MediaScanner.loadMedia(path: downloadPath);

          _log.i('文件已下载到 Download 文件夹: $downloadPath');

          Fluttertoast.showToast(
            msg: '文件已下载到 Download 文件夹\n$uniqueFilename',
          );
          break;

        case clipboard_model.ClipboardType.group:
        // Group 类型：下载 zip 文件并解压到带时间戳的文件夹
          final filename = clipboard.file;

          if (filename.isEmpty) {
            _log.w('文件名为空，无法下载');
            Fluttertoast.showToast(
              msg: '错误：文件名为空',
            );
            return;
          }

          _log.i('开始下载 group 文件: $filename');
          final fileBytes = await client.getSyncClipboardFile(filename);

          // 创建带时间戳的文件夹名：SyncClipboard_2025-12-06_20-38-04
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
                // 创建目录
                await Directory(filePath).create(recursive: true);
                _log.d('创建目录: ${file.name}');
              }
            }

            _log.i('解压完成，共 ${archive.length} 个文件/文件夹');

            // 通知 Android 系统扫描整个文件夹
            await MediaScanner.loadMedia(path: extractPath);

            Fluttertoast.showToast(
              msg: '已解压到 Download 文件夹\n$folderName',
              toastLength: Toast.LENGTH_LONG,
            );
          } catch (e) {
            _log.e('解压失败', error: e);
            Fluttertoast.showToast(
              msg: '解压失败：$e',
            );
          }
          break;
      }
    } on SyncClipboardException catch (e) {
      _log.e('下载剪贴板失败 - 业务异常', error: e);
      
      Fluttertoast.showToast(
        msg: '下载失败：${e.message}',
      );
    } catch (e) {
      _log.e('下载剪贴板失败 - 未知错误', error: e);
      
      Fluttertoast.showToast(
        msg: '下载失败：$e',
      );
    }
  }

  /// 手动上传文件
  Future<void> _uploadFile() async {
    try {
      // 1. 检查是否需要显示提示对话框
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('app_settings');
      final settings = settingsJson != null
          ? appSettingsFromJson(settingsJson)
          : const AppSettings();

      if (!settings.manualUploadDialogShown) {
        // 显示提示对话框
        final shouldContinue = await _showTipDialog();
        if (!shouldContinue) {
          return;
        }

        // 保存已显示过对话框的状态
        final updatedSettings = settings.copyWith(manualUploadDialogShown: true);
        await prefs.setString('app_settings', appSettingsToJson(updatedSettings));
      }

      // 2. 调用文件选择器并上传
      await _pickAndUploadFile();
    } catch (e) {
      _log.e('手动上传文件失败', error: e);
      Fluttertoast.showToast(
        msg: '操作失败：$e',
      );
    }
  }

  /// 显示提示对话框
  /// 返回 true 表示用户点击了"我知道了"，false 表示用户取消
  Future<bool> _showTipDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber),
              SizedBox(width: 8),
              Text('小提示'),
            ],
          ),
          content: const Text(
            '本 App 支持从相册或文件管理器中，长按文件后选择"分享"到本 App 直接上传，这样使用起来更加方便快捷！',
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('我知道了'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// 选择文件并上传
  Future<void> _pickAndUploadFile() async {
    try {
      // 1. 打开文件选择器
      _log.i('打开文件选择器...');
      final result = await FilePicker.platform.pickFiles();

      if (result == null) {
        // 用户取消选择
        _log.d('用户取消了文件选择');
        return;
      }

      // 2. 获取文件信息
      final platformFile = result.files.first;
      final filename = platformFile.name;
      final Uint8List fileBytes;

      if (platformFile.bytes != null) {
        // Web 平台
        fileBytes = platformFile.bytes!;
      } else if (platformFile.path != null) {
        // 移动/桌面平台
        final file = File(platformFile.path!);
        fileBytes = await file.readAsBytes();
      } else {
        throw Exception('无法读取文件内容');
      }

      _log.i('选择文件: $filename, 大小: ${fileBytes.length} bytes');

      // 3. 开始上传
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _uploadingFileName = filename;
      });

      final client = await SyncClipboardClient.create();
      _log.i('开始上传文件到服务器: ${client.config.url}');

      await client.putSyncClipboardFile(
        filename,
        fileBytes,
        onSendProgress: (sent, total) {
          if (total != -1) {
            setState(() {
              _uploadProgress = sent / total;
            });
          }
        },
      );

      // 计算文件的 MD5
      final fileMd5 = md5.convert(fileBytes).toString();
      _log.d('文件 MD5: $fileMd5');

      // 根据文件扩展名判断类型
      final ext = p.extension(filename).toLowerCase(); // 返回 .jpg 格式
      const imageExtensions = ['.jpg', '.jpeg', '.gif', '.bmp', '.png', '.heic', '.heif', '.webp', '.avif'];
      final clipboardType = imageExtensions.contains(ext)
          ? clipboard_model.ClipboardType.image
          : clipboard_model.ClipboardType.file;
      _log.d('文件类型: ${clipboardType.name}');

      // 4. 更新 SyncClipboard.json
      final clipboard = clipboard_model.Clipboard(
        file: filename,
        clipboard: fileMd5,
        type: clipboardType,
      );
      await client.putSyncClipboardJson(clipboard);

      _log.i('文件上传成功: $filename');

      setState(() {
        _isUploading = false;
      });

      Fluttertoast.showToast(
        msg: '文件上传成功！\n$filename',
      );
    } on SyncClipboardException catch (e) {
      _log.e('上传失败 - 业务异常', error: e);
      setState(() {
        _isUploading = false;
      });
      Fluttertoast.showToast(
        msg: '上传失败：${e.message}',
      );
    } catch (e) {
      _log.e('上传失败 - 未知错误', error: e);
      setState(() {
        _isUploading = false;
      });
      Fluttertoast.showToast(
        msg: '上传失败：$e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '调试功能',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            '测试剪贴板上传和下载功能',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          // 上传剪贴板按钮
          FilledButton.icon(
            onPressed: _uploadClipboard,
            icon: const Icon(Icons.upload),
            label: const Text('上传剪贴板'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 下载剪贴板按钮
          FilledButton.icon(
            onPressed: _downloadClipboard,
            icon: const Icon(Icons.download),
            label: const Text('下载剪贴板'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 手动上传文件按钮
          FilledButton.icon(
            onPressed: _isUploading ? null : _uploadFile,
            icon: _isUploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.upload_file),
            label: Text(
              _isUploading
                  ? '上传中... ${(_uploadProgress * 100).toStringAsFixed(0)}%'
                  : '手动上传文件',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          
          if (_isUploading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _uploadProgress),
            const SizedBox(height: 8),
            Text(
              '正在上传: $_uploadingFileName',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
