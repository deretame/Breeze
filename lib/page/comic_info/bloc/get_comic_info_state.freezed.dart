// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'get_comic_info_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GetComicInfoState {

 GetComicInfoStatus get status; NormalComicAllInfo? get allInfo; dynamic get comicInfo; String? get comicId; String get result;
/// Create a copy of GetComicInfoState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GetComicInfoStateCopyWith<GetComicInfoState> get copyWith => _$GetComicInfoStateCopyWithImpl<GetComicInfoState>(this as GetComicInfoState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GetComicInfoState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GetComicInfoState&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.allInfo, _this.allInfo) || other.allInfo == _this.allInfo)&&const DeepCollectionEquality().equals(other.comicInfo, _this.comicInfo)&&(identical(other.comicId, _this.comicId) || other.comicId == _this.comicId)&&(identical(other.result, _this.result) || other.result == _this.result));
}


@override
int get hashCode {
  final _this = this as GetComicInfoState;
  return Object.hash(runtimeType,_this.status,_this.allInfo,const DeepCollectionEquality().hash(_this.comicInfo),_this.comicId,_this.result);
}

@override
String toString() {
  final _this = this as GetComicInfoState;
  return 'GetComicInfoState(status: ${_this.status}, allInfo: ${_this.allInfo}, comicInfo: ${_this.comicInfo}, comicId: ${_this.comicId}, result: ${_this.result})';
}


}

/// @nodoc
abstract mixin class $GetComicInfoStateCopyWith<$Res>  {
  factory $GetComicInfoStateCopyWith(GetComicInfoState value, $Res Function(GetComicInfoState) _then) = _$GetComicInfoStateCopyWithImpl;
@useResult
$Res call({
 GetComicInfoStatus status, NormalComicAllInfo? allInfo, dynamic comicInfo, String? comicId, String result
});


$NormalComicAllInfoCopyWith<$Res>? get allInfo;

}
/// @nodoc
class _$GetComicInfoStateCopyWithImpl<$Res>
    implements $GetComicInfoStateCopyWith<$Res> {
  _$GetComicInfoStateCopyWithImpl(this._self, this._then);

  final GetComicInfoState _self;
  final $Res Function(GetComicInfoState) _then;

/// Create a copy of GetComicInfoState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? allInfo = freezed,Object? comicInfo = freezed,Object? comicId = freezed,Object? result = null,}) {
  return _then(GetComicInfoState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GetComicInfoStatus,allInfo: freezed == allInfo ? _self.allInfo : allInfo // ignore: cast_nullable_to_non_nullable
as NormalComicAllInfo?,comicInfo: freezed == comicInfo ? _self.comicInfo : comicInfo // ignore: cast_nullable_to_non_nullable
as dynamic,comicId: freezed == comicId ? _self.comicId : comicId // ignore: cast_nullable_to_non_nullable
as String?,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of GetComicInfoState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NormalComicAllInfoCopyWith<$Res>? get allInfo {
    if (_self.allInfo == null) {
    return null;
  }

  return $NormalComicAllInfoCopyWith<$Res>(_self.allInfo!, (value) {
    return _then(_self.copyWith(allInfo: value));
  });
}
}


/// Adds pattern-matching-related methods to [GetComicInfoState].
extension GetComicInfoStatePatterns on GetComicInfoState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GetComicInfoState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GetComicInfoState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GetComicInfoState value)  $default,){
final _that = this;
switch (_that) {
case _GetComicInfoState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GetComicInfoState value)?  $default,){
final _that = this;
switch (_that) {
case _GetComicInfoState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GetComicInfoStatus status,  NormalComicAllInfo? allInfo,  dynamic comicInfo,  String? comicId,  String result)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GetComicInfoState() when $default != null:
return $default(_that.status,_that.allInfo,_that.comicInfo,_that.comicId,_that.result);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GetComicInfoStatus status,  NormalComicAllInfo? allInfo,  dynamic comicInfo,  String? comicId,  String result)  $default,) {final _that = this;
switch (_that) {
case _GetComicInfoState():
return $default(_that.status,_that.allInfo,_that.comicInfo,_that.comicId,_that.result);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GetComicInfoStatus status,  NormalComicAllInfo? allInfo,  dynamic comicInfo,  String? comicId,  String result)?  $default,) {final _that = this;
switch (_that) {
case _GetComicInfoState() when $default != null:
return $default(_that.status,_that.allInfo,_that.comicInfo,_that.comicId,_that.result);case _:
  return null;

}
}

}

/// @nodoc


class _GetComicInfoState implements GetComicInfoState {
  const _GetComicInfoState({this.status = GetComicInfoStatus.initial, this.allInfo, this.comicInfo, this.comicId, this.result = ''});
  

@override@JsonKey() final  GetComicInfoStatus status;
@override final  NormalComicAllInfo? allInfo;
@override final  dynamic comicInfo;
@override final  String? comicId;
@override@JsonKey() final  String result;

/// Create a copy of GetComicInfoState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GetComicInfoStateCopyWith<_GetComicInfoState> get copyWith => __$GetComicInfoStateCopyWithImpl<_GetComicInfoState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GetComicInfoState&&(identical(other.status, status) || other.status == status)&&(identical(other.allInfo, allInfo) || other.allInfo == allInfo)&&const DeepCollectionEquality().equals(other.comicInfo, comicInfo)&&(identical(other.comicId, comicId) || other.comicId == comicId)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,allInfo,const DeepCollectionEquality().hash(comicInfo),comicId,result);
}

@override
String toString() {
    return 'GetComicInfoState(status: $status, allInfo: $allInfo, comicInfo: $comicInfo, comicId: $comicId, result: $result)';
}


}

/// @nodoc
abstract mixin class _$GetComicInfoStateCopyWith<$Res> implements $GetComicInfoStateCopyWith<$Res> {
  factory _$GetComicInfoStateCopyWith(_GetComicInfoState value, $Res Function(_GetComicInfoState) _then) = __$GetComicInfoStateCopyWithImpl;
@override @useResult
$Res call({
 GetComicInfoStatus status, NormalComicAllInfo? allInfo, dynamic comicInfo, String? comicId, String result
});


@override $NormalComicAllInfoCopyWith<$Res>? get allInfo;

}
/// @nodoc
class __$GetComicInfoStateCopyWithImpl<$Res>
    implements _$GetComicInfoStateCopyWith<$Res> {
  __$GetComicInfoStateCopyWithImpl(this._self, this._then);

  final _GetComicInfoState _self;
  final $Res Function(_GetComicInfoState) _then;

/// Create a copy of GetComicInfoState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? allInfo = freezed,Object? comicInfo = freezed,Object? comicId = freezed,Object? result = null,}) {
  return _then(_GetComicInfoState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GetComicInfoStatus,allInfo: freezed == allInfo ? _self.allInfo : allInfo // ignore: cast_nullable_to_non_nullable
as NormalComicAllInfo?,comicInfo: freezed == comicInfo ? _self.comicInfo : comicInfo // ignore: cast_nullable_to_non_nullable
as dynamic,comicId: freezed == comicId ? _self.comicId : comicId // ignore: cast_nullable_to_non_nullable
as String?,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of GetComicInfoState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NormalComicAllInfoCopyWith<$Res>? get allInfo {
    if (_self.allInfo == null) {
    return null;
  }

  return $NormalComicAllInfoCopyWith<$Res>(_self.allInfo!, (value) {
    return _then(_self.copyWith(allInfo: value));
  });
}
}

// dart format on
