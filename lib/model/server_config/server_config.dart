// To parse this JSON data, do
//
//     final serverConfig = serverConfigFromJson(jsonString);

import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'server_config.freezed.dart';
part 'server_config.g.dart';

ServerConfig serverConfigFromJson(String str) => ServerConfig.fromJson(json.decode(str));

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
  }) = _ServerConfig;

  factory ServerConfig.fromJson(Map<String, dynamic> json) => _$ServerConfigFromJson(json);

  /// 显示名称：优先使用 name，否则使用 url
  String get displayName => (name != null && name!.isNotEmpty) ? name! : url;
}
