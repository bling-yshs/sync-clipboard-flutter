// To parse this JSON data, do
//
//     final serverConfig = serverConfigFromJson(jsonString);

import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'server_config.freezed.dart';
part 'server_config.g.dart';

ServerConfig serverConfigFromJson(String str) =>
    ServerConfig.fromJson(json.decode(str));

String serverConfigToJson(ServerConfig data) => json.encode(data.toJson());

@freezed
abstract class ServerConfig with _$ServerConfig {
  const ServerConfig._(); // 支持自定义 getter

  const factory ServerConfig({
    /// 唯一标识符
    required String id,

    /// 用户自定义名称，可为空
    String? name,
    required String url,
    required String username,
    required String password,

    /// 当前 WiFi 名称命中时，自动切换到此配置
    @Default([]) List<String> autoSwitchWifiNames,
  }) = _ServerConfig;

  factory ServerConfig.fromJson(Map<String, dynamic> json) =>
      _$ServerConfigFromJson(json);

  /// 显示名称：优先使用 name，否则使用 url
  String get displayName => (name != null && name!.isNotEmpty) ? name! : url;

  /// 规范化后的 WiFi 名称列表
  List<String> get normalizedAutoSwitchWifiNames => autoSwitchWifiNames
      .map(_normalizeWifiName)
      .whereType<String>()
      .toList(growable: false);

  /// 当前配置是否命中 WiFi 规则
  bool matchesWifiName(String wifiName) {
    final normalizedWifiName = _normalizeWifiName(wifiName);
    if (normalizedWifiName == null) {
      return false;
    }
    return normalizedAutoSwitchWifiNames.contains(normalizedWifiName);
  }

  static String? _normalizeWifiName(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    if (trimmed.startsWith('"') &&
        trimmed.endsWith('"') &&
        trimmed.length >= 2) {
      final unquoted = trimmed.substring(1, trimmed.length - 1).trim();
      return unquoted.isEmpty ? null : unquoted;
    }

    return trimmed;
  }
}
