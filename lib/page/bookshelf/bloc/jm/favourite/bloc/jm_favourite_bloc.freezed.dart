// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jm_favourite_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$JmFavouriteEvent {

 SearchEnter get searchEnterConst;
/// Create a copy of JmFavouriteEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JmFavouriteEventCopyWith<JmFavouriteEvent> get copyWith => _$JmFavouriteEventCopyWithImpl<JmFavouriteEvent>(this as JmFavouriteEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JmFavouriteEvent&&(identical(other.searchEnterConst, searchEnterConst) || other.searchEnterConst == searchEnterConst));
}


@override
int get hashCode => Object.hash(runtimeType,searchEnterConst);

@override
String toString() {
  return 'JmFavouriteEvent(searchEnterConst: $searchEnterConst)';
}


}

/// @nodoc
abstract mixin class $JmFavouriteEventCopyWith<$Res>  {
  factory $JmFavouriteEventCopyWith(JmFavouriteEvent value, $Res Function(JmFavouriteEvent) _then) = _$JmFavouriteEventCopyWithImpl;
@useResult
$Res call({
 SearchEnter searchEnterConst
});




}
/// @nodoc
class _$JmFavouriteEventCopyWithImpl<$Res>
    implements $JmFavouriteEventCopyWith<$Res> {
  _$JmFavouriteEventCopyWithImpl(this._self, this._then);

  final JmFavouriteEvent _self;
  final $Res Function(JmFavouriteEvent) _then;

/// Create a copy of JmFavouriteEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? searchEnterConst = null,}) {
  return _then(_self.copyWith(
searchEnterConst: null == searchEnterConst ? _self.searchEnterConst : searchEnterConst // ignore: cast_nullable_to_non_nullable
as SearchEnter,
  ));
}

}


/// Adds pattern-matching-related methods to [JmFavouriteEvent].
extension JmFavouriteEventPatterns on JmFavouriteEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JmFavouriteEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JmFavouriteEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JmFavouriteEvent value)  $default,){
final _that = this;
switch (_that) {
case _JmFavouriteEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JmFavouriteEvent value)?  $default,){
final _that = this;
switch (_that) {
case _JmFavouriteEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchEnter searchEnterConst)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JmFavouriteEvent() when $default != null:
return $default(_that.searchEnterConst);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchEnter searchEnterConst)  $default,) {final _that = this;
switch (_that) {
case _JmFavouriteEvent():
return $default(_that.searchEnterConst);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchEnter searchEnterConst)?  $default,) {final _that = this;
switch (_that) {
case _JmFavouriteEvent() when $default != null:
return $default(_that.searchEnterConst);case _:
  return null;

}
}

}

/// @nodoc


class _JmFavouriteEvent implements JmFavouriteEvent {
  const _JmFavouriteEvent({this.searchEnterConst = const SearchEnter()});
  

@override@JsonKey() final  SearchEnter searchEnterConst;

/// Create a copy of JmFavouriteEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JmFavouriteEventCopyWith<_JmFavouriteEvent> get copyWith => __$JmFavouriteEventCopyWithImpl<_JmFavouriteEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JmFavouriteEvent&&(identical(other.searchEnterConst, searchEnterConst) || other.searchEnterConst == searchEnterConst));
}


@override
int get hashCode => Object.hash(runtimeType,searchEnterConst);

@override
String toString() {
  return 'JmFavouriteEvent(searchEnterConst: $searchEnterConst)';
}


}

/// @nodoc
abstract mixin class _$JmFavouriteEventCopyWith<$Res> implements $JmFavouriteEventCopyWith<$Res> {
  factory _$JmFavouriteEventCopyWith(_JmFavouriteEvent value, $Res Function(_JmFavouriteEvent) _then) = __$JmFavouriteEventCopyWithImpl;
@override @useResult
$Res call({
 SearchEnter searchEnterConst
});




}
/// @nodoc
class __$JmFavouriteEventCopyWithImpl<$Res>
    implements _$JmFavouriteEventCopyWith<$Res> {
  __$JmFavouriteEventCopyWithImpl(this._self, this._then);

  final _JmFavouriteEvent _self;
  final $Res Function(_JmFavouriteEvent) _then;

/// Create a copy of JmFavouriteEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? searchEnterConst = null,}) {
  return _then(_JmFavouriteEvent(
searchEnterConst: null == searchEnterConst ? _self.searchEnterConst : searchEnterConst // ignore: cast_nullable_to_non_nullable
as SearchEnter,
  ));
}


}

/// @nodoc
mixin _$JmFavouriteState {

 JmFavouriteStatus get status; List<JmFavorite> get comics; String get result; SearchEnter get searchEnterConst;
/// Create a copy of JmFavouriteState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JmFavouriteStateCopyWith<JmFavouriteState> get copyWith => _$JmFavouriteStateCopyWithImpl<JmFavouriteState>(this as JmFavouriteState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JmFavouriteState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.comics, comics)&&(identical(other.result, result) || other.result == result)&&(identical(other.searchEnterConst, searchEnterConst) || other.searchEnterConst == searchEnterConst));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(comics),result,searchEnterConst);

@override
String toString() {
  return 'JmFavouriteState(status: $status, comics: $comics, result: $result, searchEnterConst: $searchEnterConst)';
}


}

/// @nodoc
abstract mixin class $JmFavouriteStateCopyWith<$Res>  {
  factory $JmFavouriteStateCopyWith(JmFavouriteState value, $Res Function(JmFavouriteState) _then) = _$JmFavouriteStateCopyWithImpl;
@useResult
$Res call({
 JmFavouriteStatus status, List<JmFavorite> comics, String result, SearchEnter searchEnterConst
});




}
/// @nodoc
class _$JmFavouriteStateCopyWithImpl<$Res>
    implements $JmFavouriteStateCopyWith<$Res> {
  _$JmFavouriteStateCopyWithImpl(this._self, this._then);

  final JmFavouriteState _self;
  final $Res Function(JmFavouriteState) _then;

/// Create a copy of JmFavouriteState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? comics = null,Object? result = null,Object? searchEnterConst = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JmFavouriteStatus,comics: null == comics ? _self.comics : comics // ignore: cast_nullable_to_non_nullable
as List<JmFavorite>,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,searchEnterConst: null == searchEnterConst ? _self.searchEnterConst : searchEnterConst // ignore: cast_nullable_to_non_nullable
as SearchEnter,
  ));
}

}


/// Adds pattern-matching-related methods to [JmFavouriteState].
extension JmFavouriteStatePatterns on JmFavouriteState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JmFavouriteState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JmFavouriteState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JmFavouriteState value)  $default,){
final _that = this;
switch (_that) {
case _JmFavouriteState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JmFavouriteState value)?  $default,){
final _that = this;
switch (_that) {
case _JmFavouriteState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( JmFavouriteStatus status,  List<JmFavorite> comics,  String result,  SearchEnter searchEnterConst)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JmFavouriteState() when $default != null:
return $default(_that.status,_that.comics,_that.result,_that.searchEnterConst);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( JmFavouriteStatus status,  List<JmFavorite> comics,  String result,  SearchEnter searchEnterConst)  $default,) {final _that = this;
switch (_that) {
case _JmFavouriteState():
return $default(_that.status,_that.comics,_that.result,_that.searchEnterConst);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( JmFavouriteStatus status,  List<JmFavorite> comics,  String result,  SearchEnter searchEnterConst)?  $default,) {final _that = this;
switch (_that) {
case _JmFavouriteState() when $default != null:
return $default(_that.status,_that.comics,_that.result,_that.searchEnterConst);case _:
  return null;

}
}

}

/// @nodoc


class _JmFavouriteState implements JmFavouriteState {
  const _JmFavouriteState({this.status = JmFavouriteStatus.initial, final  List<JmFavorite> comics = const [], this.result = '', this.searchEnterConst = const SearchEnter()}): _comics = comics;
  

@override@JsonKey() final  JmFavouriteStatus status;
 final  List<JmFavorite> _comics;
@override@JsonKey() List<JmFavorite> get comics {
  if (_comics is EqualUnmodifiableListView) return _comics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_comics);
}

@override@JsonKey() final  String result;
@override@JsonKey() final  SearchEnter searchEnterConst;

/// Create a copy of JmFavouriteState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JmFavouriteStateCopyWith<_JmFavouriteState> get copyWith => __$JmFavouriteStateCopyWithImpl<_JmFavouriteState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JmFavouriteState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._comics, _comics)&&(identical(other.result, result) || other.result == result)&&(identical(other.searchEnterConst, searchEnterConst) || other.searchEnterConst == searchEnterConst));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_comics),result,searchEnterConst);

@override
String toString() {
  return 'JmFavouriteState(status: $status, comics: $comics, result: $result, searchEnterConst: $searchEnterConst)';
}


}

/// @nodoc
abstract mixin class _$JmFavouriteStateCopyWith<$Res> implements $JmFavouriteStateCopyWith<$Res> {
  factory _$JmFavouriteStateCopyWith(_JmFavouriteState value, $Res Function(_JmFavouriteState) _then) = __$JmFavouriteStateCopyWithImpl;
@override @useResult
$Res call({
 JmFavouriteStatus status, List<JmFavorite> comics, String result, SearchEnter searchEnterConst
});




}
/// @nodoc
class __$JmFavouriteStateCopyWithImpl<$Res>
    implements _$JmFavouriteStateCopyWith<$Res> {
  __$JmFavouriteStateCopyWithImpl(this._self, this._then);

  final _JmFavouriteState _self;
  final $Res Function(_JmFavouriteState) _then;

/// Create a copy of JmFavouriteState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? comics = null,Object? result = null,Object? searchEnterConst = null,}) {
  return _then(_JmFavouriteState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JmFavouriteStatus,comics: null == comics ? _self._comics : comics // ignore: cast_nullable_to_non_nullable
as List<JmFavorite>,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,searchEnterConst: null == searchEnterConst ? _self.searchEnterConst : searchEnterConst // ignore: cast_nullable_to_non_nullable
as SearchEnter,
  ));
}


}

// dart format on
