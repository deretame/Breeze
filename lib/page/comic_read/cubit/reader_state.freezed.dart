// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reader_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReaderState {

 int get currentSlot; int get totalSlots; bool get isMenuVisible; double get sliderValue; bool get isSliderRolling; bool get isComicRolling;
/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReaderStateCopyWith<ReaderState> get copyWith => _$ReaderStateCopyWithImpl<ReaderState>(this as ReaderState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ReaderState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderState&&(identical(other.currentSlot, _this.currentSlot) || other.currentSlot == _this.currentSlot)&&(identical(other.totalSlots, _this.totalSlots) || other.totalSlots == _this.totalSlots)&&(identical(other.isMenuVisible, _this.isMenuVisible) || other.isMenuVisible == _this.isMenuVisible)&&(identical(other.sliderValue, _this.sliderValue) || other.sliderValue == _this.sliderValue)&&(identical(other.isSliderRolling, _this.isSliderRolling) || other.isSliderRolling == _this.isSliderRolling)&&(identical(other.isComicRolling, _this.isComicRolling) || other.isComicRolling == _this.isComicRolling));
}


@override
int get hashCode {
  final _this = this as ReaderState;
  return Object.hash(runtimeType,_this.currentSlot,_this.totalSlots,_this.isMenuVisible,_this.sliderValue,_this.isSliderRolling,_this.isComicRolling);
}

@override
String toString() {
  final _this = this as ReaderState;
  return 'ReaderState(currentSlot: ${_this.currentSlot}, totalSlots: ${_this.totalSlots}, isMenuVisible: ${_this.isMenuVisible}, sliderValue: ${_this.sliderValue}, isSliderRolling: ${_this.isSliderRolling}, isComicRolling: ${_this.isComicRolling})';
}


}

/// @nodoc
abstract mixin class $ReaderStateCopyWith<$Res>  {
  factory $ReaderStateCopyWith(ReaderState value, $Res Function(ReaderState) _then) = _$ReaderStateCopyWithImpl;
@useResult
$Res call({
 int currentSlot, int totalSlots, bool isMenuVisible, double sliderValue, bool isSliderRolling, bool isComicRolling
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
@pragma('vm:prefer-inline') @override $Res call({Object? currentSlot = null,Object? totalSlots = null,Object? isMenuVisible = null,Object? sliderValue = null,Object? isSliderRolling = null,Object? isComicRolling = null,}) {
  return _then(ReaderState(
currentSlot: null == currentSlot ? _self.currentSlot : currentSlot // ignore: cast_nullable_to_non_nullable
as int,totalSlots: null == totalSlots ? _self.totalSlots : totalSlots // ignore: cast_nullable_to_non_nullable
as int,isMenuVisible: null == isMenuVisible ? _self.isMenuVisible : isMenuVisible // ignore: cast_nullable_to_non_nullable
as bool,sliderValue: null == sliderValue ? _self.sliderValue : sliderValue // ignore: cast_nullable_to_non_nullable
as double,isSliderRolling: null == isSliderRolling ? _self.isSliderRolling : isSliderRolling // ignore: cast_nullable_to_non_nullable
as bool,isComicRolling: null == isComicRolling ? _self.isComicRolling : isComicRolling // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int currentSlot,  int totalSlots,  bool isMenuVisible,  double sliderValue,  bool isSliderRolling,  bool isComicRolling)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReaderState() when $default != null:
return $default(_that.currentSlot,_that.totalSlots,_that.isMenuVisible,_that.sliderValue,_that.isSliderRolling,_that.isComicRolling);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int currentSlot,  int totalSlots,  bool isMenuVisible,  double sliderValue,  bool isSliderRolling,  bool isComicRolling)  $default,) {final _that = this;
switch (_that) {
case _ReaderState():
return $default(_that.currentSlot,_that.totalSlots,_that.isMenuVisible,_that.sliderValue,_that.isSliderRolling,_that.isComicRolling);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int currentSlot,  int totalSlots,  bool isMenuVisible,  double sliderValue,  bool isSliderRolling,  bool isComicRolling)?  $default,) {final _that = this;
switch (_that) {
case _ReaderState() when $default != null:
return $default(_that.currentSlot,_that.totalSlots,_that.isMenuVisible,_that.sliderValue,_that.isSliderRolling,_that.isComicRolling);case _:
  return null;

}
}

}

/// @nodoc


class _ReaderState implements ReaderState {
  const _ReaderState({this.currentSlot = 0, this.totalSlots = 0, this.isMenuVisible = true, this.sliderValue = 0.0, this.isSliderRolling = false, this.isComicRolling = false});
  

@override@JsonKey() final  int currentSlot;
@override@JsonKey() final  int totalSlots;
@override@JsonKey() final  bool isMenuVisible;
@override@JsonKey() final  double sliderValue;
@override@JsonKey() final  bool isSliderRolling;
@override@JsonKey() final  bool isComicRolling;

/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReaderStateCopyWith<_ReaderState> get copyWith => __$ReaderStateCopyWithImpl<_ReaderState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReaderState&&(identical(other.currentSlot, currentSlot) || other.currentSlot == currentSlot)&&(identical(other.totalSlots, totalSlots) || other.totalSlots == totalSlots)&&(identical(other.isMenuVisible, isMenuVisible) || other.isMenuVisible == isMenuVisible)&&(identical(other.sliderValue, sliderValue) || other.sliderValue == sliderValue)&&(identical(other.isSliderRolling, isSliderRolling) || other.isSliderRolling == isSliderRolling)&&(identical(other.isComicRolling, isComicRolling) || other.isComicRolling == isComicRolling));
}


@override
int get hashCode {
    return Object.hash(runtimeType,currentSlot,totalSlots,isMenuVisible,sliderValue,isSliderRolling,isComicRolling);
}

@override
String toString() {
    return 'ReaderState(currentSlot: $currentSlot, totalSlots: $totalSlots, isMenuVisible: $isMenuVisible, sliderValue: $sliderValue, isSliderRolling: $isSliderRolling, isComicRolling: $isComicRolling)';
}


}

/// @nodoc
abstract mixin class _$ReaderStateCopyWith<$Res> implements $ReaderStateCopyWith<$Res> {
  factory _$ReaderStateCopyWith(_ReaderState value, $Res Function(_ReaderState) _then) = __$ReaderStateCopyWithImpl;
@override @useResult
$Res call({
 int currentSlot, int totalSlots, bool isMenuVisible, double sliderValue, bool isSliderRolling, bool isComicRolling
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
@override @pragma('vm:prefer-inline') $Res call({Object? currentSlot = null,Object? totalSlots = null,Object? isMenuVisible = null,Object? sliderValue = null,Object? isSliderRolling = null,Object? isComicRolling = null,}) {
  return _then(_ReaderState(
currentSlot: null == currentSlot ? _self.currentSlot : currentSlot // ignore: cast_nullable_to_non_nullable
as int,totalSlots: null == totalSlots ? _self.totalSlots : totalSlots // ignore: cast_nullable_to_non_nullable
as int,isMenuVisible: null == isMenuVisible ? _self.isMenuVisible : isMenuVisible // ignore: cast_nullable_to_non_nullable
as bool,sliderValue: null == sliderValue ? _self.sliderValue : sliderValue // ignore: cast_nullable_to_non_nullable
as double,isSliderRolling: null == isSliderRolling ? _self.isSliderRolling : isSliderRolling // ignore: cast_nullable_to_non_nullable
as bool,isComicRolling: null == isComicRolling ? _self.isComicRolling : isComicRolling // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
