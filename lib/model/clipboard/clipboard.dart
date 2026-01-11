import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'clipboard.freezed.dart';
part 'clipboard.g.dart';

Clipboard clipboardFromJson(String str) =>
    Clipboard.fromJson(json.decode(str));

String clipboardToJson(Clipboard data) =>
    json.encode(data.toJson());

@freezed
abstract class Clipboard with _$Clipboard {
  const factory Clipboard({
    required ClipboardType type,
    @JsonKey(
      fromJson: _hashFromJson,
      toJson: _hashToJson,
      includeIfNull: false,
    )
    String? hash,
    required String text,
    required bool hasData,
    @JsonKey(includeIfNull: false)
    String? dataName,
    @JsonKey(includeIfNull: false)
    int? size,
  }) = _Clipboard;

  factory Clipboard.fromJson(Map<String, dynamic> json) =>
      _$ClipboardFromJson(json);
}

/// Type 字段的枚举
@JsonEnum(alwaysCreate: true)
enum ClipboardType {
  @JsonValue('Text')
  text,

  @JsonValue('Image')
  image,

  @JsonValue('File')
  file,

  @JsonValue('Group')
  group,
}

String? _hashFromJson(Object? value) {
  if (value == null) {
    return null;
  }
  final hash = value.toString().trim();
  return hash.isEmpty ? null : hash;
}

String? _hashToJson(String? value) {
  if (value == null) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
