// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'local_favorite_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LocalFavoriteEvent {

 SearchEnter get searchEnterConst;
/// Create a copy of LocalFavoriteEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalFavoriteEventCopyWith<LocalFavoriteEvent> get copyWith => _$LocalFavoriteEventCopyWithImpl<LocalFavoriteEvent>(this as LocalFavoriteEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalFavoriteEvent&&(identical(other.searchEnterConst, searchEnterConst) || other.searchEnterConst == searchEnterConst));
}


@override
int get hashCode => Object.hash(runtimeType,searchEnterConst);

@override
String toString() {
  return 'LocalFavoriteEvent(searchEnterConst: $searchEnterConst)';
}


}

/// @nodoc
abstract mixin class $LocalFavoriteEventCopyWith<$Res>  {
  factory $LocalFavoriteEventCopyWith(LocalFavoriteEvent value, $Res Function(LocalFavoriteEvent) _then) = _$LocalFavoriteEventCopyWithImpl;
@useResult
$Res call({
 SearchEnter searchEnterConst
});




}
/// @nodoc
class _$LocalFavoriteEventCopyWithImpl<$Res>
    implements $LocalFavoriteEventCopyWith<$Res> {
  _$LocalFavoriteEventCopyWithImpl(this._self, this._then);

  final LocalFavoriteEvent _self;
  final $Res Function(LocalFavoriteEvent) _then;

/// Create a copy of LocalFavoriteEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? searchEnterConst = null,}) {
  return _then(_self.copyWith(
searchEnterConst: null == searchEnterConst ? _self.searchEnterConst : searchEnterConst // ignore: cast_nullable_to_non_nullable
as SearchEnter,
  ));
}

}


/// Adds pattern-matching-related methods to [LocalFavoriteEvent].
extension LocalFavoriteEventPatterns on LocalFavoriteEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalFavoriteEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalFavoriteEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalFavoriteEvent value)  $default,){
final _that = this;
switch (_that) {
case _LocalFavoriteEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalFavoriteEvent value)?  $default,){
final _that = this;
switch (_that) {
case _LocalFavoriteEvent() when $default != null:
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
case _LocalFavoriteEvent() when $default != null:
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
case _LocalFavoriteEvent():
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
case _LocalFavoriteEvent() when $default != null:
return $default(_that.searchEnterConst);case _:
  return null;

}
}

}

/// @nodoc


class _LocalFavoriteEvent implements LocalFavoriteEvent {
  const _LocalFavoriteEvent({this.searchEnterConst = const SearchEnter()});
  

@override@JsonKey() final  SearchEnter searchEnterConst;

/// Create a copy of LocalFavoriteEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalFavoriteEventCopyWith<_LocalFavoriteEvent> get copyWith => __$LocalFavoriteEventCopyWithImpl<_LocalFavoriteEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalFavoriteEvent&&(identical(other.searchEnterConst, searchEnterConst) || other.searchEnterConst == searchEnterConst));
}


@override
int get hashCode => Object.hash(runtimeType,searchEnterConst);

@override
String toString() {
  return 'LocalFavoriteEvent(searchEnterConst: $searchEnterConst)';
}


}

/// @nodoc
abstract mixin class _$LocalFavoriteEventCopyWith<$Res> implements $LocalFavoriteEventCopyWith<$Res> {
  factory _$LocalFavoriteEventCopyWith(_LocalFavoriteEvent value, $Res Function(_LocalFavoriteEvent) _then) = __$LocalFavoriteEventCopyWithImpl;
@override @useResult
$Res call({
 SearchEnter searchEnterConst
});




}
/// @nodoc
class __$LocalFavoriteEventCopyWithImpl<$Res>
    implements _$LocalFavoriteEventCopyWith<$Res> {
  __$LocalFavoriteEventCopyWithImpl(this._self, this._then);

  final _LocalFavoriteEvent _self;
  final $Res Function(_LocalFavoriteEvent) _then;

/// Create a copy of LocalFavoriteEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? searchEnterConst = null,}) {
  return _then(_LocalFavoriteEvent(
searchEnterConst: null == searchEnterConst ? _self.searchEnterConst : searchEnterConst // ignore: cast_nullable_to_non_nullable
as SearchEnter,
  ));
}


}

/// @nodoc
mixin _$LocalFavoriteState {

 LocalFavoriteStatus get status; List<UnifiedComicFavorite> get comics; String get result; SearchEnter get searchEnterConst;
/// Create a copy of LocalFavoriteState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalFavoriteStateCopyWith<LocalFavoriteState> get copyWith => _$LocalFavoriteStateCopyWithImpl<LocalFavoriteState>(this as LocalFavoriteState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalFavoriteState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.comics, comics)&&(identical(other.result, result) || other.result == result)&&(identical(other.searchEnterConst, searchEnterConst) || other.searchEnterConst == searchEnterConst));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(comics),result,searchEnterConst);

@override
String toString() {
  return 'LocalFavoriteState(status: $status, comics: $comics, result: $result, searchEnterConst: $searchEnterConst)';
}


}

/// @nodoc
abstract mixin class $LocalFavoriteStateCopyWith<$Res>  {
  factory $LocalFavoriteStateCopyWith(LocalFavoriteState value, $Res Function(LocalFavoriteState) _then) = _$LocalFavoriteStateCopyWithImpl;
@useResult
$Res call({
 LocalFavoriteStatus status, List<UnifiedComicFavorite> comics, String result, SearchEnter searchEnterConst
});




}
/// @nodoc
class _$LocalFavoriteStateCopyWithImpl<$Res>
    implements $LocalFavoriteStateCopyWith<$Res> {
  _$LocalFavoriteStateCopyWithImpl(this._self, this._then);

  final LocalFavoriteState _self;
  final $Res Function(LocalFavoriteState) _then;

/// Create a copy of LocalFavoriteState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? comics = null,Object? result = null,Object? searchEnterConst = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LocalFavoriteStatus,comics: null == comics ? _self.comics : comics // ignore: cast_nullable_to_non_nullable
as List<UnifiedComicFavorite>,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,searchEnterConst: null == searchEnterConst ? _self.searchEnterConst : searchEnterConst // ignore: cast_nullable_to_non_nullable
as SearchEnter,
  ));
}

}


/// Adds pattern-matching-related methods to [LocalFavoriteState].
extension LocalFavoriteStatePatterns on LocalFavoriteState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalFavoriteState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalFavoriteState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalFavoriteState value)  $default,){
final _that = this;
switch (_that) {
case _LocalFavoriteState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalFavoriteState value)?  $default,){
final _that = this;
switch (_that) {
case _LocalFavoriteState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LocalFavoriteStatus status,  List<UnifiedComicFavorite> comics,  String result,  SearchEnter searchEnterConst)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalFavoriteState() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LocalFavoriteStatus status,  List<UnifiedComicFavorite> comics,  String result,  SearchEnter searchEnterConst)  $default,) {final _that = this;
switch (_that) {
case _LocalFavoriteState():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LocalFavoriteStatus status,  List<UnifiedComicFavorite> comics,  String result,  SearchEnter searchEnterConst)?  $default,) {final _that = this;
switch (_that) {
case _LocalFavoriteState() when $default != null:
return $default(_that.status,_that.comics,_that.result,_that.searchEnterConst);case _:
  return null;

}
}

}

/// @nodoc


class _LocalFavoriteState implements LocalFavoriteState {
  const _LocalFavoriteState({this.status = LocalFavoriteStatus.initial, final  List<UnifiedComicFavorite> comics = const [], this.result = '', this.searchEnterConst = const SearchEnter()}): _comics = comics;
  

@override@JsonKey() final  LocalFavoriteStatus status;
 final  List<UnifiedComicFavorite> _comics;
@override@JsonKey() List<UnifiedComicFavorite> get comics {
  if (_comics is EqualUnmodifiableListView) return _comics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_comics);
}

@override@JsonKey() final  String result;
@override@JsonKey() final  SearchEnter searchEnterConst;

/// Create a copy of LocalFavoriteState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalFavoriteStateCopyWith<_LocalFavoriteState> get copyWith => __$LocalFavoriteStateCopyWithImpl<_LocalFavoriteState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalFavoriteState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._comics, _comics)&&(identical(other.result, result) || other.result == result)&&(identical(other.searchEnterConst, searchEnterConst) || other.searchEnterConst == searchEnterConst));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_comics),result,searchEnterConst);

@override
String toString() {
  return 'LocalFavoriteState(status: $status, comics: $comics, result: $result, searchEnterConst: $searchEnterConst)';
}


}

/// @nodoc
abstract mixin class _$LocalFavoriteStateCopyWith<$Res> implements $LocalFavoriteStateCopyWith<$Res> {
  factory _$LocalFavoriteStateCopyWith(_LocalFavoriteState value, $Res Function(_LocalFavoriteState) _then) = __$LocalFavoriteStateCopyWithImpl;
@override @useResult
$Res call({
 LocalFavoriteStatus status, List<UnifiedComicFavorite> comics, String result, SearchEnter searchEnterConst
});




}
/// @nodoc
class __$LocalFavoriteStateCopyWithImpl<$Res>
    implements _$LocalFavoriteStateCopyWith<$Res> {
  __$LocalFavoriteStateCopyWithImpl(this._self, this._then);

  final _LocalFavoriteState _self;
  final $Res Function(_LocalFavoriteState) _then;

/// Create a copy of LocalFavoriteState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? comics = null,Object? result = null,Object? searchEnterConst = null,}) {
  return _then(_LocalFavoriteState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LocalFavoriteStatus,comics: null == comics ? _self._comics : comics // ignore: cast_nullable_to_non_nullable
as List<UnifiedComicFavorite>,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,searchEnterConst: null == searchEnterConst ? _self.searchEnterConst : searchEnterConst // ignore: cast_nullable_to_non_nullable
as SearchEnter,
  ));
}


}

// dart format on
