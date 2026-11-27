import 'package:flutter/services.dart';

/// 通过平台通道调用系统打开链接或文件。
class ExternalOpenService {
  ExternalOpenService._();

  static const MethodChannel _channel = MethodChannel(
    'com.yshs.sync_clipboard_flutter/external_open',
  );

  /// 用默认浏览器打开链接，没有应用可以处理时返回 false。
  static Future<bool> openUrl(String url) async {
    final opened = await _channel.invokeMethod<bool>(
      'openUrl',
      <String, dynamic>{'url': url},
    );
    return opened ?? false;
  }

  /// 用系统选择的应用打开文件，仅支持 content uri，无法打开时返回 false。
  static Future<bool> openFile(String uri) async {
    final opened = await _channel.invokeMethod<bool>(
      'openFile',
      <String, dynamic>{'uri': uri},
    );
    return opened ?? false;
  }

  /// 文本整段是一个 http/https 链接时返回该链接，否则返回 null。
  static String? extractSingleUrl(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.contains(RegExp(r'\s'))) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    return trimmed;
  }

  /// 是否为可交给其他应用打开的 content uri。
  static bool isContentUri(String uri) {
    return uri.startsWith('content://');
  }
}
