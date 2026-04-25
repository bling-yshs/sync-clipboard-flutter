import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sync_clipboard_flutter/service/app_logger.dart';

/// Shizuku 剪贴板读取服务。
class ShizukuClipboardService {
  ShizukuClipboardService._();

  static const MethodChannel _channel = MethodChannel(
    'com.yshs.sync_clipboard_flutter/shizuku_clipboard',
  );

  /// 判断当前平台是否可能使用 Shizuku。
  static bool get isSupportedPlatform => Platform.isAndroid;

  /// 检查 Shizuku 服务是否正在运行。
  static Future<bool> isAvailable() async {
    if (!isSupportedPlatform) {
      return false;
    }

    try {
      return await _channel.invokeMethod<bool>('isShizukuAvailable') ?? false;
    } catch (e) {
      AppLogger.logger.w('检查 Shizuku 可用性失败', error: e);
      return false;
    }
  }

  /// 检查应用是否已有 Shizuku 权限。
  static Future<bool> hasPermission() async {
    if (!isSupportedPlatform) {
      return false;
    }

    try {
      return await _channel.invokeMethod<bool>('hasShizukuPermission') ?? false;
    } catch (e) {
      AppLogger.logger.w('检查 Shizuku 权限失败', error: e);
      return false;
    }
  }

  /// 请求 Shizuku 权限并返回请求是否成功发起。
  static Future<bool> requestPermission() async {
    if (!isSupportedPlatform) {
      return false;
    }

    try {
      return await _channel.invokeMethod<bool>('requestShizukuPermission') ??
          false;
    } catch (e) {
      AppLogger.logger.w('请求 Shizuku 权限失败', error: e);
      return false;
    }
  }

  /// 检查 Shizuku 能否读取到文本剪贴板。
  static Future<bool> hasString() async {
    if (!isSupportedPlatform) {
      return false;
    }

    try {
      return await _channel.invokeMethod<bool>('hasStringViaShizuku') ?? false;
    } catch (e) {
      AppLogger.logger.w('通过 Shizuku 检查剪贴板文本失败', error: e);
      return false;
    }
  }

  /// 通过 Shizuku 读取剪贴板文本。
  static Future<String?> getString() async {
    if (!isSupportedPlatform) {
      return null;
    }

    try {
      final text = await _channel.invokeMethod<String>('getStringViaShizuku');
      final normalizedText = text?.trim();
      if (normalizedText == null || normalizedText.isEmpty) {
        return null;
      }
      return normalizedText;
    } catch (e) {
      AppLogger.logger.w('通过 Shizuku 读取剪贴板文本失败', error: e);
      return null;
    }
  }
}
