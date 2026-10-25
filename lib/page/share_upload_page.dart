import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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

  /// 获取 Android 分享文件并按单文件或 Group 流程上传。
  ///
  /// 成功后关闭分享页面，失败时保留页面并展示错误。
  Future<void> _uploadSharedFile() async {
    final stopwatch = Stopwatch()..start();
    var shouldClosePage = false;
    try {
      _log.i('开始获取分享的文件...');

      // 从 Android 获取分享的文件
      final results = await _shareChannel.invokeMethod<List<dynamic>>(
        'getSharedFiles',
      );
      if (results == null || results.isEmpty) {
        setState(() {
          _message = '没有收到分享的文件';
          _isUploading = false;
          _hasError = true;
        });
        return;
      }

      final sharedFiles = <({String filename, Uri uri})>[];
      for (final result in results) {
        if (result is! Map) {
          throw StateError('分享文件数据格式错误');
        }
        final filename = (result['filename'] ?? 'shared_file').toString();
        final uriText = (result['uri'] ?? '').toString();
        if (uriText.isEmpty) {
          throw StateError('分享文件 uri 为空');
        }
        sharedFiles.add((filename: filename, uri: Uri.parse(uriText)));
      }

      final uriContent = UriContent();
      if (sharedFiles.length == 1) {
        await _uploadSingleSharedFile(
          sharedFiles.single,
          uriContent,
          stopwatch,
        );
      } else {
        await _uploadSharedGroup(sharedFiles, uriContent, stopwatch);
      }
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

  /// 上传单个 Android 分享文件。
  ///
  /// [sharedFile] 包含展示文件名和 content uri，[uriContent] 用于读取内容，
  /// [stopwatch] 用于记录完整分享流程耗时。
  /// 成功时返回完成的 Future，失败时抛出业务或平台异常。
  Future<void> _uploadSingleSharedFile(
    ({String filename, Uri uri}) sharedFile,
    UriContent uriContent,
    Stopwatch stopwatch,
  ) async {
    final filename = sharedFile.filename;
    final uri = sharedFile.uri;
    _log.d('收到分享文件 uri: $filename, 获取耗时: ${stopwatch.elapsedMilliseconds}ms');

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
  }

  /// 将多个 Android 分享文件打包为 Group 并上传。
  ///
  /// [sharedFiles] 是待上传文件列表，[uriContent] 用于流式读取 content uri，
  /// [stopwatch] 用于记录完整分享流程耗时。
  /// 成功时返回完成的 Future，并始终清理本次创建的临时目录。
  Future<void> _uploadSharedGroup(
    List<({String filename, Uri uri})> sharedFiles,
    UriContent uriContent,
    Stopwatch stopwatch,
  ) async {
    Directory? workingDirectory;
    try {
      final temporaryDirectory = await getTemporaryDirectory();
      workingDirectory = await temporaryDirectory.createTemp('shared_group_');
      final filesDirectory = Directory(p.join(workingDirectory.path, 'files'));
      await filesDirectory.create();

      final usedNames = <String>{};
      final entries = <GroupClipboardEntry>[];
      for (var index = 0; index < sharedFiles.length; index++) {
        final sharedFile = sharedFiles[index];
        final filename = _resolveUniqueFilename(sharedFile.filename, usedNames);
        setState(() {
          _message = '正在准备 ${index + 1}/${sharedFiles.length}: $filename';
          _showProgress = true;
          _uploadProgress = index / sharedFiles.length;
        });

        final outputFile = File(p.join(filesDirectory.path, filename));
        final output = outputFile.openWrite();
        final digestOutput = _DigestResultSink();
        final digestInput = sha256.startChunkedConversion(digestOutput);
        var size = 0;
        try {
          await for (final chunk in uriContent.getContentStream(
            sharedFile.uri,
          )) {
            output.add(chunk);
            digestInput.add(chunk);
            size += chunk.length;
          }
        } finally {
          digestInput.close();
          await output.close();
        }

        final digest = digestOutput.value;
        if (digest == null) {
          throw StateError('文件 Hash 计算失败: $filename');
        }
        entries.add(
          GroupClipboardEntry(
            name: filename,
            size: size,
            contentHash: digest.toString().toUpperCase(),
          ),
        );
      }

      final clipboard = buildGroupClipboard(entries);
      final dataName = clipboard.dataName!;
      final zipFile = File(p.join(workingDirectory.path, dataName));
      final zipPath = zipFile.path;
      final zipEntries = entries
          .map(
            (entry) => (
              name: entry.name,
              path: p.join(filesDirectory.path, entry.name),
            ),
          )
          .toList();

      setState(() {
        _message = '正在打包 ${entries.length} 个文件...';
        _showProgress = false;
      });
      // 通过顶层函数 + compute 打包，避免闭包捕获 async 方法上下文导致
      // isolate 消息里携带不可发送的 _Future
      await compute(_encodeGroupZip, (zipPath: zipPath, entries: zipEntries));

      final zipSize = await zipFile.length();
      final client = await SyncClipboardClient.create();
      setState(() {
        _message = '正在上传 ${entries.length} 个文件...';
        _showProgress = true;
        _uploadProgress = 0;
      });
      _log.i(
        '开始上传 Group: files=${entries.length}, originalSize=${clipboard.size}, zipSize=$zipSize, hash=${clipboard.hash}',
      );
      await client.putSyncClipboardFileStream(
        dataName,
        zipFile.openRead(),
        contentLength: zipSize,
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
      await client.putSyncClipboardJson(clipboard);

      _log.i(
        'Group 上传成功: files=${entries.length}, dataName=$dataName, 总耗时: ${stopwatch.elapsedMilliseconds}ms',
      );
      Fluttertoast.showToast(msg: '多文件上传成功！\n共 ${entries.length} 个文件');
    } finally {
      final directory = workingDirectory;
      if (directory != null) {
        try {
          if (await directory.exists()) {
            await directory.delete(recursive: true);
          }
        } catch (e) {
          _log.w('清理分享临时目录失败: ${directory.path}', error: e);
        }
      }
    }
  }

  /// 生成安全且在当前 Group 中唯一的 ZIP 条目名。
  ///
  /// [rawName] 是 content provider 返回的名称，[usedNames] 保存已占用名称。
  /// 返回移除路径信息后的文件名，重名时在扩展名前追加递增序号。
  String _resolveUniqueFilename(String rawName, Set<String> usedNames) {
    final normalized = rawName
        .trim()
        .replaceAll('\\', '/')
        .replaceAll('\u0000', '');
    final baseName = p.basename(normalized);
    final safeName = baseName.isEmpty || baseName == '.' || baseName == '..'
        ? 'shared_file'
        : baseName;
    var candidate = safeName;
    var suffix = 2;
    while (!usedNames.add(candidate.toLowerCase())) {
      final extension = p.extension(safeName);
      final nameWithoutExtension = p.basenameWithoutExtension(safeName);
      candidate = '$nameWithoutExtension ($suffix)$extension';
      suffix++;
    }
    return candidate;
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

/// 在后台 isolate 中将平铺文件打包为 store 模式 ZIP。
///
/// [request] 携带 ZIP 输出路径和条目名到源文件路径的列表。
/// 必须是顶层函数并通过 compute 调用：直接向 Isolate.run 传闭包会连带
/// 捕获外层 async 方法的上下文（含不可发送的 _Future），导致发送失败。
void _encodeGroupZip(
  ({String zipPath, List<({String name, String path})> entries}) request,
) {
  final encoder = ZipFileEncoder();
  encoder.create(request.zipPath);
  try {
    for (final entry in request.entries) {
      // store 模式，避免 Deflate 编码器把单个文件的压缩结果完整缓存在内存
      final archiveFile = ArchiveFile.stream(
        entry.name,
        InputFileStream(entry.path),
      )..compression = CompressionType.none;
      encoder.addArchiveFile(archiveFile);
    }
  } finally {
    encoder.closeSync();
  }
}

/// 收集流式 SHA-256 计算结果。
class _DigestResultSink implements Sink<Digest> {
  Digest? value;

  /// 保存最终的 SHA-256 摘要。
  ///
  /// [data] 是 chunked conversion 产生的摘要。
  /// 此方法无返回值。
  @override
  void add(Digest data) {
    value = data;
  }

  /// 结束摘要收集。
  ///
  /// 此方法无参数和返回值。
  @override
  void close() {}
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
