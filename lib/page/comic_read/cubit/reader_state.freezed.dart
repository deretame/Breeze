// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reader_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReaderState {

 int get pageIndex;// 当前页码
 int get totalSlots;// 总页数/槽位数
 bool get isMenuVisible;// 菜单显隐
 double get sliderValue;// 滑块进度
 bool get isSliderRolling;
/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReaderStateCopyWith<ReaderState> get copyWith => _$ReaderStateCopyWithImpl<ReaderState>(this as ReaderState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderState&&(identical(other.pageIndex, pageIndex) || other.pageIndex == pageIndex)&&(identical(other.totalSlots, totalSlots) || other.totalSlots == totalSlots)&&(identical(other.isMenuVisible, isMenuVisible) || other.isMenuVisible == isMenuVisible)&&(identical(other.sliderValue, sliderValue) || other.sliderValue == sliderValue)&&(identical(other.isSliderRolling, isSliderRolling) || other.isSliderRolling == isSliderRolling));
}


@override
int get hashCode => Object.hash(runtimeType,pageIndex,totalSlots,isMenuVisible,sliderValue,isSliderRolling);

@override
String toString() {
  return 'ReaderState(pageIndex: $pageIndex, totalSlots: $totalSlots, isMenuVisible: $isMenuVisible, sliderValue: $sliderValue, isSliderRolling: $isSliderRolling)';
}


}

/// @nodoc
abstract mixin class $ReaderStateCopyWith<$Res>  {
  factory $ReaderStateCopyWith(ReaderState value, $Res Function(ReaderState) _then) = _$ReaderStateCopyWithImpl;
@useResult
$Res call({
 int pageIndex, int totalSlots, bool isMenuVisible, double sliderValue, bool isSliderRolling
});




}
/// @nodoc
class _$ReaderStateCopyWithImpl<$Res>
    implements $ReaderStateCopyWith<$Res> {
  _$ReaderStateCopyWithImpl(this._self, this._then);

  final ReaderState _self;
  final $Res Function(ReaderState) _then;

/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pageIndex = null,Object? totalSlots = null,Object? isMenuVisible = null,Object? sliderValue = null,Object? isSliderRolling = null,}) {
  return _then(_self.copyWith(
pageIndex: null == pageIndex ? _self.pageIndex : pageIndex // ignore: cast_nullable_to_non_nullable
as int,totalSlots: null == totalSlots ? _self.totalSlots : totalSlots // ignore: cast_nullable_to_non_nullable
as int,isMenuVisible: null == isMenuVisible ? _self.isMenuVisible : isMenuVisible // ignore: cast_nullable_to_non_nullable
as bool,sliderValue: null == sliderValue ? _self.sliderValue : sliderValue // ignore: cast_nullable_to_non_nullable
as double,isSliderRolling: null == isSliderRolling ? _self.isSliderRolling : isSliderRolling // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ReaderState].
extension ReaderStatePatterns on ReaderState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReaderState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReaderState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReaderState value)  $default,){
final _that = this;
switch (_that) {
case _ReaderState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReaderState value)?  $default,){
final _that = this;
switch (_that) {
case _ReaderState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int pageIndex,  int totalSlots,  bool isMenuVisible,  double sliderValue,  bool isSliderRolling)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReaderState() when $default != null:
return $default(_that.pageIndex,_that.totalSlots,_that.isMenuVisible,_that.sliderValue,_that.isSliderRolling);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int pageIndex,  int totalSlots,  bool isMenuVisible,  double sliderValue,  bool isSliderRolling)  $default,) {final _that = this;
switch (_that) {
case _ReaderState():
return $default(_that.pageIndex,_that.totalSlots,_that.isMenuVisible,_that.sliderValue,_that.isSliderRolling);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int pageIndex,  int totalSlots,  bool isMenuVisible,  double sliderValue,  bool isSliderRolling)?  $default,) {final _that = this;
switch (_that) {
case _ReaderState() when $default != null:
return $default(_that.pageIndex,_that.totalSlots,_that.isMenuVisible,_that.sliderValue,_that.isSliderRolling);case _:
  return null;

}
}

}

/// @nodoc


class _ReaderState implements ReaderState {
  const _ReaderState({this.pageIndex = 0, this.totalSlots = 0, this.isMenuVisible = true, this.sliderValue = 0.0, this.isSliderRolling = false});
  

@override@JsonKey() final  int pageIndex;
// 当前页码
@override@JsonKey() final  int totalSlots;
// 总页数/槽位数
@override@JsonKey() final  bool isMenuVisible;
// 菜单显隐
@override@JsonKey() final  double sliderValue;
// 滑块进度
@override@JsonKey() final  bool isSliderRolling;

/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReaderStateCopyWith<_ReaderState> get copyWith => __$ReaderStateCopyWithImpl<_ReaderState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReaderState&&(identical(other.pageIndex, pageIndex) || other.pageIndex == pageIndex)&&(identical(other.totalSlots, totalSlots) || other.totalSlots == totalSlots)&&(identical(other.isMenuVisible, isMenuVisible) || other.isMenuVisible == isMenuVisible)&&(identical(other.sliderValue, sliderValue) || other.sliderValue == sliderValue)&&(identical(other.isSliderRolling, isSliderRolling) || other.isSliderRolling == isSliderRolling));
}


@override
int get hashCode => Object.hash(runtimeType,pageIndex,totalSlots,isMenuVisible,sliderValue,isSliderRolling);

@override
String toString() {
  return 'ReaderState(pageIndex: $pageIndex, totalSlots: $totalSlots, isMenuVisible: $isMenuVisible, sliderValue: $sliderValue, isSliderRolling: $isSliderRolling)';
}


}

/// @nodoc
abstract mixin class _$ReaderStateCopyWith<$Res> implements $ReaderStateCopyWith<$Res> {
  factory _$ReaderStateCopyWith(_ReaderState value, $Res Function(_ReaderState) _then) = __$ReaderStateCopyWithImpl;
@override @useResult
$Res call({
 int pageIndex, int totalSlots, bool isMenuVisible, double sliderValue, bool isSliderRolling
});




}
/// @nodoc
class __$ReaderStateCopyWithImpl<$Res>
    implements _$ReaderStateCopyWith<$Res> {
  __$ReaderStateCopyWithImpl(this._self, this._then);

  final _ReaderState _self;
  final $Res Function(_ReaderState) _then;

/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pageIndex = null,Object? totalSlots = null,Object? isMenuVisible = null,Object? sliderValue = null,Object? isSliderRolling = null,}) {
  return _then(_ReaderState(
pageIndex: null == pageIndex ? _self.pageIndex : pageIndex // ignore: cast_nullable_to_non_nullable
as int,totalSlots: null == totalSlots ? _self.totalSlots : totalSlots // ignore: cast_nullable_to_non_nullable
as int,isMenuVisible: null == isMenuVisible ? _self.isMenuVisible : isMenuVisible // ignore: cast_nullable_to_non_nullable
as bool,sliderValue: null == sliderValue ? _self.sliderValue : sliderValue // ignore: cast_nullable_to_non_nullable
as double,isSliderRolling: null == isSliderRolling ? _self.isSliderRolling : isSliderRolling // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
