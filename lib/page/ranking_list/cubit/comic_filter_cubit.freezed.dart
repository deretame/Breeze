// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comic_filter_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ComicFilterState {

 String get mainKey; String get subKey; String get rankingKey;
/// Create a copy of ComicFilterState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicFilterStateCopyWith<ComicFilterState> get copyWith => _$ComicFilterStateCopyWithImpl<ComicFilterState>(this as ComicFilterState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicFilterState&&(identical(other.mainKey, mainKey) || other.mainKey == mainKey)&&(identical(other.subKey, subKey) || other.subKey == subKey)&&(identical(other.rankingKey, rankingKey) || other.rankingKey == rankingKey));
}


@override
int get hashCode => Object.hash(runtimeType,mainKey,subKey,rankingKey);

@override
String toString() {
  return 'ComicFilterState(mainKey: $mainKey, subKey: $subKey, rankingKey: $rankingKey)';
}


}

/// @nodoc
abstract mixin class $ComicFilterStateCopyWith<$Res>  {
  factory $ComicFilterStateCopyWith(ComicFilterState value, $Res Function(ComicFilterState) _then) = _$ComicFilterStateCopyWithImpl;
@useResult
$Res call({
 String mainKey, String subKey, String rankingKey
});




}
/// @nodoc
class _$ComicFilterStateCopyWithImpl<$Res>
    implements $ComicFilterStateCopyWith<$Res> {
  _$ComicFilterStateCopyWithImpl(this._self, this._then);

  final ComicFilterState _self;
  final $Res Function(ComicFilterState) _then;

/// Create a copy of ComicFilterState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mainKey = null,Object? subKey = null,Object? rankingKey = null,}) {
  return _then(_self.copyWith(
mainKey: null == mainKey ? _self.mainKey : mainKey // ignore: cast_nullable_to_non_nullable
as String,subKey: null == subKey ? _self.subKey : subKey // ignore: cast_nullable_to_non_nullable
as String,rankingKey: null == rankingKey ? _self.rankingKey : rankingKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ComicFilterState].
extension ComicFilterStatePatterns on ComicFilterState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicFilterState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicFilterState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicFilterState value)  $default,){
final _that = this;
switch (_that) {
case _ComicFilterState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicFilterState value)?  $default,){
final _that = this;
switch (_that) {
case _ComicFilterState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String mainKey,  String subKey,  String rankingKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicFilterState() when $default != null:
return $default(_that.mainKey,_that.subKey,_that.rankingKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String mainKey,  String subKey,  String rankingKey)  $default,) {final _that = this;
switch (_that) {
case _ComicFilterState():
return $default(_that.mainKey,_that.subKey,_that.rankingKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String mainKey,  String subKey,  String rankingKey)?  $default,) {final _that = this;
switch (_that) {
case _ComicFilterState() when $default != null:
return $default(_that.mainKey,_that.subKey,_that.rankingKey);case _:
  return null;

}
}

}

/// @nodoc


class _ComicFilterState implements ComicFilterState {
  const _ComicFilterState({this.mainKey = '', this.subKey = '', this.rankingKey = 'new'});
  

@override@JsonKey() final  String mainKey;
@override@JsonKey() final  String subKey;
@override@JsonKey() final  String rankingKey;

/// Create a copy of ComicFilterState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicFilterStateCopyWith<_ComicFilterState> get copyWith => __$ComicFilterStateCopyWithImpl<_ComicFilterState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicFilterState&&(identical(other.mainKey, mainKey) || other.mainKey == mainKey)&&(identical(other.subKey, subKey) || other.subKey == subKey)&&(identical(other.rankingKey, rankingKey) || other.rankingKey == rankingKey));
}


@override
int get hashCode => Object.hash(runtimeType,mainKey,subKey,rankingKey);

@override
String toString() {
  return 'ComicFilterState(mainKey: $mainKey, subKey: $subKey, rankingKey: $rankingKey)';
}


}

/// @nodoc
abstract mixin class _$ComicFilterStateCopyWith<$Res> implements $ComicFilterStateCopyWith<$Res> {
  factory _$ComicFilterStateCopyWith(_ComicFilterState value, $Res Function(_ComicFilterState) _then) = __$ComicFilterStateCopyWithImpl;
@override @useResult
$Res call({
 String mainKey, String subKey, String rankingKey
});




}
/// @nodoc
class __$ComicFilterStateCopyWithImpl<$Res>
    implements _$ComicFilterStateCopyWith<$Res> {
  __$ComicFilterStateCopyWithImpl(this._self, this._then);

  final _ComicFilterState _self;
  final $Res Function(_ComicFilterState) _then;

/// Create a copy of ComicFilterState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mainKey = null,Object? subKey = null,Object? rankingKey = null,}) {
  return _then(_ComicFilterState(
mainKey: null == mainKey ? _self.mainKey : mainKey // ignore: cast_nullable_to_non_nullable
as String,subKey: null == subKey ? _self.subKey : subKey // ignore: cast_nullable_to_non_nullable
as String,rankingKey: null == rankingKey ? _self.rankingKey : rankingKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
