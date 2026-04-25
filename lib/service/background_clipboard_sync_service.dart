import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_clipboard_flutter/model/app_settings/app_settings.dart';
import 'package:sync_clipboard_flutter/model/server_config/server_config.dart';
import 'package:sync_clipboard_flutter/service/app_logger.dart';
import 'package:sync_clipboard_flutter/service/server_config_service.dart';

/// 后台剪贴板自动同步服务控制器。
class BackgroundClipboardSyncService {
  BackgroundClipboardSyncService._();

  static const MethodChannel _channel = MethodChannel(
    'com.yshs.sync_clipboard_flutter/background_clipboard_sync',
  );

  /// 启动 Android 前台服务并写入当前服务器配置。
  static Future<bool> start() async {
    if (!Platform.isAndroid) {
      return false;
    }

    final config = await ServerConfigService.getActiveConfig();
    final settings = await _loadSettings();
    if (config == null) {
      AppLogger.logger.w('未找到服务器配置，后台剪贴板服务器检查未启动');
      return false;
    }
    return startWithConfig(config, settings);
  }

  /// 如果用户已启用设置，则在应用启动时恢复后台同步服务。
  static Future<bool> startIfEnabled() async {
    final settings = await _loadSettings();
    if (!settings.enableShizukuClipboard) {
      return false;
    }

    final config = await ServerConfigService.getActiveConfig();
    if (config == null) {
      AppLogger.logger.w('未找到服务器配置，后台剪贴板服务器检查未启动');
      return false;
    }

    return startWithConfig(config, settings);
  }

  /// 使用指定配置启动 Android 前台服务。
  static Future<bool> startWithConfig(
    ServerConfig config,
    AppSettings settings,
  ) async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      if (settings.enableBackgroundAutoSyncLog) {
        AppLogger.logger.i(
          '启动后台剪贴板服务器检查，检查间隔：${settings.serverContentCheckIntervalSeconds} 秒',
        );
      }
      return await _channel.invokeMethod<bool>('start', {
            'url': config.url,
            'username': config.username,
            'password': config.password,
            'trustInsecureCert': settings.trustInsecureCert,
            'clipboardCheckIntervalSeconds':
                settings.clipboardCheckIntervalSeconds,
            'serverContentCheckIntervalSeconds':
                settings.serverContentCheckIntervalSeconds,
            'enableBackgroundAutoSyncLog':
                settings.enableBackgroundAutoSyncLog,
          }) ??
          false;
    } catch (e) {
      AppLogger.logger.w('启动后台剪贴板同步服务失败', error: e);
      return false;
    }
  }

  /// 停止 Android 前台服务。
  static Future<bool> stop() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      return await _channel.invokeMethod<bool>('stop') ?? false;
    } catch (e) {
      AppLogger.logger.w('停止后台剪贴板同步服务失败', error: e);
      return false;
    }
  }

  /// 跳转到 Android 忽略电池优化设置。
  static Future<bool> openBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      return await _channel.invokeMethod<bool>(
            'openBatteryOptimizationSettings',
          ) ??
          false;
    } catch (e) {
      AppLogger.logger.w('打开忽略电池优化设置失败', error: e);
      return false;
    }
  }

  /// 读取应用设置。
  static Future<AppSettings> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('app_settings');
    if (settingsJson == null || settingsJson.isEmpty) {
      return const AppSettings();
    }

    try {
      return appSettingsFromJson(settingsJson);
    } catch (_) {
      return const AppSettings();
    }
  }
}
