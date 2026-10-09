// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'picture_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PictureLoadState {

 PictureLoadStatus get status; String? get imagePath; String? get result;
/// Create a copy of PictureLoadState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PictureLoadStateCopyWith<PictureLoadState> get copyWith => _$PictureLoadStateCopyWithImpl<PictureLoadState>(this as PictureLoadState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PictureLoadState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PictureLoadState&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.imagePath, _this.imagePath) || other.imagePath == _this.imagePath)&&(identical(other.result, _this.result) || other.result == _this.result));
}


@override
int get hashCode {
  final _this = this as PictureLoadState;
  return Object.hash(runtimeType,_this.status,_this.imagePath,_this.result);
}

@override
String toString() {
  final _this = this as PictureLoadState;
  return 'PictureLoadState(status: ${_this.status}, imagePath: ${_this.imagePath}, result: ${_this.result})';
}


}

/// @nodoc
abstract mixin class $PictureLoadStateCopyWith<$Res>  {
  factory $PictureLoadStateCopyWith(PictureLoadState value, $Res Function(PictureLoadState) _then) = _$PictureLoadStateCopyWithImpl;
@useResult
$Res call({
 PictureLoadStatus status, String? imagePath, String? result
});




}
/// @nodoc
class _$PictureLoadStateCopyWithImpl<$Res>
    implements $PictureLoadStateCopyWith<$Res> {
  _$PictureLoadStateCopyWithImpl(this._self, this._then);

  final PictureLoadState _self;
  final $Res Function(PictureLoadState) _then;

/// Create a copy of PictureLoadState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? imagePath = freezed,Object? result = freezed,}) {
  return _then(PictureLoadState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PictureLoadStatus,imagePath: freezed == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String?,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PictureLoadState].
extension PictureLoadStatePatterns on PictureLoadState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PictureLoadState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PictureLoadState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PictureLoadState value)  $default,){
final _that = this;
switch (_that) {
case _PictureLoadState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PictureLoadState value)?  $default,){
final _that = this;
switch (_that) {
case _PictureLoadState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PictureLoadStatus status,  String? imagePath,  String? result)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PictureLoadState() when $default != null:
return $default(_that.status,_that.imagePath,_that.result);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PictureLoadStatus status,  String? imagePath,  String? result)  $default,) {final _that = this;
switch (_that) {
case _PictureLoadState():
return $default(_that.status,_that.imagePath,_that.result);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PictureLoadStatus status,  String? imagePath,  String? result)?  $default,) {final _that = this;
switch (_that) {
case _PictureLoadState() when $default != null:
return $default(_that.status,_that.imagePath,_that.result);case _:
  return null;

}
}

}

/// @nodoc


class _PictureLoadState implements PictureLoadState {
  const _PictureLoadState({this.status = PictureLoadStatus.initial, this.imagePath, this.result});
  

@override@JsonKey() final  PictureLoadStatus status;
@override final  String? imagePath;
@override final  String? result;

/// Create a copy of PictureLoadState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PictureLoadStateCopyWith<_PictureLoadState> get copyWith => __$PictureLoadStateCopyWithImpl<_PictureLoadState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PictureLoadState&&(identical(other.status, status) || other.status == status)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,imagePath,result);
}

@override
String toString() {
    return 'PictureLoadState(status: $status, imagePath: $imagePath, result: $result)';
}


}

/// @nodoc
abstract mixin class _$PictureLoadStateCopyWith<$Res> implements $PictureLoadStateCopyWith<$Res> {
  factory _$PictureLoadStateCopyWith(_PictureLoadState value, $Res Function(_PictureLoadState) _then) = __$PictureLoadStateCopyWithImpl;
@override @useResult
$Res call({
 PictureLoadStatus status, String? imagePath, String? result
});




}
/// @nodoc
class __$PictureLoadStateCopyWithImpl<$Res>
    implements _$PictureLoadStateCopyWith<$Res> {
  __$PictureLoadStateCopyWithImpl(this._self, this._then);

  final _PictureLoadState _self;
  final $Res Function(_PictureLoadState) _then;

/// Create a copy of PictureLoadState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? imagePath = freezed,Object? result = freezed,}) {
  return _then(_PictureLoadState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PictureLoadStatus,imagePath: freezed == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String?,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
