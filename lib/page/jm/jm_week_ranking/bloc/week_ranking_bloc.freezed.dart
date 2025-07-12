// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'week_ranking_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WeekRankingEvent {

 JmRankingStatus get status; int get date; String get type; int get page;
/// Create a copy of WeekRankingEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeekRankingEventCopyWith<WeekRankingEvent> get copyWith => _$WeekRankingEventCopyWithImpl<WeekRankingEvent>(this as WeekRankingEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeekRankingEvent&&(identical(other.status, status) || other.status == status)&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type)&&(identical(other.page, page) || other.page == page));
}


@override
int get hashCode => Object.hash(runtimeType,status,date,type,page);

@override
String toString() {
  return 'WeekRankingEvent(status: $status, date: $date, type: $type, page: $page)';
}


}

/// @nodoc
abstract mixin class $WeekRankingEventCopyWith<$Res>  {
  factory $WeekRankingEventCopyWith(WeekRankingEvent value, $Res Function(WeekRankingEvent) _then) = _$WeekRankingEventCopyWithImpl;
@useResult
$Res call({
 JmRankingStatus status, int date, String type, int page
});




}
/// @nodoc
class _$WeekRankingEventCopyWithImpl<$Res>
    implements $WeekRankingEventCopyWith<$Res> {
  _$WeekRankingEventCopyWithImpl(this._self, this._then);

  final WeekRankingEvent _self;
  final $Res Function(WeekRankingEvent) _then;

/// Create a copy of WeekRankingEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? date = null,Object? type = null,Object? page = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JmRankingStatus,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WeekRankingEvent].
extension WeekRankingEventPatterns on WeekRankingEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeekRankingEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeekRankingEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeekRankingEvent value)  $default,){
final _that = this;
switch (_that) {
case _WeekRankingEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeekRankingEvent value)?  $default,){
final _that = this;
switch (_that) {
case _WeekRankingEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( JmRankingStatus status,  int date,  String type,  int page)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeekRankingEvent() when $default != null:
return $default(_that.status,_that.date,_that.type,_that.page);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( JmRankingStatus status,  int date,  String type,  int page)  $default,) {final _that = this;
switch (_that) {
case _WeekRankingEvent():
return $default(_that.status,_that.date,_that.type,_that.page);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( JmRankingStatus status,  int date,  String type,  int page)?  $default,) {final _that = this;
switch (_that) {
case _WeekRankingEvent() when $default != null:
return $default(_that.status,_that.date,_that.type,_that.page);case _:
  return null;

}
}

}

/// @nodoc


class _WeekRankingEvent implements WeekRankingEvent {
  const _WeekRankingEvent({this.status = JmRankingStatus.initial, this.date = 0, this.type = "all", this.page = 1});
  

@override@JsonKey() final  JmRankingStatus status;
@override@JsonKey() final  int date;
@override@JsonKey() final  String type;
@override@JsonKey() final  int page;

/// Create a copy of WeekRankingEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeekRankingEventCopyWith<_WeekRankingEvent> get copyWith => __$WeekRankingEventCopyWithImpl<_WeekRankingEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeekRankingEvent&&(identical(other.status, status) || other.status == status)&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type)&&(identical(other.page, page) || other.page == page));
}


@override
int get hashCode => Object.hash(runtimeType,status,date,type,page);

@override
String toString() {
  return 'WeekRankingEvent(status: $status, date: $date, type: $type, page: $page)';
}


}

/// @nodoc
abstract mixin class _$WeekRankingEventCopyWith<$Res> implements $WeekRankingEventCopyWith<$Res> {
  factory _$WeekRankingEventCopyWith(_WeekRankingEvent value, $Res Function(_WeekRankingEvent) _then) = __$WeekRankingEventCopyWithImpl;
@override @useResult
$Res call({
 JmRankingStatus status, int date, String type, int page
});




}
/// @nodoc
class __$WeekRankingEventCopyWithImpl<$Res>
    implements _$WeekRankingEventCopyWith<$Res> {
  __$WeekRankingEventCopyWithImpl(this._self, this._then);

  final _WeekRankingEvent _self;
  final $Res Function(_WeekRankingEvent) _then;

/// Create a copy of WeekRankingEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? date = null,Object? type = null,Object? page = null,}) {
  return _then(_WeekRankingEvent(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JmRankingStatus,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$WeekRankingState {

 JmRankingStatus get status; List<ListElement> get list; bool get hasReachedMax; String get result;
/// Create a copy of WeekRankingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeekRankingStateCopyWith<WeekRankingState> get copyWith => _$WeekRankingStateCopyWithImpl<WeekRankingState>(this as WeekRankingState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeekRankingState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.list, list)&&(identical(other.hasReachedMax, hasReachedMax) || other.hasReachedMax == hasReachedMax)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(list),hasReachedMax,result);

@override
String toString() {
  return 'WeekRankingState(status: $status, list: $list, hasReachedMax: $hasReachedMax, result: $result)';
}


}

/// @nodoc
abstract mixin class $WeekRankingStateCopyWith<$Res>  {
  factory $WeekRankingStateCopyWith(WeekRankingState value, $Res Function(WeekRankingState) _then) = _$WeekRankingStateCopyWithImpl;
@useResult
$Res call({
 JmRankingStatus status, List<ListElement> list, bool hasReachedMax, String result
});




}
/// @nodoc
class _$WeekRankingStateCopyWithImpl<$Res>
    implements $WeekRankingStateCopyWith<$Res> {
  _$WeekRankingStateCopyWithImpl(this._self, this._then);

  final WeekRankingState _self;
  final $Res Function(WeekRankingState) _then;

/// Create a copy of WeekRankingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? list = null,Object? hasReachedMax = null,Object? result = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JmRankingStatus,list: null == list ? _self.list : list // ignore: cast_nullable_to_non_nullable
as List<ListElement>,hasReachedMax: null == hasReachedMax ? _self.hasReachedMax : hasReachedMax // ignore: cast_nullable_to_non_nullable
as bool,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WeekRankingState].
extension WeekRankingStatePatterns on WeekRankingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeekRankingBlocState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeekRankingBlocState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeekRankingBlocState value)  $default,){
final _that = this;
switch (_that) {
case _WeekRankingBlocState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeekRankingBlocState value)?  $default,){
final _that = this;
switch (_that) {
case _WeekRankingBlocState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( JmRankingStatus status,  List<ListElement> list,  bool hasReachedMax,  String result)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeekRankingBlocState() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( JmRankingStatus status,  List<ListElement> list,  bool hasReachedMax,  String result)  $default,) {final _that = this;
switch (_that) {
case _WeekRankingBlocState():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( JmRankingStatus status,  List<ListElement> list,  bool hasReachedMax,  String result)?  $default,) {final _that = this;
switch (_that) {
case _WeekRankingBlocState() when $default != null:
return $default(_that.status,_that.list,_that.hasReachedMax,_that.result);case _:
  return null;

}
}

}

/// @nodoc


class _WeekRankingBlocState implements WeekRankingState {
  const _WeekRankingBlocState({this.status = JmRankingStatus.initial, final  List<ListElement> list = const [], this.hasReachedMax = false, this.result = ''}): _list = list;
  

@override@JsonKey() final  JmRankingStatus status;
 final  List<ListElement> _list;
@override@JsonKey() List<ListElement> get list {
  if (_list is EqualUnmodifiableListView) return _list;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_list);
}

@override@JsonKey() final  bool hasReachedMax;
@override@JsonKey() final  String result;

/// Create a copy of WeekRankingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeekRankingBlocStateCopyWith<_WeekRankingBlocState> get copyWith => __$WeekRankingBlocStateCopyWithImpl<_WeekRankingBlocState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeekRankingBlocState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._list, _list)&&(identical(other.hasReachedMax, hasReachedMax) || other.hasReachedMax == hasReachedMax)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_list),hasReachedMax,result);

@override
String toString() {
  return 'WeekRankingState(status: $status, list: $list, hasReachedMax: $hasReachedMax, result: $result)';
}


}

/// @nodoc
abstract mixin class _$WeekRankingBlocStateCopyWith<$Res> implements $WeekRankingStateCopyWith<$Res> {
  factory _$WeekRankingBlocStateCopyWith(_WeekRankingBlocState value, $Res Function(_WeekRankingBlocState) _then) = __$WeekRankingBlocStateCopyWithImpl;
@override @useResult
$Res call({
 JmRankingStatus status, List<ListElement> list, bool hasReachedMax, String result
});




}
/// @nodoc
class __$WeekRankingBlocStateCopyWithImpl<$Res>
    implements _$WeekRankingBlocStateCopyWith<$Res> {
  __$WeekRankingBlocStateCopyWithImpl(this._self, this._then);

  final _WeekRankingBlocState _self;
  final $Res Function(_WeekRankingBlocState) _then;

/// Create a copy of WeekRankingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? list = null,Object? hasReachedMax = null,Object? result = null,}) {
  return _then(_WeekRankingBlocState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JmRankingStatus,list: null == list ? _self._list : list // ignore: cast_nullable_to_non_nullable
as List<ListElement>,hasReachedMax: null == hasReachedMax ? _self.hasReachedMax : hasReachedMax // ignore: cast_nullable_to_non_nullable
as bool,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
