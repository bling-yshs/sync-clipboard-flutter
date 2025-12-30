// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'server_config_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServerConfigList {

/// 所有服务器配置列表
 List<ServerConfig> get configs;/// 当前激活配置的 ID
 String? get activeConfigId;
/// Create a copy of ServerConfigList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerConfigListCopyWith<ServerConfigList> get copyWith => _$ServerConfigListCopyWithImpl<ServerConfigList>(this as ServerConfigList, _$identity);

  /// Serializes this ServerConfigList to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerConfigList&&const DeepCollectionEquality().equals(other.configs, configs)&&(identical(other.activeConfigId, activeConfigId) || other.activeConfigId == activeConfigId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(configs),activeConfigId);

@override
String toString() {
  return 'ServerConfigList(configs: $configs, activeConfigId: $activeConfigId)';
}


}

/// @nodoc
abstract mixin class $ServerConfigListCopyWith<$Res>  {
  factory $ServerConfigListCopyWith(ServerConfigList value, $Res Function(ServerConfigList) _then) = _$ServerConfigListCopyWithImpl;
@useResult
$Res call({
 List<ServerConfig> configs, String? activeConfigId
});




}
/// @nodoc
class _$ServerConfigListCopyWithImpl<$Res>
    implements $ServerConfigListCopyWith<$Res> {
  _$ServerConfigListCopyWithImpl(this._self, this._then);

  final ServerConfigList _self;
  final $Res Function(ServerConfigList) _then;

/// Create a copy of ServerConfigList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? configs = null,Object? activeConfigId = freezed,}) {
  return _then(_self.copyWith(
configs: null == configs ? _self.configs : configs // ignore: cast_nullable_to_non_nullable
as List<ServerConfig>,activeConfigId: freezed == activeConfigId ? _self.activeConfigId : activeConfigId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ServerConfigList].
extension ServerConfigListPatterns on ServerConfigList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServerConfigList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServerConfigList() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServerConfigList value)  $default,){
final _that = this;
switch (_that) {
case _ServerConfigList():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServerConfigList value)?  $default,){
final _that = this;
switch (_that) {
case _ServerConfigList() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ServerConfig> configs,  String? activeConfigId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServerConfigList() when $default != null:
return $default(_that.configs,_that.activeConfigId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ServerConfig> configs,  String? activeConfigId)  $default,) {final _that = this;
switch (_that) {
case _ServerConfigList():
return $default(_that.configs,_that.activeConfigId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ServerConfig> configs,  String? activeConfigId)?  $default,) {final _that = this;
switch (_that) {
case _ServerConfigList() when $default != null:
return $default(_that.configs,_that.activeConfigId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServerConfigList implements ServerConfigList {
  const _ServerConfigList({final  List<ServerConfig> configs = const [], this.activeConfigId}): _configs = configs;
  factory _ServerConfigList.fromJson(Map<String, dynamic> json) => _$ServerConfigListFromJson(json);

/// 所有服务器配置列表
 final  List<ServerConfig> _configs;
/// 所有服务器配置列表
@override@JsonKey() List<ServerConfig> get configs {
  if (_configs is EqualUnmodifiableListView) return _configs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_configs);
}

/// 当前激活配置的 ID
@override final  String? activeConfigId;

/// Create a copy of ServerConfigList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServerConfigListCopyWith<_ServerConfigList> get copyWith => __$ServerConfigListCopyWithImpl<_ServerConfigList>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServerConfigListToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServerConfigList&&const DeepCollectionEquality().equals(other._configs, _configs)&&(identical(other.activeConfigId, activeConfigId) || other.activeConfigId == activeConfigId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_configs),activeConfigId);

@override
String toString() {
  return 'ServerConfigList(configs: $configs, activeConfigId: $activeConfigId)';
}


}

/// @nodoc
abstract mixin class _$ServerConfigListCopyWith<$Res> implements $ServerConfigListCopyWith<$Res> {
  factory _$ServerConfigListCopyWith(_ServerConfigList value, $Res Function(_ServerConfigList) _then) = __$ServerConfigListCopyWithImpl;
@override @useResult
$Res call({
 List<ServerConfig> configs, String? activeConfigId
});




}
/// @nodoc
class __$ServerConfigListCopyWithImpl<$Res>
    implements _$ServerConfigListCopyWith<$Res> {
  __$ServerConfigListCopyWithImpl(this._self, this._then);

  final _ServerConfigList _self;
  final $Res Function(_ServerConfigList) _then;

/// Create a copy of ServerConfigList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? configs = null,Object? activeConfigId = freezed,}) {
  return _then(_ServerConfigList(
configs: null == configs ? _self._configs : configs // ignore: cast_nullable_to_non_nullable
as List<ServerConfig>,activeConfigId: freezed == activeConfigId ? _self.activeConfigId : activeConfigId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
