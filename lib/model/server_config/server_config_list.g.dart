// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_config_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServerConfigList _$ServerConfigListFromJson(Map<String, dynamic> json) =>
    _ServerConfigList(
      configs:
          (json['configs'] as List<dynamic>?)
              ?.map((e) => ServerConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      activeConfigId: json['activeConfigId'] as String?,
    );

Map<String, dynamic> _$ServerConfigListToJson(_ServerConfigList instance) =>
    <String, dynamic>{
      'configs': instance.configs,
      'activeConfigId': instance.activeConfigId,
    };
