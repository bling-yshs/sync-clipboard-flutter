// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UpdateInfo _$UpdateInfoFromJson(Map<String, dynamic> json) => _UpdateInfo(
  version: json['version'] as String,
  minSupportedVersion: json['minSupportedVersion'] as String,
  changelog: json['changelog'] as String,
  size: (json['size'] as num).toInt(),
  sha256: json['sha256'] as String,
  sources: (json['sources'] as List<dynamic>)
      .map((e) => DownloadSource.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UpdateInfoToJson(_UpdateInfo instance) =>
    <String, dynamic>{
      'version': instance.version,
      'minSupportedVersion': instance.minSupportedVersion,
      'changelog': instance.changelog,
      'size': instance.size,
      'sha256': instance.sha256,
      'sources': instance.sources,
    };

_DownloadSource _$DownloadSourceFromJson(Map<String, dynamic> json) =>
    _DownloadSource(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$DownloadSourceToJson(_DownloadSource instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'url': instance.url,
    };
