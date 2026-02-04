// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SearchEvent {

 SearchStatus get status; SearchStates get searchStates; int get page; String get url;
/// Create a copy of SearchEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchEventCopyWith<SearchEvent> get copyWith => _$SearchEventCopyWithImpl<SearchEvent>(this as SearchEvent, _$identity);

  /// Serializes this SearchEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchEvent&&(identical(other.status, status) || other.status == status)&&(identical(other.searchStates, searchStates) || other.searchStates == searchStates)&&(identical(other.page, page) || other.page == page)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,searchStates,page,url);

@override
String toString() {
  return 'SearchEvent(status: $status, searchStates: $searchStates, page: $page, url: $url)';
}


}

/// @nodoc
abstract mixin class $SearchEventCopyWith<$Res>  {
  factory $SearchEventCopyWith(SearchEvent value, $Res Function(SearchEvent) _then) = _$SearchEventCopyWithImpl;
@useResult
$Res call({
 SearchStatus status, SearchStates searchStates, int page, String url
});


$SearchStatesCopyWith<$Res> get searchStates;

}
/// @nodoc
class _$SearchEventCopyWithImpl<$Res>
    implements $SearchEventCopyWith<$Res> {
  _$SearchEventCopyWithImpl(this._self, this._then);

  final SearchEvent _self;
  final $Res Function(SearchEvent) _then;

/// Create a copy of SearchEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? searchStates = null,Object? page = null,Object? url = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SearchStatus,searchStates: null == searchStates ? _self.searchStates : searchStates // ignore: cast_nullable_to_non_nullable
as SearchStates,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of SearchEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchStatesCopyWith<$Res> get searchStates {
  
  return $SearchStatesCopyWith<$Res>(_self.searchStates, (value) {
    return _then(_self.copyWith(searchStates: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchEvent].
extension SearchEventPatterns on SearchEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchEvent value)  $default,){
final _that = this;
switch (_that) {
case _SearchEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchEvent value)?  $default,){
final _that = this;
switch (_that) {
case _SearchEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchStatus status,  SearchStates searchStates,  int page,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchEvent() when $default != null:
return $default(_that.status,_that.searchStates,_that.page,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchStatus status,  SearchStates searchStates,  int page,  String url)  $default,) {final _that = this;
switch (_that) {
case _SearchEvent():
return $default(_that.status,_that.searchStates,_that.page,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchStatus status,  SearchStates searchStates,  int page,  String url)?  $default,) {final _that = this;
switch (_that) {
case _SearchEvent() when $default != null:
return $default(_that.status,_that.searchStates,_that.page,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchEvent implements SearchEvent {
  const _SearchEvent({this.status = SearchStatus.initial, this.searchStates = const SearchStates(), this.page = 1, this.url = ''});
  factory _SearchEvent.fromJson(Map<String, dynamic> json) => _$SearchEventFromJson(json);

@override@JsonKey() final  SearchStatus status;
@override@JsonKey() final  SearchStates searchStates;
@override@JsonKey() final  int page;
@override@JsonKey() final  String url;

/// Create a copy of SearchEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchEventCopyWith<_SearchEvent> get copyWith => __$SearchEventCopyWithImpl<_SearchEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchEvent&&(identical(other.status, status) || other.status == status)&&(identical(other.searchStates, searchStates) || other.searchStates == searchStates)&&(identical(other.page, page) || other.page == page)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,searchStates,page,url);

@override
String toString() {
  return 'SearchEvent(status: $status, searchStates: $searchStates, page: $page, url: $url)';
}


}

/// @nodoc
abstract mixin class _$SearchEventCopyWith<$Res> implements $SearchEventCopyWith<$Res> {
  factory _$SearchEventCopyWith(_SearchEvent value, $Res Function(_SearchEvent) _then) = __$SearchEventCopyWithImpl;
@override @useResult
$Res call({
 SearchStatus status, SearchStates searchStates, int page, String url
});


@override $SearchStatesCopyWith<$Res> get searchStates;

}
/// @nodoc
class __$SearchEventCopyWithImpl<$Res>
    implements _$SearchEventCopyWith<$Res> {
  __$SearchEventCopyWithImpl(this._self, this._then);

  final _SearchEvent _self;
  final $Res Function(_SearchEvent) _then;

/// Create a copy of SearchEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? searchStates = null,Object? page = null,Object? url = null,}) {
  return _then(_SearchEvent(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SearchStatus,searchStates: null == searchStates ? _self.searchStates : searchStates // ignore: cast_nullable_to_non_nullable
as SearchStates,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of SearchEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchStatesCopyWith<$Res> get searchStates {
  
  return $SearchStatesCopyWith<$Res>(_self.searchStates, (value) {
    return _then(_self.copyWith(searchStates: value));
  });
}
}


/// @nodoc
mixin _$SearchState {

 SearchStatus get status; List<ComicNumber> get comics; bool get hasReachedMax; String get result; SearchEvent get searchEvent;
/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchStateCopyWith<SearchState> get copyWith => _$SearchStateCopyWithImpl<SearchState>(this as SearchState, _$identity);

  /// Serializes this SearchState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.comics, comics)&&(identical(other.hasReachedMax, hasReachedMax) || other.hasReachedMax == hasReachedMax)&&(identical(other.result, result) || other.result == result)&&(identical(other.searchEvent, searchEvent) || other.searchEvent == searchEvent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(comics),hasReachedMax,result,searchEvent);

@override
String toString() {
  return 'SearchState(status: $status, comics: $comics, hasReachedMax: $hasReachedMax, result: $result, searchEvent: $searchEvent)';
}


}

/// @nodoc
abstract mixin class $SearchStateCopyWith<$Res>  {
  factory $SearchStateCopyWith(SearchState value, $Res Function(SearchState) _then) = _$SearchStateCopyWithImpl;
@useResult
$Res call({
 SearchStatus status, List<ComicNumber> comics, bool hasReachedMax, String result, SearchEvent searchEvent
});


$SearchEventCopyWith<$Res> get searchEvent;

}
/// @nodoc
class _$SearchStateCopyWithImpl<$Res>
    implements $SearchStateCopyWith<$Res> {
  _$SearchStateCopyWithImpl(this._self, this._then);

  final SearchState _self;
  final $Res Function(SearchState) _then;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? comics = null,Object? hasReachedMax = null,Object? result = null,Object? searchEvent = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SearchStatus,comics: null == comics ? _self.comics : comics // ignore: cast_nullable_to_non_nullable
as List<ComicNumber>,hasReachedMax: null == hasReachedMax ? _self.hasReachedMax : hasReachedMax // ignore: cast_nullable_to_non_nullable
as bool,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,searchEvent: null == searchEvent ? _self.searchEvent : searchEvent // ignore: cast_nullable_to_non_nullable
as SearchEvent,
  ));
}
/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchEventCopyWith<$Res> get searchEvent {
  
  return $SearchEventCopyWith<$Res>(_self.searchEvent, (value) {
    return _then(_self.copyWith(searchEvent: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchState].
extension SearchStatePatterns on SearchState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchState value)  $default,){
final _that = this;
switch (_that) {
case _SearchState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchState value)?  $default,){
final _that = this;
switch (_that) {
case _SearchState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchStatus status,  List<ComicNumber> comics,  bool hasReachedMax,  String result,  SearchEvent searchEvent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchState() when $default != null:
return $default(_that.status,_that.comics,_that.hasReachedMax,_that.result,_that.searchEvent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchStatus status,  List<ComicNumber> comics,  bool hasReachedMax,  String result,  SearchEvent searchEvent)  $default,) {final _that = this;
switch (_that) {
case _SearchState():
return $default(_that.status,_that.comics,_that.hasReachedMax,_that.result,_that.searchEvent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchStatus status,  List<ComicNumber> comics,  bool hasReachedMax,  String result,  SearchEvent searchEvent)?  $default,) {final _that = this;
switch (_that) {
case _SearchState() when $default != null:
return $default(_that.status,_that.comics,_that.hasReachedMax,_that.result,_that.searchEvent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchState implements SearchState {
  const _SearchState({this.status = SearchStatus.initial, final  List<ComicNumber> comics = const [], this.hasReachedMax = false, this.result = '', this.searchEvent = const SearchEvent()}): _comics = comics;
  factory _SearchState.fromJson(Map<String, dynamic> json) => _$SearchStateFromJson(json);

@override@JsonKey() final  SearchStatus status;
 final  List<ComicNumber> _comics;
@override@JsonKey() List<ComicNumber> get comics {
  if (_comics is EqualUnmodifiableListView) return _comics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_comics);
}

@override@JsonKey() final  bool hasReachedMax;
@override@JsonKey() final  String result;
@override@JsonKey() final  SearchEvent searchEvent;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchStateCopyWith<_SearchState> get copyWith => __$SearchStateCopyWithImpl<_SearchState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._comics, _comics)&&(identical(other.hasReachedMax, hasReachedMax) || other.hasReachedMax == hasReachedMax)&&(identical(other.result, result) || other.result == result)&&(identical(other.searchEvent, searchEvent) || other.searchEvent == searchEvent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_comics),hasReachedMax,result,searchEvent);

@override
String toString() {
  return 'SearchState(status: $status, comics: $comics, hasReachedMax: $hasReachedMax, result: $result, searchEvent: $searchEvent)';
}


}

/// @nodoc
abstract mixin class _$SearchStateCopyWith<$Res> implements $SearchStateCopyWith<$Res> {
  factory _$SearchStateCopyWith(_SearchState value, $Res Function(_SearchState) _then) = __$SearchStateCopyWithImpl;
@override @useResult
$Res call({
 SearchStatus status, List<ComicNumber> comics, bool hasReachedMax, String result, SearchEvent searchEvent
});


@override $SearchEventCopyWith<$Res> get searchEvent;

}
/// @nodoc
class __$SearchStateCopyWithImpl<$Res>
    implements _$SearchStateCopyWith<$Res> {
  __$SearchStateCopyWithImpl(this._self, this._then);

  final _SearchState _self;
  final $Res Function(_SearchState) _then;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? comics = null,Object? hasReachedMax = null,Object? result = null,Object? searchEvent = null,}) {
  return _then(_SearchState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SearchStatus,comics: null == comics ? _self._comics : comics // ignore: cast_nullable_to_non_nullable
as List<ComicNumber>,hasReachedMax: null == hasReachedMax ? _self.hasReachedMax : hasReachedMax // ignore: cast_nullable_to_non_nullable
as bool,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,searchEvent: null == searchEvent ? _self.searchEvent : searchEvent // ignore: cast_nullable_to_non_nullable
as SearchEvent,
  ));
}

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchEventCopyWith<$Res> get searchEvent {
  
  return $SearchEventCopyWith<$Res>(_self.searchEvent, (value) {
    return _then(_self.copyWith(searchEvent: value));
  });
}
}

// dart format on
