import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sync_clipboard_flutter/model/clipboard/clipboard.dart';

const int textTransferDataThreshold = 10240;

class ClipboardUploadPayload {
  final Clipboard clipboard;
  final String? dataName;
  final List<int>? dataBytes;

  const ClipboardUploadPayload({
    required this.clipboard,
    this.dataName,
    this.dataBytes,
  });

  bool get hasDataFile =>
      dataName != null && dataName!.isNotEmpty && dataBytes != null;
}

/// 流式文件剪贴板元数据构建结果。
class FileClipboardStreamPayload {
  final Clipboard clipboard;
  final int size;

  /// 创建流式文件剪贴板元数据构建结果。
  const FileClipboardStreamPayload({
    required this.clipboard,
    required this.size,
  });
}

ClipboardUploadPayload buildTextClipboardPayload(String text) {
  final textLength = text.length;
  final hash = computeTextHash(text);

  if (textLength > textTransferDataThreshold) {
    final preview = text.substring(0, textTransferDataThreshold);
    final dataName = 'text_$hash.txt';
    return ClipboardUploadPayload(
      clipboard: Clipboard(
        type: ClipboardType.text,
        hash: hash,
        text: preview,
        hasData: true,
        dataName: dataName,
        size: textLength,
      ),
      dataName: dataName,
      dataBytes: utf8.encode(text),
    );
  }

  return ClipboardUploadPayload(
    clipboard: Clipboard(
      type: ClipboardType.text,
      hash: hash,
      text: text,
      hasData: false,
      size: textLength,
    ),
  );
}

Clipboard buildFileClipboard({
  required String filename,
  required List<int> bytes,
  required ClipboardType type,
}) {
  final hash = computeFileHash(filename, bytes);
  return Clipboard(
    type: type,
    hash: hash,
    text: p.basename(filename),
    hasData: true,
    dataName: filename,
    size: bytes.length,
  );
}

/// 基于文件流构建剪贴板文件元数据。
Future<FileClipboardStreamPayload> buildFileClipboardFromStream({
  required String filename,
  required Stream<List<int>> stream,
  required ClipboardType type,
}) async {
  final hashAndSize = await _computeFileHashAndSizeFromStream(
    filename,
    stream,
  );
  return FileClipboardStreamPayload(
    clipboard: Clipboard(
      type: type,
      hash: hashAndSize.hash,
      text: p.basename(filename),
      hasData: true,
      dataName: filename,
      size: hashAndSize.size,
    ),
    size: hashAndSize.size,
  );
}

String computeTextHash(String text) {
  return _sha256Upper(utf8.encode(text));
}

String computeFileHash(String filename, List<int> bytes) {
  final contentHash = _sha256Upper(bytes);
  final baseName = p.basename(filename);
  final combined = '$baseName|$contentHash';
  return _sha256Upper(utf8.encode(combined));
}

/// 使用流式读取计算文件 hash。
Future<String> computeFileHashFromStream(
  String filename,
  Stream<List<int>> stream,
) async {
  final hashAndSize = await _computeFileHashAndSizeFromStream(
    filename,
    stream,
  );
  return hashAndSize.hash;
}

/// 使用流式读取计算文件 hash 与真实字节数。
Future<_FileHashStreamResult> _computeFileHashAndSizeFromStream(
  String filename,
  Stream<List<int>> stream,
) async {
  final contentHashAndSize = await _sha256UpperFromStream(stream);
  final baseName = p.basename(filename);
  final combined = '$baseName|${contentHashAndSize.hash}';
  return _FileHashStreamResult(
    hash: _sha256Upper(utf8.encode(combined)),
    size: contentHashAndSize.size,
  );
}

String computeGroupHashFromArchive(Archive archive) {
  final entryNames = <String>{};
  final fileEntries = <String, ArchiveFile>{};

  for (final entry in archive) {
    var entryName = entry.name.replaceAll('\\', '/');
    if (entry.isFile) {
      entryNames.add(entryName);
      fileEntries[entryName] = entry;
      _addParentDirectories(entryNames, entryName);
      continue;
    }

    if (!entryName.endsWith('/')) {
      entryName = '$entryName/';
    }
    entryNames.add(entryName);
    _addParentDirectories(entryNames, entryName);
  }

  final sortedEntries = entryNames.toList()..sort(_compareByUtf8Bytes);

  final buffer = StringBuffer();
  for (final entryName in sortedEntries) {
    if (entryName.endsWith('/')) {
      buffer.write('D|$entryName\x00');
      continue;
    }

    final entry = fileEntries[entryName];
    if (entry == null) {
      continue;
    }

    final bytes = entry.content as List<int>;
    final contentHash = _sha256Upper(bytes);
    buffer.write('F|$entryName|${bytes.length}|$contentHash\x00');
  }

  return _sha256Upper(utf8.encode(buffer.toString()));
}

bool hashMatches(String? expectedHash, String actualHash) {
  if (expectedHash == null || expectedHash.trim().isEmpty) {
    return true;
  }
  return expectedHash.trim().toUpperCase() == actualHash.toUpperCase();
}

String _sha256Upper(List<int> bytes) {
  return sha256.convert(bytes).toString().toUpperCase();
}

/// 使用 chunked conversion 计算流式 sha256。
Future<_FileHashStreamResult> _sha256UpperFromStream(
  Stream<List<int>> stream,
) async {
  final output = _DigestSink();
  final input = sha256.startChunkedConversion(output);
  var totalBytes = 0;
  await for (final chunk in stream) {
    totalBytes += chunk.length;
    input.add(chunk);
  }
  input.close();
  final digest = output.value;
  if (digest == null) {
    throw StateError('文件 hash 计算失败');
  }
  return _FileHashStreamResult(
    hash: digest.toString().toUpperCase(),
    size: totalBytes,
  );
}

void _addParentDirectories(Set<String> entryNames, String entryName) {
  final normalized = entryName.replaceAll('\\', '/');
  final parts = normalized.split('/');
  if (parts.length <= 1) {
    return;
  }

  var current = '';
  for (var i = 0; i < parts.length - 1; i++) {
    if (parts[i].isEmpty) {
      continue;
    }
    current = current.isEmpty ? '${parts[i]}/' : '$current${parts[i]}/';
    entryNames.add(current);
  }
}

int _compareByUtf8Bytes(String a, String b) {
  final aBytes = utf8.encode(a);
  final bBytes = utf8.encode(b);
  final minLength = aBytes.length < bBytes.length
      ? aBytes.length
      : bBytes.length;
  for (var i = 0; i < minLength; i++) {
    final diff = aBytes[i] - bBytes[i];
    if (diff != 0) {
      return diff;
    }
  }
  return aBytes.length - bBytes.length;
}

/// 收集 chunked hash 的最终 digest。
class _DigestSink implements Sink<Digest> {
  Digest? value;

  /// 保存最终 digest。
  @override
  void add(Digest data) {
    value = data;
  }

  /// 结束 digest 收集。
  @override
  void close() {}
}

/// 流式文件 hash 与字节数计算结果。
class _FileHashStreamResult {
  final String hash;
  final int size;

  /// 创建流式文件 hash 与字节数计算结果。
  const _FileHashStreamResult({
    required this.hash,
    required this.size,
  });
}
