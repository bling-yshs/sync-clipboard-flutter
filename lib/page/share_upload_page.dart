import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:sync_clipboard_flutter/dio/sync_clipboard_client.dart';
import 'package:sync_clipboard_flutter/model/clipboard/clipboard.dart'
    as clipboard_model;
import 'package:sync_clipboard_flutter/service/app_logger.dart';
import 'package:sync_clipboard_flutter/utils/clipboard_utils.dart';
import 'package:uri_content/uri_content.dart';

/// MethodChannel 用于从 Android 获取分享数据
const _shareChannel = MethodChannel('com.yshs.sync_clipboard_flutter/share');

/// 分享文本上传页面
class ShareTextUploadPage extends StatefulWidget {
  const ShareTextUploadPage({super.key});

  @override
  State<ShareTextUploadPage> createState() => _ShareTextUploadPageState();
}

class _ShareTextUploadPageState extends State<ShareTextUploadPage> {
  final Logger _log = AppLogger.logger;
  String _message = '正在上传分享的文本...';
  bool _isUploading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _uploadSharedText();
  }

  Future<void> _uploadSharedText() async {
    try {
      _log.i('开始获取分享的文本...');

      // 从 Android 获取分享的文本
      final sharedText = await _shareChannel.invokeMethod<String>(
        'getSharedText',
      );

      if (sharedText == null || sharedText.isEmpty) {
        setState(() {
          _message = '没有收到分享的文本';
          _isUploading = false;
          _hasError = true;
        });
        return;
      }

      _log.d('收到分享文本，长度: ${sharedText.length}');

      // 创建 Clipboard 对象
      final payload = buildTextClipboardPayload(sharedText);

      // 上传到服务器
      final client = await SyncClipboardClient.create();
      _log.i('开始上传到服务器: ${client.config.url}');
      if (payload.hasDataFile) {
        await client.putSyncClipboardFile(
          payload.dataName!,
          payload.dataBytes!,
        );
      }
      await client.putSyncClipboardJson(payload.clipboard);

      _log.i('分享文本上传成功');

      Fluttertoast.showToast(msg: '分享文本上传成功！🎉');
      SystemNavigator.pop();
    } on SyncClipboardException catch (e) {
      _log.e('上传失败 - 业务异常', error: e, stackTrace: StackTrace.current);
      setState(() {
        _message = '上传失败：${e.message}';
        _isUploading = false;
        _hasError = true;
      });
    } catch (e) {
      _log.e('上传失败 - 未知错误', error: e, stackTrace: StackTrace.current);
      setState(() {
        _message = '上传失败：$e';
        _isUploading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ShareOverlayPage(
      message: _message,
      icon: _hasError ? Icons.error : Icons.text_snippet,
      isLoading: _isUploading,
      iconColor: _hasError ? Colors.red : Colors.white,
    );
  }
}

/// 分享文件上传页面
class ShareFileUploadPage extends StatefulWidget {
  const ShareFileUploadPage({super.key});

  @override
  State<ShareFileUploadPage> createState() => _ShareFileUploadPageState();
}

class _ShareFileUploadPageState extends State<ShareFileUploadPage> {
  final Logger _log = AppLogger.logger;
  String _message = '正在上传分享的文件...';
  bool _isUploading = true;
  bool _hasError = false;
  double _uploadProgress = 0.0;
  bool _showProgress = false;

  @override
  void initState() {
    super.initState();
    _uploadSharedFile();
  }

  Future<void> _uploadSharedFile() async {
    final stopwatch = Stopwatch()..start();
    var shouldClosePage = false;
    try {
      _log.i('开始获取分享的文件...');

      // 从 Android 获取分享的文件
      final result = await _shareChannel.invokeMethod<Map>('getSharedFile');
      if (result == null) {
        setState(() {
          _message = '没有收到分享的文件';
          _isUploading = false;
          _hasError = true;
        });
        return;
      }

      final filename = result['filename'] as String;
      final uriText = result['uri'] as String;

      if (uriText.isEmpty) {
        throw StateError('分享文件 uri 为空');
      }

      final uri = Uri.parse(uriText);
      final uriContent = UriContent();
      _log.d(
        '收到分享文件 uri: $filename, 获取耗时: ${stopwatch.elapsedMilliseconds}ms',
      );

      setState(() {
        _message = '正在准备: $filename';
        _showProgress = true;
      });

      // 根据文件扩展名判断类型
      final ext = p.extension(filename).toLowerCase();
      const imageExtensions = [
        '.jpg',
        '.jpeg',
        '.gif',
        '.bmp',
        '.png',
        '.heic',
        '.heif',
        '.webp',
        '.avif',
      ];
      final clipboardType = imageExtensions.contains(ext)
          ? clipboard_model.ClipboardType.image
          : clipboard_model.ClipboardType.file;
      _log.d('文件类型: ${clipboardType.name}');

      // 流式构建 SyncClipboard.json 内容
      _log.d('开始构建分享文件剪贴板元数据');
      final measuredPayload = await buildFileClipboardFromStream(
        filename: filename,
        stream: uriContent.getContentStream(uri),
        type: clipboardType,
      );
      final measuredSize = measuredPayload.size;
      final measuredSizeMb = measuredSize / 1024 / 1024;
      if (measuredSize <= 0) {
        throw SyncClipboardException('分享文件实测大小为 0，无法上传');
      }
      _log.d(
        '分享文件剪贴板元数据构建完成: filename=$filename, size=$measuredSize (${measuredSizeMb.toStringAsFixed(2)}MB), hash=${measuredPayload.clipboard.hash}',
      );

      // 上传文件
      final client = await SyncClipboardClient.create();
      _log.i(
        '开始上传文件到服务器: ${client.config.url}, Content-Length 使用 Dart 实测大小: $measuredSize, 距开始获取已耗时: ${stopwatch.elapsedMilliseconds}ms',
      );

      await client.putSyncClipboardFileStream(
        filename,
        uriContent.getContentStream(uri),
        contentLength: measuredSize,
        onSendProgress: (sent, total) {
          if (total != -1) {
            setState(() {
              _uploadProgress = sent / total;
              _message =
                  '正在上传：${(sent / 1024 / 1024).toStringAsFixed(1)}MB / ${(total / 1024 / 1024).toStringAsFixed(1)}MB';
            });
          }
        },
      );
      _log.i('分享文件主体上传完成，耗时: ${stopwatch.elapsedMilliseconds}ms');

      // 更新 SyncClipboard.json
      await client.putSyncClipboardJson(measuredPayload.clipboard);

      _log.i('分享文件上传成功: $filename, 总耗时: ${stopwatch.elapsedMilliseconds}ms');

      Fluttertoast.showToast(msg: '文件上传成功！\n$filename');
      shouldClosePage = true;
    } on PlatformException catch (e) {
      _log.e(
        '获取分享文件失败 - 平台通道异常，耗时: ${stopwatch.elapsedMilliseconds}ms, code: ${e.code}, message: ${e.message}, details: ${e.details}',
        error: e,
        stackTrace: StackTrace.current,
      );
      setState(() {
        _message = '上传失败：${e.message ?? e.code}';
        _isUploading = false;
        _hasError = true;
        _showProgress = false;
      });
    } on SyncClipboardException catch (e) {
      _log.e(
        '上传失败 - 业务异常，耗时: ${stopwatch.elapsedMilliseconds}ms',
        error: e,
        stackTrace: StackTrace.current,
      );
      setState(() {
        _message = '上传失败：${e.message}';
        _isUploading = false;
        _hasError = true;
        _showProgress = false;
      });
    } catch (e) {
      _log.e(
        '上传失败 - 未知错误，耗时: ${stopwatch.elapsedMilliseconds}ms',
        error: e,
        stackTrace: StackTrace.current,
      );
      setState(() {
        _message = '上传失败：$e';
        _isUploading = false;
        _hasError = true;
        _showProgress = false;
      });
    } finally {
      if (shouldClosePage) {
        await SystemNavigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ShareOverlayPage(
      message: _message,
      icon: _hasError ? Icons.error : Icons.insert_drive_file,
      isLoading: _isUploading,
      uploadProgress: _showProgress ? _uploadProgress : null,
      iconColor: _hasError ? Colors.red : Colors.white,
    );
  }
}

/// 分享上传页面的通用透明背景实现
class _ShareOverlayPage extends StatelessWidget {
  final String message;
  final IconData icon;
  final bool isLoading;
  final double? uploadProgress;
  final Color iconColor;

  const _ShareOverlayPage({
    required this.message,
    required this.icon,
    this.isLoading = false,
    this.uploadProgress,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
              onTap: () {},
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
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
                      Icon(icon, size: 48, color: iconColor),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (uploadProgress != null) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: uploadProgress,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(uploadProgress! * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
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
