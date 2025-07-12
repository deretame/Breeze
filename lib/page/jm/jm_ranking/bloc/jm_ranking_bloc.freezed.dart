// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jm_ranking_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$JmRankingEvent {

 JmRankingStatus get status; int get page; String get type; String get order;
/// Create a copy of JmRankingEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JmRankingEventCopyWith<JmRankingEvent> get copyWith => _$JmRankingEventCopyWithImpl<JmRankingEvent>(this as JmRankingEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JmRankingEvent&&(identical(other.status, status) || other.status == status)&&(identical(other.page, page) || other.page == page)&&(identical(other.type, type) || other.type == type)&&(identical(other.order, order) || other.order == order));
}


@override
int get hashCode => Object.hash(runtimeType,status,page,type,order);

@override
String toString() {
  return 'JmRankingEvent(status: $status, page: $page, type: $type, order: $order)';
}


}

/// @nodoc
abstract mixin class $JmRankingEventCopyWith<$Res>  {
  factory $JmRankingEventCopyWith(JmRankingEvent value, $Res Function(JmRankingEvent) _then) = _$JmRankingEventCopyWithImpl;
@useResult
$Res call({
 JmRankingStatus status, int page, String type, String order
});




}
/// @nodoc
class _$JmRankingEventCopyWithImpl<$Res>
    implements $JmRankingEventCopyWith<$Res> {
  _$JmRankingEventCopyWithImpl(this._self, this._then);

  final JmRankingEvent _self;
  final $Res Function(JmRankingEvent) _then;

/// Create a copy of JmRankingEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? page = null,Object? type = null,Object? order = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JmRankingStatus,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [JmRankingEvent].
extension JmRankingEventPatterns on JmRankingEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JmRankingEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JmRankingEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JmRankingEvent value)  $default,){
final _that = this;
switch (_that) {
case _JmRankingEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JmRankingEvent value)?  $default,){
final _that = this;
switch (_that) {
case _JmRankingEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( JmRankingStatus status,  int page,  String type,  String order)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JmRankingEvent() when $default != null:
return $default(_that.status,_that.page,_that.type,_that.order);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( JmRankingStatus status,  int page,  String type,  String order)  $default,) {final _that = this;
switch (_that) {
case _JmRankingEvent():
return $default(_that.status,_that.page,_that.type,_that.order);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( JmRankingStatus status,  int page,  String type,  String order)?  $default,) {final _that = this;
switch (_that) {
case _JmRankingEvent() when $default != null:
return $default(_that.status,_that.page,_that.type,_that.order);case _:
  return null;

}
}

}

/// @nodoc


class _JmRankingEvent implements JmRankingEvent {
  const _JmRankingEvent({this.status = JmRankingStatus.initial, this.page = 1, this.type = "0", this.order = ""});
  

@override@JsonKey() final  JmRankingStatus status;
@override@JsonKey() final  int page;
@override@JsonKey() final  String type;
@override@JsonKey() final  String order;

/// Create a copy of JmRankingEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JmRankingEventCopyWith<_JmRankingEvent> get copyWith => __$JmRankingEventCopyWithImpl<_JmRankingEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JmRankingEvent&&(identical(other.status, status) || other.status == status)&&(identical(other.page, page) || other.page == page)&&(identical(other.type, type) || other.type == type)&&(identical(other.order, order) || other.order == order));
}


@override
int get hashCode => Object.hash(runtimeType,status,page,type,order);

@override
String toString() {
  return 'JmRankingEvent(status: $status, page: $page, type: $type, order: $order)';
}


}

/// @nodoc
abstract mixin class _$JmRankingEventCopyWith<$Res> implements $JmRankingEventCopyWith<$Res> {
  factory _$JmRankingEventCopyWith(_JmRankingEvent value, $Res Function(_JmRankingEvent) _then) = __$JmRankingEventCopyWithImpl;
@override @useResult
$Res call({
 JmRankingStatus status, int page, String type, String order
});




}
/// @nodoc
class __$JmRankingEventCopyWithImpl<$Res>
    implements _$JmRankingEventCopyWith<$Res> {
  __$JmRankingEventCopyWithImpl(this._self, this._then);

  final _JmRankingEvent _self;
  final $Res Function(_JmRankingEvent) _then;

/// Create a copy of JmRankingEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? page = null,Object? type = null,Object? order = null,}) {
  return _then(_JmRankingEvent(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JmRankingStatus,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$JmRankingState {

 JmRankingStatus get status; List<Content> get list; bool get hasReachedMax; String get result;
/// Create a copy of JmRankingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JmRankingStateCopyWith<JmRankingState> get copyWith => _$JmRankingStateCopyWithImpl<JmRankingState>(this as JmRankingState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JmRankingState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.list, list)&&(identical(other.hasReachedMax, hasReachedMax) || other.hasReachedMax == hasReachedMax)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(list),hasReachedMax,result);

@override
String toString() {
  return 'JmRankingState(status: $status, list: $list, hasReachedMax: $hasReachedMax, result: $result)';
}


}

/// @nodoc
abstract mixin class $JmRankingStateCopyWith<$Res>  {
  factory $JmRankingStateCopyWith(JmRankingState value, $Res Function(JmRankingState) _then) = _$JmRankingStateCopyWithImpl;
@useResult
$Res call({
 JmRankingStatus status, List<Content> list, bool hasReachedMax, String result
});




}
/// @nodoc
class _$JmRankingStateCopyWithImpl<$Res>
    implements $JmRankingStateCopyWith<$Res> {
  _$JmRankingStateCopyWithImpl(this._self, this._then);

  final JmRankingState _self;
  final $Res Function(JmRankingState) _then;

/// Create a copy of JmRankingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? list = null,Object? hasReachedMax = null,Object? result = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JmRankingStatus,list: null == list ? _self.list : list // ignore: cast_nullable_to_non_nullable
as List<Content>,hasReachedMax: null == hasReachedMax ? _self.hasReachedMax : hasReachedMax // ignore: cast_nullable_to_non_nullable
as bool,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [JmRankingState].
extension JmRankingStatePatterns on JmRankingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JmRankingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JmRankingState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JmRankingState value)  $default,){
final _that = this;
switch (_that) {
case _JmRankingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JmRankingState value)?  $default,){
final _that = this;
switch (_that) {
case _JmRankingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( JmRankingStatus status,  List<Content> list,  bool hasReachedMax,  String result)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JmRankingState() when $default != null:
return $default(_that.status,_that.list,_that.hasReachedMax,_that.result);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( JmRankingStatus status,  List<Content> list,  bool hasReachedMax,  String result)  $default,) {final _that = this;
switch (_that) {
case _JmRankingState():
return $default(_that.status,_that.list,_that.hasReachedMax,_that.result);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( JmRankingStatus status,  List<Content> list,  bool hasReachedMax,  String result)?  $default,) {final _that = this;
switch (_that) {
case _JmRankingState() when $default != null:
return $default(_that.status,_that.list,_that.hasReachedMax,_that.result);case _:
  return null;

}
}

}

/// @nodoc


class _JmRankingState implements JmRankingState {
  const _JmRankingState({this.status = JmRankingStatus.initial, final  List<Content> list = const [], this.hasReachedMax = false, this.result = ''}): _list = list;
  

@override@JsonKey() final  JmRankingStatus status;
 final  List<Content> _list;
@override@JsonKey() List<Content> get list {
  if (_list is EqualUnmodifiableListView) return _list;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_list);
}

@override@JsonKey() final  bool hasReachedMax;
@override@JsonKey() final  String result;

/// Create a copy of JmRankingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JmRankingStateCopyWith<_JmRankingState> get copyWith => __$JmRankingStateCopyWithImpl<_JmRankingState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JmRankingState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._list, _list)&&(identical(other.hasReachedMax, hasReachedMax) || other.hasReachedMax == hasReachedMax)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_list),hasReachedMax,result);

@override
String toString() {
  return 'JmRankingState(status: $status, list: $list, hasReachedMax: $hasReachedMax, result: $result)';
}


}

/// @nodoc
abstract mixin class _$JmRankingStateCopyWith<$Res> implements $JmRankingStateCopyWith<$Res> {
  factory _$JmRankingStateCopyWith(_JmRankingState value, $Res Function(_JmRankingState) _then) = __$JmRankingStateCopyWithImpl;
@override @useResult
$Res call({
 JmRankingStatus status, List<Content> list, bool hasReachedMax, String result
});




}
/// @nodoc
class __$JmRankingStateCopyWithImpl<$Res>
    implements _$JmRankingStateCopyWith<$Res> {
  __$JmRankingStateCopyWithImpl(this._self, this._then);

  final _JmRankingState _self;
  final $Res Function(_JmRankingState) _then;

/// Create a copy of JmRankingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? list = null,Object? hasReachedMax = null,Object? result = null,}) {
  return _then(_JmRankingState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JmRankingStatus,list: null == list ? _self._list : list // ignore: cast_nullable_to_non_nullable
as List<Content>,hasReachedMax: null == hasReachedMax ? _self.hasReachedMax : hasReachedMax // ignore: cast_nullable_to_non_nullable
as bool,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
