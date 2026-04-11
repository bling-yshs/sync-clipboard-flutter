import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:super_clipboard/super_clipboard.dart';
import 'package:sync_clipboard_flutter/dio/sync_clipboard_client.dart';
import 'package:sync_clipboard_flutter/model/clipboard/clipboard.dart'
    as clipboard_model;
import 'package:sync_clipboard_flutter/service/app_logger.dart';
import 'package:sync_clipboard_flutter/utils/clipboard_utils.dart';

class PreparedClipboardUpload {
  final clipboard_model.Clipboard clipboard;
  final String? dataName;
  final Uint8List? dataBytes;
  final String successMessage;

  const PreparedClipboardUpload({
    required this.clipboard,
    required this.successMessage,
    this.dataName,
    this.dataBytes,
  });

  bool get hasDataFile =>
      dataName != null && dataName!.isNotEmpty && dataBytes != null;
}

class ClipboardUploadService {
  ClipboardUploadService();

  final Logger _log = AppLogger.logger;

  Future<PreparedClipboardUpload> readClipboardForUpload() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      throw SyncClipboardException('当前平台不支持增强剪贴板读取');
    }

    final reader = await clipboard.read();
    if (reader.items.isEmpty) {
      throw SyncClipboardException('剪贴板为空');
    }

    for (final item in reader.items) {
      final imageUpload = await _readImageUpload(item);
      if (imageUpload != null) {
        return imageUpload;
      }
    }

    for (final item in reader.items) {
      if (!_shouldReadAsBinaryFirst(item)) {
        continue;
      }
      final fileUpload = await _readGenericFileUpload(item);
      if (fileUpload != null) {
        return fileUpload;
      }
    }

    final textUpload = await _readTextUploadWithFlutterClipboard();
    if (textUpload != null) {
      return textUpload;
    }

    for (final item in reader.items) {
      if (item.canProvide(Formats.plainText) ||
          item.canProvide(Formats.htmlText)) {
        continue;
      }
      final fileUpload = await _readGenericFileUpload(item);
      if (fileUpload != null) {
        return fileUpload;
      }
    }

    throw SyncClipboardException('暂不支持当前剪贴板内容');
  }

  Future<void> uploadPreparedClipboard(
    PreparedClipboardUpload prepared, {
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final client = await SyncClipboardClient.create();
    _log.i('开始上传到服务器: ${client.config.url}');

    if (prepared.hasDataFile) {
      await client.putSyncClipboardFile(
        prepared.dataName!,
        prepared.dataBytes!,
        onSendProgress: onSendProgress,
      );
    }

    await client.putSyncClipboardJson(prepared.clipboard);
  }

  PreparedClipboardUpload _buildTextUpload(String text) {
    final payload = buildTextClipboardPayload(text);
    return PreparedClipboardUpload(
      clipboard: payload.clipboard,
      dataName: payload.dataName,
      dataBytes: payload.dataBytes == null
          ? null
          : Uint8List.fromList(payload.dataBytes!),
      successMessage: '剪贴板文本上传成功！',
    );
  }

  Future<PreparedClipboardUpload?> _readTextUploadWithFlutterClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final normalizedText = clipboardData?.text?.trim();
    if (normalizedText == null || normalizedText.isEmpty) {
      return null;
    }

    _log.d('通过 Flutter Clipboard 读取到文本，长度: ${normalizedText.length}');
    return _buildTextUpload(normalizedText);
  }

  Future<PreparedClipboardUpload?> _readImageUpload(
    ClipboardDataReader item,
  ) async {
    for (final candidate in _imageCandidates) {
      final fileResult = await _readFile(item, candidate.format);
      if (fileResult == null || fileResult.bytes.isEmpty) {
        continue;
      }

      final filename = _resolveSuggestedFilename(
        suggestedName: fileResult.fileName ?? await item.getSuggestedName(),
        fallbackBaseName: 'clipboard_image',
        extension: candidate.extension,
      );

      _log.d(
        '通过 super_clipboard 读取到图片: $filename, 大小: ${fileResult.bytes.length} bytes',
      );
      return PreparedClipboardUpload(
        clipboard: buildFileClipboard(
          filename: filename,
          bytes: fileResult.bytes,
          type: clipboard_model.ClipboardType.image,
        ),
        dataName: filename,
        dataBytes: fileResult.bytes,
        successMessage: '剪贴板图片上传成功！\n$filename',
      );
    }
    return null;
  }

  Future<PreparedClipboardUpload?> _readGenericFileUpload(
    ClipboardDataReader item,
  ) async {
    final fileResult = await _readFile(item, null);
    if (fileResult == null || fileResult.bytes.isEmpty) {
      return null;
    }

    final filename = _resolveSuggestedFilename(
      suggestedName: fileResult.fileName ?? await item.getSuggestedName(),
      fallbackBaseName: 'clipboard_data',
      extension: 'bin',
    );
    final type = _inferFileType(filename);

    _log.d(
      '通过 super_clipboard 兜底读取到二进制内容: $filename, 类型: ${type.name}, 大小: ${fileResult.bytes.length} bytes',
    );

    return PreparedClipboardUpload(
      clipboard: buildFileClipboard(
        filename: filename,
        bytes: fileResult.bytes,
        type: type,
      ),
      dataName: filename,
      dataBytes: fileResult.bytes,
      successMessage: type == clipboard_model.ClipboardType.image
          ? '剪贴板图片上传成功！\n$filename'
          : '剪贴板文件上传成功！\n$filename',
    );
  }

  Future<_ReadFileResult?> _readFile(
    ClipboardDataReader item,
    FileFormat? format,
  ) async {
    final completer = Completer<_ReadFileResult?>();
    final progress = item.getFile(
      format,
      (file) async {
        try {
          final bytes = await file.readAll();
          completer.complete(
            _ReadFileResult(
              bytes: bytes,
              fileName: file.fileName,
            ),
          );
        } catch (e) {
          completer.completeError(e);
        }
      },
      onError: (error) {
        completer.completeError(error);
      },
    );
    if (progress == null) {
      completer.complete(null);
    }
    return completer.future;
  }

  clipboard_model.ClipboardType _inferFileType(String filename) {
    final ext = p.extension(filename).toLowerCase();
    if (_imageExtensions.contains(ext)) {
      return clipboard_model.ClipboardType.image;
    }
    return clipboard_model.ClipboardType.file;
  }

  String _resolveSuggestedFilename({
    required String? suggestedName,
    required String fallbackBaseName,
    required String extension,
  }) {
    final rawName = suggestedName?.trim();
    if (rawName == null || rawName.isEmpty) {
      return '$fallbackBaseName.$extension';
    }

    final fileName = p.basename(rawName);
    if (p.extension(fileName).isNotEmpty) {
      return fileName;
    }
    return '$fileName.$extension';
  }

  bool _shouldReadAsBinaryFirst(ClipboardDataReader item) {
    final formats = item.platformFormats.map((format) => format.toLowerCase());
    for (final format in formats) {
      if (_binaryFirstFormats.contains(format)) {
        return true;
      }
      if (format.startsWith('image/')) {
        return true;
      }
      if (format.startsWith('application/')) {
        return true;
      }
      if (format.startsWith('audio/')) {
        return true;
      }
      if (format.startsWith('video/')) {
        return true;
      }
    }
    return false;
  }
}

class _ReadFileResult {
  final Uint8List bytes;
  final String? fileName;

  const _ReadFileResult({
    required this.bytes,
    required this.fileName,
  });
}

class _ImageFormatCandidate {
  final FileFormat format;
  final String extension;

  const _ImageFormatCandidate(this.format, this.extension);
}

const _imageCandidates = <_ImageFormatCandidate>[
  _ImageFormatCandidate(Formats.png, 'png'),
  _ImageFormatCandidate(Formats.jpeg, 'jpg'),
  _ImageFormatCandidate(Formats.gif, 'gif'),
  _ImageFormatCandidate(Formats.webp, 'webp'),
  _ImageFormatCandidate(Formats.bmp, 'bmp'),
  _ImageFormatCandidate(Formats.tiff, 'tiff'),
  _ImageFormatCandidate(Formats.heic, 'heic'),
  _ImageFormatCandidate(Formats.heif, 'heif'),
];

const _imageExtensions = <String>{
  '.jpg',
  '.jpeg',
  '.gif',
  '.bmp',
  '.png',
  '.heic',
  '.heif',
  '.webp',
  '.avif',
  '.tiff',
  '.tif',
};

const _binaryFirstFormats = <String>{
  'text/uri-list',
};
