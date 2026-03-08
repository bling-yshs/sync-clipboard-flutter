// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'server_config_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ServerConfigState {

 ServerConfigList get configList; String? get editingConfigId; String get name; String get url; String get username; String get password; List<String> get autoSwitchWifiNames; bool get isSaving;
/// Create a copy of ServerConfigState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerConfigStateCopyWith<ServerConfigState> get copyWith => _$ServerConfigStateCopyWithImpl<ServerConfigState>(this as ServerConfigState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerConfigState&&(identical(other.configList, configList) || other.configList == configList)&&(identical(other.editingConfigId, editingConfigId) || other.editingConfigId == editingConfigId)&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password)&&const DeepCollectionEquality().equals(other.autoSwitchWifiNames, autoSwitchWifiNames)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving));
}


@override
int get hashCode => Object.hash(runtimeType,configList,editingConfigId,name,url,username,password,const DeepCollectionEquality().hash(autoSwitchWifiNames),isSaving);

@override
String toString() {
  return 'ServerConfigState(configList: $configList, editingConfigId: $editingConfigId, name: $name, url: $url, username: $username, password: $password, autoSwitchWifiNames: $autoSwitchWifiNames, isSaving: $isSaving)';
}


}

/// @nodoc
abstract mixin class $ServerConfigStateCopyWith<$Res>  {
  factory $ServerConfigStateCopyWith(ServerConfigState value, $Res Function(ServerConfigState) _then) = _$ServerConfigStateCopyWithImpl;
@useResult
$Res call({
 ServerConfigList configList, String? editingConfigId, String name, String url, String username, String password, List<String> autoSwitchWifiNames, bool isSaving
});


$ServerConfigListCopyWith<$Res> get configList;

}
/// @nodoc
class _$ServerConfigStateCopyWithImpl<$Res>
    implements $ServerConfigStateCopyWith<$Res> {
  _$ServerConfigStateCopyWithImpl(this._self, this._then);

  final ServerConfigState _self;
  final $Res Function(ServerConfigState) _then;

/// Create a copy of ServerConfigState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? configList = null,Object? editingConfigId = freezed,Object? name = null,Object? url = null,Object? username = null,Object? password = null,Object? autoSwitchWifiNames = null,Object? isSaving = null,}) {
  return _then(_self.copyWith(
configList: null == configList ? _self.configList : configList // ignore: cast_nullable_to_non_nullable
as ServerConfigList,editingConfigId: freezed == editingConfigId ? _self.editingConfigId : editingConfigId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,autoSwitchWifiNames: null == autoSwitchWifiNames ? _self.autoSwitchWifiNames : autoSwitchWifiNames // ignore: cast_nullable_to_non_nullable
as List<String>,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ServerConfigState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServerConfigListCopyWith<$Res> get configList {
  
  return $ServerConfigListCopyWith<$Res>(_self.configList, (value) {
    return _then(_self.copyWith(configList: value));
  });
}
}


/// Adds pattern-matching-related methods to [ServerConfigState].
extension ServerConfigStatePatterns on ServerConfigState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServerConfigState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServerConfigState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServerConfigState value)  $default,){
final _that = this;
switch (_that) {
case _ServerConfigState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServerConfigState value)?  $default,){
final _that = this;
switch (_that) {
case _ServerConfigState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ServerConfigList configList,  String? editingConfigId,  String name,  String url,  String username,  String password,  List<String> autoSwitchWifiNames,  bool isSaving)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServerConfigState() when $default != null:
return $default(_that.configList,_that.editingConfigId,_that.name,_that.url,_that.username,_that.password,_that.autoSwitchWifiNames,_that.isSaving);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ServerConfigList configList,  String? editingConfigId,  String name,  String url,  String username,  String password,  List<String> autoSwitchWifiNames,  bool isSaving)  $default,) {final _that = this;
switch (_that) {
case _ServerConfigState():
return $default(_that.configList,_that.editingConfigId,_that.name,_that.url,_that.username,_that.password,_that.autoSwitchWifiNames,_that.isSaving);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ServerConfigList configList,  String? editingConfigId,  String name,  String url,  String username,  String password,  List<String> autoSwitchWifiNames,  bool isSaving)?  $default,) {final _that = this;
switch (_that) {
case _ServerConfigState() when $default != null:
return $default(_that.configList,_that.editingConfigId,_that.name,_that.url,_that.username,_that.password,_that.autoSwitchWifiNames,_that.isSaving);case _:
  return null;

}
}

}

/// @nodoc


class _ServerConfigState implements ServerConfigState {
  const _ServerConfigState({required this.configList, this.editingConfigId, this.name = '', this.url = '', this.username = '', this.password = '', final  List<String> autoSwitchWifiNames = const [], this.isSaving = false}): _autoSwitchWifiNames = autoSwitchWifiNames;
  

@override final  ServerConfigList configList;
@override final  String? editingConfigId;
@override@JsonKey() final  String name;
@override@JsonKey() final  String url;
@override@JsonKey() final  String username;
@override@JsonKey() final  String password;
 final  List<String> _autoSwitchWifiNames;
@override@JsonKey() List<String> get autoSwitchWifiNames {
  if (_autoSwitchWifiNames is EqualUnmodifiableListView) return _autoSwitchWifiNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_autoSwitchWifiNames);
}

@override@JsonKey() final  bool isSaving;

/// Create a copy of ServerConfigState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServerConfigStateCopyWith<_ServerConfigState> get copyWith => __$ServerConfigStateCopyWithImpl<_ServerConfigState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServerConfigState&&(identical(other.configList, configList) || other.configList == configList)&&(identical(other.editingConfigId, editingConfigId) || other.editingConfigId == editingConfigId)&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password)&&const DeepCollectionEquality().equals(other._autoSwitchWifiNames, _autoSwitchWifiNames)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving));
}


@override
int get hashCode => Object.hash(runtimeType,configList,editingConfigId,name,url,username,password,const DeepCollectionEquality().hash(_autoSwitchWifiNames),isSaving);

@override
String toString() {
  return 'ServerConfigState(configList: $configList, editingConfigId: $editingConfigId, name: $name, url: $url, username: $username, password: $password, autoSwitchWifiNames: $autoSwitchWifiNames, isSaving: $isSaving)';
}


}

/// @nodoc
abstract mixin class _$ServerConfigStateCopyWith<$Res> implements $ServerConfigStateCopyWith<$Res> {
  factory _$ServerConfigStateCopyWith(_ServerConfigState value, $Res Function(_ServerConfigState) _then) = __$ServerConfigStateCopyWithImpl;
@override @useResult
$Res call({
 ServerConfigList configList, String? editingConfigId, String name, String url, String username, String password, List<String> autoSwitchWifiNames, bool isSaving
});


@override $ServerConfigListCopyWith<$Res> get configList;

}
/// @nodoc
class __$ServerConfigStateCopyWithImpl<$Res>
    implements _$ServerConfigStateCopyWith<$Res> {
  __$ServerConfigStateCopyWithImpl(this._self, this._then);

  final _ServerConfigState _self;
  final $Res Function(_ServerConfigState) _then;

/// Create a copy of ServerConfigState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? configList = null,Object? editingConfigId = freezed,Object? name = null,Object? url = null,Object? username = null,Object? password = null,Object? autoSwitchWifiNames = null,Object? isSaving = null,}) {
  return _then(_ServerConfigState(
configList: null == configList ? _self.configList : configList // ignore: cast_nullable_to_non_nullable
as ServerConfigList,editingConfigId: freezed == editingConfigId ? _self.editingConfigId : editingConfigId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,autoSwitchWifiNames: null == autoSwitchWifiNames ? _self._autoSwitchWifiNames : autoSwitchWifiNames // ignore: cast_nullable_to_non_nullable
as List<String>,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ServerConfigState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServerConfigListCopyWith<$Res> get configList {
  
  return $ServerConfigListCopyWith<$Res>(_self.configList, (value) {
    return _then(_self.copyWith(configList: value));
  });
}
}

// dart format on
