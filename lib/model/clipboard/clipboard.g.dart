// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clipboard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Clipboard _$ClipboardFromJson(Map<String, dynamic> json) => _Clipboard(
  type: $enumDecode(_$ClipboardTypeEnumMap, json['type']),
  hash: _hashFromJson(json['hash']),
  text: json['text'] as String,
  hasData: json['hasData'] as bool,
  dataName: json['dataName'] as String?,
  size: (json['size'] as num?)?.toInt(),
);

Map<String, dynamic> _$ClipboardToJson(_Clipboard instance) =>
    <String, dynamic>{
      'type': _$ClipboardTypeEnumMap[instance.type]!,
      'hash': ?_hashToJson(instance.hash),
      'text': instance.text,
      'hasData': instance.hasData,
      'dataName': ?instance.dataName,
      'size': ?instance.size,
    };

const _$ClipboardTypeEnumMap = {
  ClipboardType.text: 'Text',
  ClipboardType.image: 'Image',
  ClipboardType.file: 'File',
  ClipboardType.group: 'Group',
};
