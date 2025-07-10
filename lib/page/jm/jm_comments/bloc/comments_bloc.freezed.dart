// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comments_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommentsEvent {

 CommentsStatus get status; String get comicId;
/// Create a copy of CommentsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentsEventCopyWith<CommentsEvent> get copyWith => _$CommentsEventCopyWithImpl<CommentsEvent>(this as CommentsEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentsEvent&&(identical(other.status, status) || other.status == status)&&(identical(other.comicId, comicId) || other.comicId == comicId));
}


@override
int get hashCode => Object.hash(runtimeType,status,comicId);

@override
String toString() {
  return 'CommentsEvent(status: $status, comicId: $comicId)';
}


}

/// @nodoc
abstract mixin class $CommentsEventCopyWith<$Res>  {
  factory $CommentsEventCopyWith(CommentsEvent value, $Res Function(CommentsEvent) _then) = _$CommentsEventCopyWithImpl;
@useResult
$Res call({
 CommentsStatus status, String comicId
});




}
/// @nodoc
class _$CommentsEventCopyWithImpl<$Res>
    implements $CommentsEventCopyWith<$Res> {
  _$CommentsEventCopyWithImpl(this._self, this._then);

  final CommentsEvent _self;
  final $Res Function(CommentsEvent) _then;

/// Create a copy of CommentsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? comicId = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CommentsStatus,comicId: null == comicId ? _self.comicId : comicId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentsEvent].
extension CommentsEventPatterns on CommentsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentsEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentsEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentsEvent value)  $default,){
final _that = this;
switch (_that) {
case _CommentsEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentsEvent value)?  $default,){
final _that = this;
switch (_that) {
case _CommentsEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CommentsStatus status,  String comicId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentsEvent() when $default != null:
return $default(_that.status,_that.comicId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CommentsStatus status,  String comicId)  $default,) {final _that = this;
switch (_that) {
case _CommentsEvent():
return $default(_that.status,_that.comicId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CommentsStatus status,  String comicId)?  $default,) {final _that = this;
switch (_that) {
case _CommentsEvent() when $default != null:
return $default(_that.status,_that.comicId);case _:
  return null;

}
}

}

/// @nodoc


class _CommentsEvent implements CommentsEvent {
  const _CommentsEvent({this.status = CommentsStatus.initial, required this.comicId});
  

@override@JsonKey() final  CommentsStatus status;
@override final  String comicId;

/// Create a copy of CommentsEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentsEventCopyWith<_CommentsEvent> get copyWith => __$CommentsEventCopyWithImpl<_CommentsEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentsEvent&&(identical(other.status, status) || other.status == status)&&(identical(other.comicId, comicId) || other.comicId == comicId));
}


@override
int get hashCode => Object.hash(runtimeType,status,comicId);

@override
String toString() {
  return 'CommentsEvent(status: $status, comicId: $comicId)';
}


}

/// @nodoc
abstract mixin class _$CommentsEventCopyWith<$Res> implements $CommentsEventCopyWith<$Res> {
  factory _$CommentsEventCopyWith(_CommentsEvent value, $Res Function(_CommentsEvent) _then) = __$CommentsEventCopyWithImpl;
@override @useResult
$Res call({
 CommentsStatus status, String comicId
});




}
/// @nodoc
class __$CommentsEventCopyWithImpl<$Res>
    implements _$CommentsEventCopyWith<$Res> {
  __$CommentsEventCopyWithImpl(this._self, this._then);

  final _CommentsEvent _self;
  final $Res Function(_CommentsEvent) _then;

/// Create a copy of CommentsEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? comicId = null,}) {
  return _then(_CommentsEvent(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CommentsStatus,comicId: null == comicId ? _self.comicId : comicId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$CommentsState {

 CommentsStatus get status; List<ListElement> get comments; bool get hasReachedMax; String get result;
/// Create a copy of CommentsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentsStateCopyWith<CommentsState> get copyWith => _$CommentsStateCopyWithImpl<CommentsState>(this as CommentsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentsState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.comments, comments)&&(identical(other.hasReachedMax, hasReachedMax) || other.hasReachedMax == hasReachedMax)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(comments),hasReachedMax,result);

@override
String toString() {
  return 'CommentsState(status: $status, comments: $comments, hasReachedMax: $hasReachedMax, result: $result)';
}


}

/// @nodoc
abstract mixin class $CommentsStateCopyWith<$Res>  {
  factory $CommentsStateCopyWith(CommentsState value, $Res Function(CommentsState) _then) = _$CommentsStateCopyWithImpl;
@useResult
$Res call({
 CommentsStatus status, List<ListElement> comments, bool hasReachedMax, String result
});




}
/// @nodoc
class _$CommentsStateCopyWithImpl<$Res>
    implements $CommentsStateCopyWith<$Res> {
  _$CommentsStateCopyWithImpl(this._self, this._then);

  final CommentsState _self;
  final $Res Function(CommentsState) _then;

/// Create a copy of CommentsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? comments = null,Object? hasReachedMax = null,Object? result = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CommentsStatus,comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as List<ListElement>,hasReachedMax: null == hasReachedMax ? _self.hasReachedMax : hasReachedMax // ignore: cast_nullable_to_non_nullable
as bool,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentsState].
extension CommentsStatePatterns on CommentsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentsState value)  $default,){
final _that = this;
switch (_that) {
case _CommentsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentsState value)?  $default,){
final _that = this;
switch (_that) {
case _CommentsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CommentsStatus status,  List<ListElement> comments,  bool hasReachedMax,  String result)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentsState() when $default != null:
return $default(_that.status,_that.comments,_that.hasReachedMax,_that.result);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CommentsStatus status,  List<ListElement> comments,  bool hasReachedMax,  String result)  $default,) {final _that = this;
switch (_that) {
case _CommentsState():
return $default(_that.status,_that.comments,_that.hasReachedMax,_that.result);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CommentsStatus status,  List<ListElement> comments,  bool hasReachedMax,  String result)?  $default,) {final _that = this;
switch (_that) {
case _CommentsState() when $default != null:
return $default(_that.status,_that.comments,_that.hasReachedMax,_that.result);case _:
  return null;

}
}

}

/// @nodoc


class _CommentsState implements CommentsState {
  const _CommentsState({this.status = CommentsStatus.initial, final  List<ListElement> comments = const [], this.hasReachedMax = false, this.result = ''}): _comments = comments;
  

@override@JsonKey() final  CommentsStatus status;
 final  List<ListElement> _comments;
@override@JsonKey() List<ListElement> get comments {
  if (_comments is EqualUnmodifiableListView) return _comments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_comments);
}

@override@JsonKey() final  bool hasReachedMax;
@override@JsonKey() final  String result;

/// Create a copy of CommentsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentsStateCopyWith<_CommentsState> get copyWith => __$CommentsStateCopyWithImpl<_CommentsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentsState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._comments, _comments)&&(identical(other.hasReachedMax, hasReachedMax) || other.hasReachedMax == hasReachedMax)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_comments),hasReachedMax,result);

@override
String toString() {
  return 'CommentsState(status: $status, comments: $comments, hasReachedMax: $hasReachedMax, result: $result)';
}


}

/// @nodoc
abstract mixin class _$CommentsStateCopyWith<$Res> implements $CommentsStateCopyWith<$Res> {
  factory _$CommentsStateCopyWith(_CommentsState value, $Res Function(_CommentsState) _then) = __$CommentsStateCopyWithImpl;
@override @useResult
$Res call({
 CommentsStatus status, List<ListElement> comments, bool hasReachedMax, String result
});




}
/// @nodoc
class __$CommentsStateCopyWithImpl<$Res>
    implements _$CommentsStateCopyWith<$Res> {
  __$CommentsStateCopyWithImpl(this._self, this._then);

  final _CommentsState _self;
  final $Res Function(_CommentsState) _then;

/// Create a copy of CommentsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? comments = null,Object? hasReachedMax = null,Object? result = null,}) {
  return _then(_CommentsState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CommentsStatus,comments: null == comments ? _self._comments : comments // ignore: cast_nullable_to_non_nullable
as List<ListElement>,hasReachedMax: null == hasReachedMax ? _self.hasReachedMax : hasReachedMax // ignore: cast_nullable_to_non_nullable
as bool,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
