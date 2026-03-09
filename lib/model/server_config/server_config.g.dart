// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServerConfig _$ServerConfigFromJson(Map<String, dynamic> json) =>
    _ServerConfig(
      id: json['id'] as String,
      name: json['name'] as String?,
      url: json['url'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      autoSwitchWifiNames:
          (json['autoSwitchWifiNames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ServerConfigToJson(_ServerConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'url': instance.url,
      'username': instance.username,
      'password': instance.password,
      'autoSwitchWifiNames': instance.autoSwitchWifiNames,
    };
