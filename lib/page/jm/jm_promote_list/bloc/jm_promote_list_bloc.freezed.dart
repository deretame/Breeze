// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jm_promote_list_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$JmPromoteListEvent {

 JmPromoteListStatus get status; int get page; int get id;
/// Create a copy of JmPromoteListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JmPromoteListEventCopyWith<JmPromoteListEvent> get copyWith => _$JmPromoteListEventCopyWithImpl<JmPromoteListEvent>(this as JmPromoteListEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JmPromoteListEvent&&(identical(other.status, status) || other.status == status)&&(identical(other.page, page) || other.page == page)&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,status,page,id);

@override
String toString() {
  return 'JmPromoteListEvent(status: $status, page: $page, id: $id)';
}


}

/// @nodoc
abstract mixin class $JmPromoteListEventCopyWith<$Res>  {
  factory $JmPromoteListEventCopyWith(JmPromoteListEvent value, $Res Function(JmPromoteListEvent) _then) = _$JmPromoteListEventCopyWithImpl;
@useResult
$Res call({
 JmPromoteListStatus status, int page, int id
});




}
/// @nodoc
class _$JmPromoteListEventCopyWithImpl<$Res>
    implements $JmPromoteListEventCopyWith<$Res> {
  _$JmPromoteListEventCopyWithImpl(this._self, this._then);

  final JmPromoteListEvent _self;
  final $Res Function(JmPromoteListEvent) _then;

/// Create a copy of JmPromoteListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? page = null,Object? id = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JmPromoteListStatus,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// @nodoc


class _JmPromoteListEvent implements JmPromoteListEvent {
  const _JmPromoteListEvent({this.status = JmPromoteListStatus.initial, this.page = 0, this.id = 0});
  

@override@JsonKey() final  JmPromoteListStatus status;
@override@JsonKey() final  int page;
@override@JsonKey() final  int id;

/// Create a copy of JmPromoteListEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JmPromoteListEventCopyWith<_JmPromoteListEvent> get copyWith => __$JmPromoteListEventCopyWithImpl<_JmPromoteListEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JmPromoteListEvent&&(identical(other.status, status) || other.status == status)&&(identical(other.page, page) || other.page == page)&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,status,page,id);

@override
String toString() {
  return 'JmPromoteListEvent(status: $status, page: $page, id: $id)';
}


}

/// @nodoc
abstract mixin class _$JmPromoteListEventCopyWith<$Res> implements $JmPromoteListEventCopyWith<$Res> {
  factory _$JmPromoteListEventCopyWith(_JmPromoteListEvent value, $Res Function(_JmPromoteListEvent) _then) = __$JmPromoteListEventCopyWithImpl;
@override @useResult
$Res call({
 JmPromoteListStatus status, int page, int id
});




}
/// @nodoc
class __$JmPromoteListEventCopyWithImpl<$Res>
    implements _$JmPromoteListEventCopyWith<$Res> {
  __$JmPromoteListEventCopyWithImpl(this._self, this._then);

  final _JmPromoteListEvent _self;
  final $Res Function(_JmPromoteListEvent) _then;

/// Create a copy of JmPromoteListEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? page = null,Object? id = null,}) {
  return _then(_JmPromoteListEvent(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JmPromoteListStatus,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$JmPromoteListState {

 JmPromoteListStatus get status; List<ListElement> get list; bool get hasReachedMax; String get result;
/// Create a copy of JmPromoteListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JmPromoteListStateCopyWith<JmPromoteListState> get copyWith => _$JmPromoteListStateCopyWithImpl<JmPromoteListState>(this as JmPromoteListState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JmPromoteListState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.list, list)&&(identical(other.hasReachedMax, hasReachedMax) || other.hasReachedMax == hasReachedMax)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(list),hasReachedMax,result);

@override
String toString() {
  return 'JmPromoteListState(status: $status, list: $list, hasReachedMax: $hasReachedMax, result: $result)';
}


}

/// @nodoc
abstract mixin class $JmPromoteListStateCopyWith<$Res>  {
  factory $JmPromoteListStateCopyWith(JmPromoteListState value, $Res Function(JmPromoteListState) _then) = _$JmPromoteListStateCopyWithImpl;
@useResult
$Res call({
 JmPromoteListStatus status, List<ListElement> list, bool hasReachedMax, String result
});




}
/// @nodoc
class _$JmPromoteListStateCopyWithImpl<$Res>
    implements $JmPromoteListStateCopyWith<$Res> {
  _$JmPromoteListStateCopyWithImpl(this._self, this._then);

  final JmPromoteListState _self;
  final $Res Function(JmPromoteListState) _then;

/// Create a copy of JmPromoteListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? list = null,Object? hasReachedMax = null,Object? result = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JmPromoteListStatus,list: null == list ? _self.list : list // ignore: cast_nullable_to_non_nullable
as List<ListElement>,hasReachedMax: null == hasReachedMax ? _self.hasReachedMax : hasReachedMax // ignore: cast_nullable_to_non_nullable
as bool,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc


class _JmPromoteListState implements JmPromoteListState {
  const _JmPromoteListState({this.status = JmPromoteListStatus.initial, final  List<ListElement> list = const [], this.hasReachedMax = false, this.result = ''}): _list = list;
  

@override@JsonKey() final  JmPromoteListStatus status;
 final  List<ListElement> _list;
@override@JsonKey() List<ListElement> get list {
  if (_list is EqualUnmodifiableListView) return _list;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_list);
}

@override@JsonKey() final  bool hasReachedMax;
@override@JsonKey() final  String result;

/// Create a copy of JmPromoteListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JmPromoteListStateCopyWith<_JmPromoteListState> get copyWith => __$JmPromoteListStateCopyWithImpl<_JmPromoteListState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JmPromoteListState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._list, _list)&&(identical(other.hasReachedMax, hasReachedMax) || other.hasReachedMax == hasReachedMax)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_list),hasReachedMax,result);

@override
String toString() {
  return 'JmPromoteListState(status: $status, list: $list, hasReachedMax: $hasReachedMax, result: $result)';
}


}

/// @nodoc
abstract mixin class _$JmPromoteListStateCopyWith<$Res> implements $JmPromoteListStateCopyWith<$Res> {
  factory _$JmPromoteListStateCopyWith(_JmPromoteListState value, $Res Function(_JmPromoteListState) _then) = __$JmPromoteListStateCopyWithImpl;
@override @useResult
$Res call({
 JmPromoteListStatus status, List<ListElement> list, bool hasReachedMax, String result
});




}
/// @nodoc
class __$JmPromoteListStateCopyWithImpl<$Res>
    implements _$JmPromoteListStateCopyWith<$Res> {
  __$JmPromoteListStateCopyWithImpl(this._self, this._then);

  final _JmPromoteListState _self;
  final $Res Function(_JmPromoteListState) _then;

/// Create a copy of JmPromoteListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? list = null,Object? hasReachedMax = null,Object? result = null,}) {
  return _then(_JmPromoteListState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JmPromoteListStatus,list: null == list ? _self._list : list // ignore: cast_nullable_to_non_nullable
as List<ListElement>,hasReachedMax: null == hasReachedMax ? _self.hasReachedMax : hasReachedMax // ignore: cast_nullable_to_non_nullable
as bool,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
