// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clipboard.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Clipboard {

 ClipboardType get type;@JsonKey(fromJson: _hashFromJson, toJson: _hashToJson, includeIfNull: false) String? get hash; String get text; bool get hasData;@JsonKey(includeIfNull: false) String? get dataName;@JsonKey(includeIfNull: false) int? get size;
/// Create a copy of Clipboard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClipboardCopyWith<Clipboard> get copyWith => _$ClipboardCopyWithImpl<Clipboard>(this as Clipboard, _$identity);

  /// Serializes this Clipboard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Clipboard&&(identical(other.type, type) || other.type == type)&&(identical(other.hash, hash) || other.hash == hash)&&(identical(other.text, text) || other.text == text)&&(identical(other.hasData, hasData) || other.hasData == hasData)&&(identical(other.dataName, dataName) || other.dataName == dataName)&&(identical(other.size, size) || other.size == size));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,hash,text,hasData,dataName,size);

@override
String toString() {
  return 'Clipboard(type: $type, hash: $hash, text: $text, hasData: $hasData, dataName: $dataName, size: $size)';
}


}

/// @nodoc
abstract mixin class $ClipboardCopyWith<$Res>  {
  factory $ClipboardCopyWith(Clipboard value, $Res Function(Clipboard) _then) = _$ClipboardCopyWithImpl;
@useResult
$Res call({
 ClipboardType type,@JsonKey(fromJson: _hashFromJson, toJson: _hashToJson, includeIfNull: false) String? hash, String text, bool hasData,@JsonKey(includeIfNull: false) String? dataName,@JsonKey(includeIfNull: false) int? size
});




}
/// @nodoc
class _$ClipboardCopyWithImpl<$Res>
    implements $ClipboardCopyWith<$Res> {
  _$ClipboardCopyWithImpl(this._self, this._then);

  final Clipboard _self;
  final $Res Function(Clipboard) _then;

/// Create a copy of Clipboard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? hash = freezed,Object? text = null,Object? hasData = null,Object? dataName = freezed,Object? size = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ClipboardType,hash: freezed == hash ? _self.hash : hash // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,hasData: null == hasData ? _self.hasData : hasData // ignore: cast_nullable_to_non_nullable
as bool,dataName: freezed == dataName ? _self.dataName : dataName // ignore: cast_nullable_to_non_nullable
as String?,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Clipboard].
extension ClipboardPatterns on Clipboard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Clipboard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Clipboard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Clipboard value)  $default,){
final _that = this;
switch (_that) {
case _Clipboard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Clipboard value)?  $default,){
final _that = this;
switch (_that) {
case _Clipboard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ClipboardType type, @JsonKey(fromJson: _hashFromJson, toJson: _hashToJson, includeIfNull: false)  String? hash,  String text,  bool hasData, @JsonKey(includeIfNull: false)  String? dataName, @JsonKey(includeIfNull: false)  int? size)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Clipboard() when $default != null:
return $default(_that.type,_that.hash,_that.text,_that.hasData,_that.dataName,_that.size);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ClipboardType type, @JsonKey(fromJson: _hashFromJson, toJson: _hashToJson, includeIfNull: false)  String? hash,  String text,  bool hasData, @JsonKey(includeIfNull: false)  String? dataName, @JsonKey(includeIfNull: false)  int? size)  $default,) {final _that = this;
switch (_that) {
case _Clipboard():
return $default(_that.type,_that.hash,_that.text,_that.hasData,_that.dataName,_that.size);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ClipboardType type, @JsonKey(fromJson: _hashFromJson, toJson: _hashToJson, includeIfNull: false)  String? hash,  String text,  bool hasData, @JsonKey(includeIfNull: false)  String? dataName, @JsonKey(includeIfNull: false)  int? size)?  $default,) {final _that = this;
switch (_that) {
case _Clipboard() when $default != null:
return $default(_that.type,_that.hash,_that.text,_that.hasData,_that.dataName,_that.size);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Clipboard implements Clipboard {
  const _Clipboard({required this.type, @JsonKey(fromJson: _hashFromJson, toJson: _hashToJson, includeIfNull: false) this.hash, required this.text, required this.hasData, @JsonKey(includeIfNull: false) this.dataName, @JsonKey(includeIfNull: false) this.size});
  factory _Clipboard.fromJson(Map<String, dynamic> json) => _$ClipboardFromJson(json);

@override final  ClipboardType type;
@override@JsonKey(fromJson: _hashFromJson, toJson: _hashToJson, includeIfNull: false) final  String? hash;
@override final  String text;
@override final  bool hasData;
@override@JsonKey(includeIfNull: false) final  String? dataName;
@override@JsonKey(includeIfNull: false) final  int? size;

/// Create a copy of Clipboard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClipboardCopyWith<_Clipboard> get copyWith => __$ClipboardCopyWithImpl<_Clipboard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClipboardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Clipboard&&(identical(other.type, type) || other.type == type)&&(identical(other.hash, hash) || other.hash == hash)&&(identical(other.text, text) || other.text == text)&&(identical(other.hasData, hasData) || other.hasData == hasData)&&(identical(other.dataName, dataName) || other.dataName == dataName)&&(identical(other.size, size) || other.size == size));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,hash,text,hasData,dataName,size);

@override
String toString() {
  return 'Clipboard(type: $type, hash: $hash, text: $text, hasData: $hasData, dataName: $dataName, size: $size)';
}


}

/// @nodoc
abstract mixin class _$ClipboardCopyWith<$Res> implements $ClipboardCopyWith<$Res> {
  factory _$ClipboardCopyWith(_Clipboard value, $Res Function(_Clipboard) _then) = __$ClipboardCopyWithImpl;
@override @useResult
$Res call({
 ClipboardType type,@JsonKey(fromJson: _hashFromJson, toJson: _hashToJson, includeIfNull: false) String? hash, String text, bool hasData,@JsonKey(includeIfNull: false) String? dataName,@JsonKey(includeIfNull: false) int? size
});




}
/// @nodoc
class __$ClipboardCopyWithImpl<$Res>
    implements _$ClipboardCopyWith<$Res> {
  __$ClipboardCopyWithImpl(this._self, this._then);

  final _Clipboard _self;
  final $Res Function(_Clipboard) _then;

/// Create a copy of Clipboard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? hash = freezed,Object? text = null,Object? hasData = null,Object? dataName = freezed,Object? size = freezed,}) {
  return _then(_Clipboard(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ClipboardType,hash: freezed == hash ? _self.hash : hash // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,hasData: null == hasData ? _self.hasData : hasData // ignore: cast_nullable_to_non_nullable
as bool,dataName: freezed == dataName ? _self.dataName : dataName // ignore: cast_nullable_to_non_nullable
as String?,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
