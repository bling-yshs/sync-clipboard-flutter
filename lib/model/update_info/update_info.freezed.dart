// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdateInfo {

/// 最新版本号
 String get version;/// 最低支持版本号，低于此版本必须更新
 String get minSupportedVersion;/// 更新日志
 String get changelog;/// 安装包大小（字节）
 int get size;/// 安装包 SHA256 校验值
 String get sha256;/// 下载源列表
 List<DownloadSource> get sources;
/// Create a copy of UpdateInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateInfoCopyWith<UpdateInfo> get copyWith => _$UpdateInfoCopyWithImpl<UpdateInfo>(this as UpdateInfo, _$identity);

  /// Serializes this UpdateInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateInfo&&(identical(other.version, version) || other.version == version)&&(identical(other.minSupportedVersion, minSupportedVersion) || other.minSupportedVersion == minSupportedVersion)&&(identical(other.changelog, changelog) || other.changelog == changelog)&&(identical(other.size, size) || other.size == size)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&const DeepCollectionEquality().equals(other.sources, sources));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,minSupportedVersion,changelog,size,sha256,const DeepCollectionEquality().hash(sources));

@override
String toString() {
  return 'UpdateInfo(version: $version, minSupportedVersion: $minSupportedVersion, changelog: $changelog, size: $size, sha256: $sha256, sources: $sources)';
}


}

/// @nodoc
abstract mixin class $UpdateInfoCopyWith<$Res>  {
  factory $UpdateInfoCopyWith(UpdateInfo value, $Res Function(UpdateInfo) _then) = _$UpdateInfoCopyWithImpl;
@useResult
$Res call({
 String version, String minSupportedVersion, String changelog, int size, String sha256, List<DownloadSource> sources
});




}
/// @nodoc
class _$UpdateInfoCopyWithImpl<$Res>
    implements $UpdateInfoCopyWith<$Res> {
  _$UpdateInfoCopyWithImpl(this._self, this._then);

  final UpdateInfo _self;
  final $Res Function(UpdateInfo) _then;

/// Create a copy of UpdateInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? minSupportedVersion = null,Object? changelog = null,Object? size = null,Object? sha256 = null,Object? sources = null,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,minSupportedVersion: null == minSupportedVersion ? _self.minSupportedVersion : minSupportedVersion // ignore: cast_nullable_to_non_nullable
as String,changelog: null == changelog ? _self.changelog : changelog // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as List<DownloadSource>,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateInfo].
extension UpdateInfoPatterns on UpdateInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateInfo value)  $default,){
final _that = this;
switch (_that) {
case _UpdateInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateInfo value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String version,  String minSupportedVersion,  String changelog,  int size,  String sha256,  List<DownloadSource> sources)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateInfo() when $default != null:
return $default(_that.version,_that.minSupportedVersion,_that.changelog,_that.size,_that.sha256,_that.sources);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String version,  String minSupportedVersion,  String changelog,  int size,  String sha256,  List<DownloadSource> sources)  $default,) {final _that = this;
switch (_that) {
case _UpdateInfo():
return $default(_that.version,_that.minSupportedVersion,_that.changelog,_that.size,_that.sha256,_that.sources);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String version,  String minSupportedVersion,  String changelog,  int size,  String sha256,  List<DownloadSource> sources)?  $default,) {final _that = this;
switch (_that) {
case _UpdateInfo() when $default != null:
return $default(_that.version,_that.minSupportedVersion,_that.changelog,_that.size,_that.sha256,_that.sources);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateInfo implements UpdateInfo {
  const _UpdateInfo({required this.version, required this.minSupportedVersion, required this.changelog, required this.size, required this.sha256, required final  List<DownloadSource> sources}): _sources = sources;
  factory _UpdateInfo.fromJson(Map<String, dynamic> json) => _$UpdateInfoFromJson(json);

/// 最新版本号
@override final  String version;
/// 最低支持版本号，低于此版本必须更新
@override final  String minSupportedVersion;
/// 更新日志
@override final  String changelog;
/// 安装包大小（字节）
@override final  int size;
/// 安装包 SHA256 校验值
@override final  String sha256;
/// 下载源列表
 final  List<DownloadSource> _sources;
/// 下载源列表
@override List<DownloadSource> get sources {
  if (_sources is EqualUnmodifiableListView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sources);
}


/// Create a copy of UpdateInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateInfoCopyWith<_UpdateInfo> get copyWith => __$UpdateInfoCopyWithImpl<_UpdateInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateInfo&&(identical(other.version, version) || other.version == version)&&(identical(other.minSupportedVersion, minSupportedVersion) || other.minSupportedVersion == minSupportedVersion)&&(identical(other.changelog, changelog) || other.changelog == changelog)&&(identical(other.size, size) || other.size == size)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&const DeepCollectionEquality().equals(other._sources, _sources));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,minSupportedVersion,changelog,size,sha256,const DeepCollectionEquality().hash(_sources));

@override
String toString() {
  return 'UpdateInfo(version: $version, minSupportedVersion: $minSupportedVersion, changelog: $changelog, size: $size, sha256: $sha256, sources: $sources)';
}


}

/// @nodoc
abstract mixin class _$UpdateInfoCopyWith<$Res> implements $UpdateInfoCopyWith<$Res> {
  factory _$UpdateInfoCopyWith(_UpdateInfo value, $Res Function(_UpdateInfo) _then) = __$UpdateInfoCopyWithImpl;
@override @useResult
$Res call({
 String version, String minSupportedVersion, String changelog, int size, String sha256, List<DownloadSource> sources
});




}
/// @nodoc
class __$UpdateInfoCopyWithImpl<$Res>
    implements _$UpdateInfoCopyWith<$Res> {
  __$UpdateInfoCopyWithImpl(this._self, this._then);

  final _UpdateInfo _self;
  final $Res Function(_UpdateInfo) _then;

/// Create a copy of UpdateInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? minSupportedVersion = null,Object? changelog = null,Object? size = null,Object? sha256 = null,Object? sources = null,}) {
  return _then(_UpdateInfo(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,minSupportedVersion: null == minSupportedVersion ? _self.minSupportedVersion : minSupportedVersion // ignore: cast_nullable_to_non_nullable
as String,changelog: null == changelog ? _self.changelog : changelog // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,sources: null == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<DownloadSource>,
  ));
}


}


/// @nodoc
mixin _$DownloadSource {

/// 下载源 ID
 String get id;/// 下载源名称（用于显示）
 String get name;/// 下载地址
 String get url;
/// Create a copy of DownloadSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadSourceCopyWith<DownloadSource> get copyWith => _$DownloadSourceCopyWithImpl<DownloadSource>(this as DownloadSource, _$identity);

  /// Serializes this DownloadSource to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadSource&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,url);

@override
String toString() {
  return 'DownloadSource(id: $id, name: $name, url: $url)';
}


}

/// @nodoc
abstract mixin class $DownloadSourceCopyWith<$Res>  {
  factory $DownloadSourceCopyWith(DownloadSource value, $Res Function(DownloadSource) _then) = _$DownloadSourceCopyWithImpl;
@useResult
$Res call({
 String id, String name, String url
});




}
/// @nodoc
class _$DownloadSourceCopyWithImpl<$Res>
    implements $DownloadSourceCopyWith<$Res> {
  _$DownloadSourceCopyWithImpl(this._self, this._then);

  final DownloadSource _self;
  final $Res Function(DownloadSource) _then;

/// Create a copy of DownloadSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? url = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DownloadSource].
extension DownloadSourcePatterns on DownloadSource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadSource value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadSource() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadSource value)  $default,){
final _that = this;
switch (_that) {
case _DownloadSource():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadSource value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadSource() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadSource() when $default != null:
return $default(_that.id,_that.name,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String url)  $default,) {final _that = this;
switch (_that) {
case _DownloadSource():
return $default(_that.id,_that.name,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String url)?  $default,) {final _that = this;
switch (_that) {
case _DownloadSource() when $default != null:
return $default(_that.id,_that.name,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DownloadSource implements DownloadSource {
  const _DownloadSource({required this.id, required this.name, required this.url});
  factory _DownloadSource.fromJson(Map<String, dynamic> json) => _$DownloadSourceFromJson(json);

/// 下载源 ID
@override final  String id;
/// 下载源名称（用于显示）
@override final  String name;
/// 下载地址
@override final  String url;

/// Create a copy of DownloadSource
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadSourceCopyWith<_DownloadSource> get copyWith => __$DownloadSourceCopyWithImpl<_DownloadSource>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DownloadSourceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadSource&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,url);

@override
String toString() {
  return 'DownloadSource(id: $id, name: $name, url: $url)';
}


}

/// @nodoc
abstract mixin class _$DownloadSourceCopyWith<$Res> implements $DownloadSourceCopyWith<$Res> {
  factory _$DownloadSourceCopyWith(_DownloadSource value, $Res Function(_DownloadSource) _then) = __$DownloadSourceCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String url
});




}
/// @nodoc
class __$DownloadSourceCopyWithImpl<$Res>
    implements _$DownloadSourceCopyWith<$Res> {
  __$DownloadSourceCopyWithImpl(this._self, this._then);

  final _DownloadSource _self;
  final $Res Function(_DownloadSource) _then;

/// Create a copy of DownloadSource
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? url = null,}) {
  return _then(_DownloadSource(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
