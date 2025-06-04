// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
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

 PromoteStatus get status;
/// Create a copy of PromoteEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PromoteEventCopyWith<PromoteEvent> get copyWith => _$PromoteEventCopyWithImpl<PromoteEvent>(this as PromoteEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PromoteEvent&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'PromoteEvent(status: $status)';
}


}

/// @nodoc
abstract mixin class $PromoteEventCopyWith<$Res>  {
  factory $PromoteEventCopyWith(PromoteEvent value, $Res Function(PromoteEvent) _then) = _$PromoteEventCopyWithImpl;
@useResult
$Res call({
 PromoteStatus status
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
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PromoteStatus,
  ));
}

}


/// @nodoc


class _PromoteEvent implements PromoteEvent {
  const _PromoteEvent({this.status = PromoteStatus.initial});
  

@override@JsonKey() final  PromoteStatus status;

/// Create a copy of PromoteEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PromoteEventCopyWith<_PromoteEvent> get copyWith => __$PromoteEventCopyWithImpl<_PromoteEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PromoteEvent&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'PromoteEvent(status: $status)';
}


}

/// @nodoc
abstract mixin class _$PromoteEventCopyWith<$Res> implements $PromoteEventCopyWith<$Res> {
  factory _$PromoteEventCopyWith(_PromoteEvent value, $Res Function(_PromoteEvent) _then) = __$PromoteEventCopyWithImpl;
@override @useResult
$Res call({
 PromoteStatus status
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
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,}) {
  return _then(_PromoteEvent(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PromoteStatus,
  ));
}


}

/// @nodoc
mixin _$PromoteState {

 PromoteStatus get status; List<JmPromoteJson> get list; String get result;
/// Create a copy of PromoteState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PromoteStateCopyWith<PromoteState> get copyWith => _$PromoteStateCopyWithImpl<PromoteState>(this as PromoteState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PromoteState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.list, list)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(list),result);

@override
String toString() {
  return 'PromoteState(status: $status, list: $list, result: $result)';
}


}

/// @nodoc
abstract mixin class $PromoteStateCopyWith<$Res>  {
  factory $PromoteStateCopyWith(PromoteState value, $Res Function(PromoteState) _then) = _$PromoteStateCopyWithImpl;
@useResult
$Res call({
 PromoteStatus status, List<JmPromoteJson> list, String result
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
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? list = null,Object? result = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PromoteStatus,list: null == list ? _self.list : list // ignore: cast_nullable_to_non_nullable
as List<JmPromoteJson>,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc


class _PromoteState implements PromoteState {
  const _PromoteState({this.status = PromoteStatus.initial, final  List<JmPromoteJson> list = const [], this.result = ''}): _list = list;
  

@override@JsonKey() final  PromoteStatus status;
 final  List<JmPromoteJson> _list;
@override@JsonKey() List<JmPromoteJson> get list {
  if (_list is EqualUnmodifiableListView) return _list;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_list);
}

@override@JsonKey() final  String result;

/// Create a copy of PromoteState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PromoteStateCopyWith<_PromoteState> get copyWith => __$PromoteStateCopyWithImpl<_PromoteState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PromoteState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._list, _list)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_list),result);

@override
String toString() {
  return 'PromoteState(status: $status, list: $list, result: $result)';
}


}

/// @nodoc
abstract mixin class _$PromoteStateCopyWith<$Res> implements $PromoteStateCopyWith<$Res> {
  factory _$PromoteStateCopyWith(_PromoteState value, $Res Function(_PromoteState) _then) = __$PromoteStateCopyWithImpl;
@override @useResult
$Res call({
 PromoteStatus status, List<JmPromoteJson> list, String result
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
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? list = null,Object? result = null,}) {
  return _then(_PromoteState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PromoteStatus,list: null == list ? _self._list : list // ignore: cast_nullable_to_non_nullable
as List<JmPromoteJson>,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
