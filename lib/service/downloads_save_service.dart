import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_clipboard_flutter/model/app_settings/app_settings.dart';

class DownloadsSaveResult {
  final bool isZip;
  final String? uri;
  final String? displayName;
  final String path;

  const DownloadsSaveResult({
    required this.isZip,
    required this.uri,
    required this.displayName,
    required this.path,
  });

  factory DownloadsSaveResult.fromMap(Map<dynamic, dynamic> map) {
    final isZip = map['isZip'] == true;
    final uriRaw = (map['uri'] ?? '').toString();
    final displayNameRaw = (map['displayName'] ?? '').toString();
    final path = (map['path'] ?? map['relativePath'] ?? '').toString();

    if (!isZip && (uriRaw.isEmpty || displayNameRaw.isEmpty)) {
      throw StateError('保存结果无效: $map');
    }
    return DownloadsSaveResult(
      isZip: isZip,
      uri: uriRaw.isEmpty ? null : uriRaw,
      displayName: displayNameRaw.isEmpty ? null : displayNameRaw,
      path: path,
    );
  }
}

/// 通过平台通道将文件写入 Android Download 目录。
class DownloadsSaveService {
  DownloadsSaveService._();

  static const String _settingsStorageKey = 'app_settings';
  static const MethodChannel _channel = MethodChannel(
    'com.yshs.sync_clipboard_flutter/downloads',
  );

  static String _normalizeFileName(String fileName) {
    final normalized = fileName.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('文件名不能为空');
    }
    if (normalized.contains('/') || normalized.contains('\\')) {
      throw ArgumentError('文件名不能包含路径分隔符');
    }
    return normalized;
  }

  static String _normalizePath(String path) {
    final raw = path.trim().replaceAll('\\', '/');

    final validPrefix = raw == '/Download' || raw.startsWith('/Download/');
    if (!validPrefix) {
      throw ArgumentError('path 必须以 /Download 开头');
    }

    final parts = raw
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (parts.isEmpty || parts.first != 'Download') {
      throw ArgumentError('path 必须以 /Download 开头');
    }
    final hasInvalidSegment = parts
        .skip(1)
        .any((segment) => segment == '.' || segment == '..');
    if (hasInvalidSegment) {
      throw ArgumentError('path 不能包含 . 或 ..');
    }
    return '/${parts.join('/')}';
  }

  static String normalizeRelativePath(String? relativePath) {
    final raw = (relativePath ?? '').trim().replaceAll('\\', '/');
    if (raw.isEmpty) {
      return '';
    }

    final parts = raw
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList();
    final hasInvalidSegment = parts.any(
      (segment) => segment == '.' || segment == '..',
    );
    if (hasInvalidSegment) {
      throw ArgumentError('目录不能包含 . 或 ..');
    }
    return parts.join('/');
  }

  static String buildDownloadPathFromRelativePath(String? relativePath) {
    final normalizedRelativePath = normalizeRelativePath(relativePath);
    if (normalizedRelativePath.isEmpty) {
      return '/Download';
    }
    return _normalizePath('/Download/$normalizedRelativePath');
  }

  static Future<String> getConfiguredDownloadPath() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsStorageKey);
    final settings = settingsJson != null && settingsJson.isNotEmpty
        ? appSettingsFromJson(settingsJson)
        : const AppSettings();
    return buildDownloadPathFromRelativePath(settings.downloadRelativePath);
  }

  static Future<DownloadsSaveResult> saveBytesToDownloads({
    required List<int> bytes,
    String? fileName,
    String? path,
    bool isZip = false,
  }) async {
    final safePath = path == null
        ? await getConfiguredDownloadPath()
        : _normalizePath(path);
    final safeName = isZip ? '' : _normalizeFileName(fileName ?? '');
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'saveBytesToDownloads',
      <String, dynamic>{
        'bytes': Uint8List.fromList(bytes),
        'fileName': safeName,
        'path': safePath,
        'isZip': isZip,
      },
    );
    if (result == null) {
      throw StateError('保存失败：未返回结果');
    }
    return DownloadsSaveResult.fromMap(result);
  }

  static Future<DownloadsSaveResult> extractZipToDownloads({
    required List<int> zipBytes,
    required String rootFolderName,
  }) async {
    final basePath = await getConfiguredDownloadPath();
    final normalizedRootName = normalizeRelativePath(rootFolderName);
    final safeRoot = normalizedRootName.isEmpty
        ? basePath
        : _normalizePath('$basePath/$normalizedRootName');
    return saveBytesToDownloads(bytes: zipBytes, path: safeRoot, isZip: true);
  }
}
