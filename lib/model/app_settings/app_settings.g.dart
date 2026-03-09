// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => _AppSettings(
  trustInsecureCert: json['trustInsecureCert'] as bool? ?? false,
  autoCheckUpdate: json['autoCheckUpdate'] as bool? ?? true,
  manualUploadDialogShown: json['manualUploadDialogShown'] as bool? ?? false,
  downloadRelativePath: json['downloadRelativePath'] as String? ?? '',
  ignoredVersion: json['ignoredVersion'] as String?,
);

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{
      'trustInsecureCert': instance.trustInsecureCert,
      'autoCheckUpdate': instance.autoCheckUpdate,
      'manualUploadDialogShown': instance.manualUploadDialogShown,
      'downloadRelativePath': instance.downloadRelativePath,
      'ignoredVersion': instance.ignoredVersion,
    };
