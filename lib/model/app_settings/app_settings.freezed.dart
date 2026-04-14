// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppSettings {

/// 是否信任不安全的 HTTPS 证书
/// 开启后，Dio 请求将不校验 HTTPS 证书
/// 注意：这会降低安全性，仅建议在开发/测试环境使用
 bool get trustInsecureCert;/// 启动时自动检查更新
 bool get autoCheckUpdate;/// 是否已经显示过手动上传提示对话框
/// 用户点击"我知道了"后设为 true，后续不再显示
 bool get manualUploadDialogShown;/// Download 下的相对保存目录
/// 例如 A/B/C，最终保存到 /Download/A/B/C
 String get downloadRelativePath;/// 日志查看页默认选中的日志级别
 String get logViewLevelFilter;/// 被忽略的更新版本号
/// 用户点击"忽略该版本"后设置，该版本将不再提示更新
/// 当有新版本发布时，会自动清除该设置
 String? get ignoredVersion;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);

  /// Serializes this AppSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.trustInsecureCert, trustInsecureCert) || other.trustInsecureCert == trustInsecureCert)&&(identical(other.autoCheckUpdate, autoCheckUpdate) || other.autoCheckUpdate == autoCheckUpdate)&&(identical(other.manualUploadDialogShown, manualUploadDialogShown) || other.manualUploadDialogShown == manualUploadDialogShown)&&(identical(other.downloadRelativePath, downloadRelativePath) || other.downloadRelativePath == downloadRelativePath)&&(identical(other.logViewLevelFilter, logViewLevelFilter) || other.logViewLevelFilter == logViewLevelFilter)&&(identical(other.ignoredVersion, ignoredVersion) || other.ignoredVersion == ignoredVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trustInsecureCert,autoCheckUpdate,manualUploadDialogShown,downloadRelativePath,logViewLevelFilter,ignoredVersion);

@override
String toString() {
  return 'AppSettings(trustInsecureCert: $trustInsecureCert, autoCheckUpdate: $autoCheckUpdate, manualUploadDialogShown: $manualUploadDialogShown, downloadRelativePath: $downloadRelativePath, logViewLevelFilter: $logViewLevelFilter, ignoredVersion: $ignoredVersion)';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 bool trustInsecureCert, bool autoCheckUpdate, bool manualUploadDialogShown, String downloadRelativePath, String logViewLevelFilter, String? ignoredVersion
});




}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trustInsecureCert = null,Object? autoCheckUpdate = null,Object? manualUploadDialogShown = null,Object? downloadRelativePath = null,Object? logViewLevelFilter = null,Object? ignoredVersion = freezed,}) {
  return _then(_self.copyWith(
trustInsecureCert: null == trustInsecureCert ? _self.trustInsecureCert : trustInsecureCert // ignore: cast_nullable_to_non_nullable
as bool,autoCheckUpdate: null == autoCheckUpdate ? _self.autoCheckUpdate : autoCheckUpdate // ignore: cast_nullable_to_non_nullable
as bool,manualUploadDialogShown: null == manualUploadDialogShown ? _self.manualUploadDialogShown : manualUploadDialogShown // ignore: cast_nullable_to_non_nullable
as bool,downloadRelativePath: null == downloadRelativePath ? _self.downloadRelativePath : downloadRelativePath // ignore: cast_nullable_to_non_nullable
as String,logViewLevelFilter: null == logViewLevelFilter ? _self.logViewLevelFilter : logViewLevelFilter // ignore: cast_nullable_to_non_nullable
as String,ignoredVersion: freezed == ignoredVersion ? _self.ignoredVersion : ignoredVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool trustInsecureCert,  bool autoCheckUpdate,  bool manualUploadDialogShown,  String downloadRelativePath,  String logViewLevelFilter,  String? ignoredVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.trustInsecureCert,_that.autoCheckUpdate,_that.manualUploadDialogShown,_that.downloadRelativePath,_that.logViewLevelFilter,_that.ignoredVersion);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool trustInsecureCert,  bool autoCheckUpdate,  bool manualUploadDialogShown,  String downloadRelativePath,  String logViewLevelFilter,  String? ignoredVersion)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.trustInsecureCert,_that.autoCheckUpdate,_that.manualUploadDialogShown,_that.downloadRelativePath,_that.logViewLevelFilter,_that.ignoredVersion);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool trustInsecureCert,  bool autoCheckUpdate,  bool manualUploadDialogShown,  String downloadRelativePath,  String logViewLevelFilter,  String? ignoredVersion)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.trustInsecureCert,_that.autoCheckUpdate,_that.manualUploadDialogShown,_that.downloadRelativePath,_that.logViewLevelFilter,_that.ignoredVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppSettings implements AppSettings {
  const _AppSettings({this.trustInsecureCert = false, this.autoCheckUpdate = true, this.manualUploadDialogShown = false, this.downloadRelativePath = '', this.logViewLevelFilter = 'info', this.ignoredVersion});
  factory _AppSettings.fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);

/// 是否信任不安全的 HTTPS 证书
/// 开启后，Dio 请求将不校验 HTTPS 证书
/// 注意：这会降低安全性，仅建议在开发/测试环境使用
@override@JsonKey() final  bool trustInsecureCert;
/// 启动时自动检查更新
@override@JsonKey() final  bool autoCheckUpdate;
/// 是否已经显示过手动上传提示对话框
/// 用户点击"我知道了"后设为 true，后续不再显示
@override@JsonKey() final  bool manualUploadDialogShown;
/// Download 下的相对保存目录
/// 例如 A/B/C，最终保存到 /Download/A/B/C
@override@JsonKey() final  String downloadRelativePath;
/// 日志查看页默认选中的日志级别
@override@JsonKey() final  String logViewLevelFilter;
/// 被忽略的更新版本号
/// 用户点击"忽略该版本"后设置，该版本将不再提示更新
/// 当有新版本发布时，会自动清除该设置
@override final  String? ignoredVersion;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.trustInsecureCert, trustInsecureCert) || other.trustInsecureCert == trustInsecureCert)&&(identical(other.autoCheckUpdate, autoCheckUpdate) || other.autoCheckUpdate == autoCheckUpdate)&&(identical(other.manualUploadDialogShown, manualUploadDialogShown) || other.manualUploadDialogShown == manualUploadDialogShown)&&(identical(other.downloadRelativePath, downloadRelativePath) || other.downloadRelativePath == downloadRelativePath)&&(identical(other.logViewLevelFilter, logViewLevelFilter) || other.logViewLevelFilter == logViewLevelFilter)&&(identical(other.ignoredVersion, ignoredVersion) || other.ignoredVersion == ignoredVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trustInsecureCert,autoCheckUpdate,manualUploadDialogShown,downloadRelativePath,logViewLevelFilter,ignoredVersion);

@override
String toString() {
  return 'AppSettings(trustInsecureCert: $trustInsecureCert, autoCheckUpdate: $autoCheckUpdate, manualUploadDialogShown: $manualUploadDialogShown, downloadRelativePath: $downloadRelativePath, logViewLevelFilter: $logViewLevelFilter, ignoredVersion: $ignoredVersion)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool trustInsecureCert, bool autoCheckUpdate, bool manualUploadDialogShown, String downloadRelativePath, String logViewLevelFilter, String? ignoredVersion
});




}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trustInsecureCert = null,Object? autoCheckUpdate = null,Object? manualUploadDialogShown = null,Object? downloadRelativePath = null,Object? logViewLevelFilter = null,Object? ignoredVersion = freezed,}) {
  return _then(_AppSettings(
trustInsecureCert: null == trustInsecureCert ? _self.trustInsecureCert : trustInsecureCert // ignore: cast_nullable_to_non_nullable
as bool,autoCheckUpdate: null == autoCheckUpdate ? _self.autoCheckUpdate : autoCheckUpdate // ignore: cast_nullable_to_non_nullable
as bool,manualUploadDialogShown: null == manualUploadDialogShown ? _self.manualUploadDialogShown : manualUploadDialogShown // ignore: cast_nullable_to_non_nullable
as bool,downloadRelativePath: null == downloadRelativePath ? _self.downloadRelativePath : downloadRelativePath // ignore: cast_nullable_to_non_nullable
as String,logViewLevelFilter: null == logViewLevelFilter ? _self.logViewLevelFilter : logViewLevelFilter // ignore: cast_nullable_to_non_nullable
as String,ignoredVersion: freezed == ignoredVersion ? _self.ignoredVersion : ignoredVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
