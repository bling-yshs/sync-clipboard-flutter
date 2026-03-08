import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';
import 'server_config.dart';

part 'server_config_list.freezed.dart';
part 'server_config_list.g.dart';

ServerConfigList serverConfigListFromJson(String str) =>
    ServerConfigList.fromJson(json.decode(str));

String serverConfigListToJson(ServerConfigList data) =>
    json.encode(data.toJson());

@freezed
abstract class ServerConfigList with _$ServerConfigList {
  const factory ServerConfigList({
    /// 所有服务器配置列表
    @Default([]) List<ServerConfig> configs,

    /// 当前激活配置的 ID
    String? activeConfigId,
  }) = _ServerConfigList;

  factory ServerConfigList.fromJson(Map<String, dynamic> json) =>
      _$ServerConfigListFromJson(json);
}
