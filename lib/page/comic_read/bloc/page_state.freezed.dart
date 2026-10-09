// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'page_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PageState {

 PageStatus get status; NormalComicEpInfo? get epInfo; String get errorMessage;
/// Create a copy of PageState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageStateCopyWith<PageState> get copyWith => _$PageStateCopyWithImpl<PageState>(this as PageState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PageState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageState&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.epInfo, _this.epInfo) || other.epInfo == _this.epInfo)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as PageState;
  return Object.hash(runtimeType,_this.status,_this.epInfo,_this.errorMessage);
}

@override
String toString() {
  final _this = this as PageState;
  return 'PageState(status: ${_this.status}, epInfo: ${_this.epInfo}, errorMessage: ${_this.errorMessage})';
}


}

/// @nodoc
abstract mixin class $PageStateCopyWith<$Res>  {
  factory $PageStateCopyWith(PageState value, $Res Function(PageState) _then) = _$PageStateCopyWithImpl;
@useResult
$Res call({
 PageStatus status, NormalComicEpInfo? epInfo, String errorMessage
});




}
/// @nodoc
class _$PageStateCopyWithImpl<$Res>
    implements $PageStateCopyWith<$Res> {
  _$PageStateCopyWithImpl(this._self, this._then);

  final PageState _self;
  final $Res Function(PageState) _then;

/// Create a copy of PageState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? epInfo = freezed,Object? errorMessage = null,}) {
  return _then(PageState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PageStatus,epInfo: freezed == epInfo ? _self.epInfo : epInfo // ignore: cast_nullable_to_non_nullable
as NormalComicEpInfo?,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PageState].
extension PageStatePatterns on PageState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PageState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PageState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PageState value)  $default,){
final _that = this;
switch (_that) {
case _PageState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PageState value)?  $default,){
final _that = this;
switch (_that) {
case _PageState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PageStatus status,  NormalComicEpInfo? epInfo,  String errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PageState() when $default != null:
return $default(_that.status,_that.epInfo,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PageStatus status,  NormalComicEpInfo? epInfo,  String errorMessage)  $default,) {final _that = this;
switch (_that) {
case _PageState():
return $default(_that.status,_that.epInfo,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PageStatus status,  NormalComicEpInfo? epInfo,  String errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _PageState() when $default != null:
return $default(_that.status,_that.epInfo,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _PageState implements PageState {
  const _PageState({this.status = PageStatus.initial, this.epInfo, this.errorMessage = ''});
  

@override@JsonKey() final  PageStatus status;
@override final  NormalComicEpInfo? epInfo;
@override@JsonKey() final  String errorMessage;

/// Create a copy of PageState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageStateCopyWith<_PageState> get copyWith => __$PageStateCopyWithImpl<_PageState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PageState&&(identical(other.status, status) || other.status == status)&&(identical(other.epInfo, epInfo) || other.epInfo == epInfo)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,epInfo,errorMessage);
}

@override
String toString() {
    return 'PageState(status: $status, epInfo: $epInfo, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$PageStateCopyWith<$Res> implements $PageStateCopyWith<$Res> {
  factory _$PageStateCopyWith(_PageState value, $Res Function(_PageState) _then) = __$PageStateCopyWithImpl;
@override @useResult
$Res call({
 PageStatus status, NormalComicEpInfo? epInfo, String errorMessage
});




}
/// @nodoc
class __$PageStateCopyWithImpl<$Res>
    implements _$PageStateCopyWith<$Res> {
  __$PageStateCopyWithImpl(this._self, this._then);

  final _PageState _self;
  final $Res Function(_PageState) _then;

/// Create a copy of PageState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? epInfo = freezed,Object? errorMessage = null,}) {
  return _then(_PageState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PageStatus,epInfo: freezed == epInfo ? _self.epInfo : epInfo // ignore: cast_nullable_to_non_nullable
as NormalComicEpInfo?,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
