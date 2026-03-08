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

String computeTextHash(String text) {
  return _sha256Upper(utf8.encode(text));
}

String computeFileHash(String filename, List<int> bytes) {
  final contentHash = _sha256Upper(bytes);
  final baseName = p.basename(filename);
  final combined = '$baseName|$contentHash';
  return _sha256Upper(utf8.encode(combined));
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
