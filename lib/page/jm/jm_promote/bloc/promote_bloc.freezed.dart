// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'promote_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PromoteEvent {

 PromoteStatus get status; int get page;
/// Create a copy of PromoteEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PromoteEventCopyWith<PromoteEvent> get copyWith => _$PromoteEventCopyWithImpl<PromoteEvent>(this as PromoteEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PromoteEvent&&(identical(other.status, status) || other.status == status)&&(identical(other.page, page) || other.page == page));
}


@override
int get hashCode => Object.hash(runtimeType,status,page);

@override
String toString() {
  return 'PromoteEvent(status: $status, page: $page)';
}


}

/// @nodoc
abstract mixin class $PromoteEventCopyWith<$Res>  {
  factory $PromoteEventCopyWith(PromoteEvent value, $Res Function(PromoteEvent) _then) = _$PromoteEventCopyWithImpl;
@useResult
$Res call({
 PromoteStatus status, int page
});




}
/// @nodoc
class _$PromoteEventCopyWithImpl<$Res>
    implements $PromoteEventCopyWith<$Res> {
  _$PromoteEventCopyWithImpl(this._self, this._then);

  final PromoteEvent _self;
  final $Res Function(PromoteEvent) _then;

/// Create a copy of PromoteEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? page = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PromoteStatus,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PromoteEvent].
extension PromoteEventPatterns on PromoteEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PromoteEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PromoteEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PromoteEvent value)  $default,){
final _that = this;
switch (_that) {
case _PromoteEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PromoteEvent value)?  $default,){
final _that = this;
switch (_that) {
case _PromoteEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PromoteStatus status,  int page)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PromoteEvent() when $default != null:
return $default(_that.status,_that.page);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PromoteStatus status,  int page)  $default,) {final _that = this;
switch (_that) {
case _PromoteEvent():
return $default(_that.status,_that.page);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PromoteStatus status,  int page)?  $default,) {final _that = this;
switch (_that) {
case _PromoteEvent() when $default != null:
return $default(_that.status,_that.page);case _:
  return null;

}
}

}

/// @nodoc


class _PromoteEvent implements PromoteEvent {
  const _PromoteEvent({this.status = PromoteStatus.initial, this.page = -1});
  

@override@JsonKey() final  PromoteStatus status;
@override@JsonKey() final  int page;

/// Create a copy of PromoteEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PromoteEventCopyWith<_PromoteEvent> get copyWith => __$PromoteEventCopyWithImpl<_PromoteEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PromoteEvent&&(identical(other.status, status) || other.status == status)&&(identical(other.page, page) || other.page == page));
}


@override
int get hashCode => Object.hash(runtimeType,status,page);

@override
String toString() {
  return 'PromoteEvent(status: $status, page: $page)';
}


}

/// @nodoc
abstract mixin class _$PromoteEventCopyWith<$Res> implements $PromoteEventCopyWith<$Res> {
  factory _$PromoteEventCopyWith(_PromoteEvent value, $Res Function(_PromoteEvent) _then) = __$PromoteEventCopyWithImpl;
@override @useResult
$Res call({
 PromoteStatus status, int page
});




}
/// @nodoc
class __$PromoteEventCopyWithImpl<$Res>
    implements _$PromoteEventCopyWith<$Res> {
  __$PromoteEventCopyWithImpl(this._self, this._then);

  final _PromoteEvent _self;
  final $Res Function(_PromoteEvent) _then;

/// Create a copy of PromoteEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? page = null,}) {
  return _then(_PromoteEvent(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PromoteStatus,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$PromoteState {

 PromoteStatus get status; List<Map<String, dynamic>> get sections; List<Map<String, dynamic>> get suggestionItems; bool get hasReachedMax; String get result;
/// Create a copy of PromoteState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PromoteStateCopyWith<PromoteState> get copyWith => _$PromoteStateCopyWithImpl<PromoteState>(this as PromoteState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PromoteState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.sections, sections)&&const DeepCollectionEquality().equals(other.suggestionItems, suggestionItems)&&(identical(other.hasReachedMax, hasReachedMax) || other.hasReachedMax == hasReachedMax)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(sections),const DeepCollectionEquality().hash(suggestionItems),hasReachedMax,result);

@override
String toString() {
  return 'PromoteState(status: $status, sections: $sections, suggestionItems: $suggestionItems, hasReachedMax: $hasReachedMax, result: $result)';
}


}

/// @nodoc
abstract mixin class $PromoteStateCopyWith<$Res>  {
  factory $PromoteStateCopyWith(PromoteState value, $Res Function(PromoteState) _then) = _$PromoteStateCopyWithImpl;
@useResult
$Res call({
 PromoteStatus status, List<Map<String, dynamic>> sections, List<Map<String, dynamic>> suggestionItems, bool hasReachedMax, String result
});




}
/// @nodoc
class _$PromoteStateCopyWithImpl<$Res>
    implements $PromoteStateCopyWith<$Res> {
  _$PromoteStateCopyWithImpl(this._self, this._then);

  final PromoteState _self;
  final $Res Function(PromoteState) _then;

/// Create a copy of PromoteState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? sections = null,Object? suggestionItems = null,Object? hasReachedMax = null,Object? result = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PromoteStatus,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,suggestionItems: null == suggestionItems ? _self.suggestionItems : suggestionItems // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,hasReachedMax: null == hasReachedMax ? _self.hasReachedMax : hasReachedMax // ignore: cast_nullable_to_non_nullable
as bool,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PromoteState].
extension PromoteStatePatterns on PromoteState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PromoteState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PromoteState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PromoteState value)  $default,){
final _that = this;
switch (_that) {
case _PromoteState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PromoteState value)?  $default,){
final _that = this;
switch (_that) {
case _PromoteState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PromoteStatus status,  List<Map<String, dynamic>> sections,  List<Map<String, dynamic>> suggestionItems,  bool hasReachedMax,  String result)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PromoteState() when $default != null:
return $default(_that.status,_that.sections,_that.suggestionItems,_that.hasReachedMax,_that.result);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PromoteStatus status,  List<Map<String, dynamic>> sections,  List<Map<String, dynamic>> suggestionItems,  bool hasReachedMax,  String result)  $default,) {final _that = this;
switch (_that) {
case _PromoteState():
return $default(_that.status,_that.sections,_that.suggestionItems,_that.hasReachedMax,_that.result);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PromoteStatus status,  List<Map<String, dynamic>> sections,  List<Map<String, dynamic>> suggestionItems,  bool hasReachedMax,  String result)?  $default,) {final _that = this;
switch (_that) {
case _PromoteState() when $default != null:
return $default(_that.status,_that.sections,_that.suggestionItems,_that.hasReachedMax,_that.result);case _:
  return null;

}
}

}

/// @nodoc


class _PromoteState implements PromoteState {
  const _PromoteState({this.status = PromoteStatus.initial, final  List<Map<String, dynamic>> sections = const <Map<String, dynamic>>[], final  List<Map<String, dynamic>> suggestionItems = const <Map<String, dynamic>>[], this.hasReachedMax = false, this.result = ''}): _sections = sections,_suggestionItems = suggestionItems;
  

@override@JsonKey() final  PromoteStatus status;
 final  List<Map<String, dynamic>> _sections;
@override@JsonKey() List<Map<String, dynamic>> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}

 final  List<Map<String, dynamic>> _suggestionItems;
@override@JsonKey() List<Map<String, dynamic>> get suggestionItems {
  if (_suggestionItems is EqualUnmodifiableListView) return _suggestionItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_suggestionItems);
}

@override@JsonKey() final  bool hasReachedMax;
@override@JsonKey() final  String result;

/// Create a copy of PromoteState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PromoteStateCopyWith<_PromoteState> get copyWith => __$PromoteStateCopyWithImpl<_PromoteState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PromoteState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._sections, _sections)&&const DeepCollectionEquality().equals(other._suggestionItems, _suggestionItems)&&(identical(other.hasReachedMax, hasReachedMax) || other.hasReachedMax == hasReachedMax)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_sections),const DeepCollectionEquality().hash(_suggestionItems),hasReachedMax,result);

@override
String toString() {
  return 'PromoteState(status: $status, sections: $sections, suggestionItems: $suggestionItems, hasReachedMax: $hasReachedMax, result: $result)';
}


}

/// @nodoc
abstract mixin class _$PromoteStateCopyWith<$Res> implements $PromoteStateCopyWith<$Res> {
  factory _$PromoteStateCopyWith(_PromoteState value, $Res Function(_PromoteState) _then) = __$PromoteStateCopyWithImpl;
@override @useResult
$Res call({
 PromoteStatus status, List<Map<String, dynamic>> sections, List<Map<String, dynamic>> suggestionItems, bool hasReachedMax, String result
});




}
/// @nodoc
class __$PromoteStateCopyWithImpl<$Res>
    implements _$PromoteStateCopyWith<$Res> {
  __$PromoteStateCopyWithImpl(this._self, this._then);

  final _PromoteState _self;
  final $Res Function(_PromoteState) _then;

/// Create a copy of PromoteState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? sections = null,Object? suggestionItems = null,Object? hasReachedMax = null,Object? result = null,}) {
  return _then(_PromoteState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PromoteStatus,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,suggestionItems: null == suggestionItems ? _self._suggestionItems : suggestionItems // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,hasReachedMax: null == hasReachedMax ? _self.hasReachedMax : hasReachedMax // ignore: cast_nullable_to_non_nullable
as bool,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
