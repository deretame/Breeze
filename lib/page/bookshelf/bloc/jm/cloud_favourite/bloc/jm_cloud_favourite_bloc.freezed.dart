// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jm_cloud_favourite_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$JmCloudFavouriteEvent {

 int get page; String get id; String get order; JmCloudFavouriteStatus get status;
/// Create a copy of JmCloudFavouriteEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JmCloudFavouriteEventCopyWith<JmCloudFavouriteEvent> get copyWith => _$JmCloudFavouriteEventCopyWithImpl<JmCloudFavouriteEvent>(this as JmCloudFavouriteEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JmCloudFavouriteEvent&&(identical(other.page, page) || other.page == page)&&(identical(other.id, id) || other.id == id)&&(identical(other.order, order) || other.order == order)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,page,id,order,status);

@override
String toString() {
  return 'JmCloudFavouriteEvent(page: $page, id: $id, order: $order, status: $status)';
}


}

/// @nodoc
abstract mixin class $JmCloudFavouriteEventCopyWith<$Res>  {
  factory $JmCloudFavouriteEventCopyWith(JmCloudFavouriteEvent value, $Res Function(JmCloudFavouriteEvent) _then) = _$JmCloudFavouriteEventCopyWithImpl;
@useResult
$Res call({
 int page, String id, String order, JmCloudFavouriteStatus status
});




}
/// @nodoc
class _$JmCloudFavouriteEventCopyWithImpl<$Res>
    implements $JmCloudFavouriteEventCopyWith<$Res> {
  _$JmCloudFavouriteEventCopyWithImpl(this._self, this._then);

  final JmCloudFavouriteEvent _self;
  final $Res Function(JmCloudFavouriteEvent) _then;

/// Create a copy of JmCloudFavouriteEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? page = null,Object? id = null,Object? order = null,Object? status = null,}) {
  return _then(_self.copyWith(
page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JmCloudFavouriteStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [JmCloudFavouriteEvent].
extension JmCloudFavouriteEventPatterns on JmCloudFavouriteEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JmCloudFavouriteEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JmCloudFavouriteEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JmCloudFavouriteEvent value)  $default,){
final _that = this;
switch (_that) {
case _JmCloudFavouriteEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JmCloudFavouriteEvent value)?  $default,){
final _that = this;
switch (_that) {
case _JmCloudFavouriteEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int page,  String id,  String order,  JmCloudFavouriteStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JmCloudFavouriteEvent() when $default != null:
return $default(_that.page,_that.id,_that.order,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int page,  String id,  String order,  JmCloudFavouriteStatus status)  $default,) {final _that = this;
switch (_that) {
case _JmCloudFavouriteEvent():
return $default(_that.page,_that.id,_that.order,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int page,  String id,  String order,  JmCloudFavouriteStatus status)?  $default,) {final _that = this;
switch (_that) {
case _JmCloudFavouriteEvent() when $default != null:
return $default(_that.page,_that.id,_that.order,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _JmCloudFavouriteEvent implements JmCloudFavouriteEvent {
  const _JmCloudFavouriteEvent({this.page = 1, this.id = '', this.order = 'mr', this.status = JmCloudFavouriteStatus.initial});
  

@override@JsonKey() final  int page;
@override@JsonKey() final  String id;
@override@JsonKey() final  String order;
@override@JsonKey() final  JmCloudFavouriteStatus status;

/// Create a copy of JmCloudFavouriteEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JmCloudFavouriteEventCopyWith<_JmCloudFavouriteEvent> get copyWith => __$JmCloudFavouriteEventCopyWithImpl<_JmCloudFavouriteEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JmCloudFavouriteEvent&&(identical(other.page, page) || other.page == page)&&(identical(other.id, id) || other.id == id)&&(identical(other.order, order) || other.order == order)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,page,id,order,status);

@override
String toString() {
  return 'JmCloudFavouriteEvent(page: $page, id: $id, order: $order, status: $status)';
}


}

/// @nodoc
abstract mixin class _$JmCloudFavouriteEventCopyWith<$Res> implements $JmCloudFavouriteEventCopyWith<$Res> {
  factory _$JmCloudFavouriteEventCopyWith(_JmCloudFavouriteEvent value, $Res Function(_JmCloudFavouriteEvent) _then) = __$JmCloudFavouriteEventCopyWithImpl;
@override @useResult
$Res call({
 int page, String id, String order, JmCloudFavouriteStatus status
});




}
/// @nodoc
class __$JmCloudFavouriteEventCopyWithImpl<$Res>
    implements _$JmCloudFavouriteEventCopyWith<$Res> {
  __$JmCloudFavouriteEventCopyWithImpl(this._self, this._then);

  final _JmCloudFavouriteEvent _self;
  final $Res Function(_JmCloudFavouriteEvent) _then;

/// Create a copy of JmCloudFavouriteEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? page = null,Object? id = null,Object? order = null,Object? status = null,}) {
  return _then(_JmCloudFavouriteEvent(
page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JmCloudFavouriteStatus,
  ));
}


}

/// @nodoc
mixin _$JmCloudFavouriteState {

 JmCloudFavouriteStatus get status; List<ListElement> get list; List<FolderList> get folderList; JmCloudFavouriteEvent get event; bool get hasMore; String get result;
/// Create a copy of JmCloudFavouriteState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JmCloudFavouriteStateCopyWith<JmCloudFavouriteState> get copyWith => _$JmCloudFavouriteStateCopyWithImpl<JmCloudFavouriteState>(this as JmCloudFavouriteState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JmCloudFavouriteState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.list, list)&&const DeepCollectionEquality().equals(other.folderList, folderList)&&(identical(other.event, event) || other.event == event)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(list),const DeepCollectionEquality().hash(folderList),event,hasMore,result);

@override
String toString() {
  return 'JmCloudFavouriteState(status: $status, list: $list, folderList: $folderList, event: $event, hasMore: $hasMore, result: $result)';
}


}

/// @nodoc
abstract mixin class $JmCloudFavouriteStateCopyWith<$Res>  {
  factory $JmCloudFavouriteStateCopyWith(JmCloudFavouriteState value, $Res Function(JmCloudFavouriteState) _then) = _$JmCloudFavouriteStateCopyWithImpl;
@useResult
$Res call({
 JmCloudFavouriteStatus status, List<ListElement> list, List<FolderList> folderList, JmCloudFavouriteEvent event, bool hasMore, String result
});


$JmCloudFavouriteEventCopyWith<$Res> get event;

}
/// @nodoc
class _$JmCloudFavouriteStateCopyWithImpl<$Res>
    implements $JmCloudFavouriteStateCopyWith<$Res> {
  _$JmCloudFavouriteStateCopyWithImpl(this._self, this._then);

  final JmCloudFavouriteState _self;
  final $Res Function(JmCloudFavouriteState) _then;

/// Create a copy of JmCloudFavouriteState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? list = null,Object? folderList = null,Object? event = null,Object? hasMore = null,Object? result = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JmCloudFavouriteStatus,list: null == list ? _self.list : list // ignore: cast_nullable_to_non_nullable
as List<ListElement>,folderList: null == folderList ? _self.folderList : folderList // ignore: cast_nullable_to_non_nullable
as List<FolderList>,event: null == event ? _self.event : event // ignore: cast_nullable_to_non_nullable
as JmCloudFavouriteEvent,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of JmCloudFavouriteState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JmCloudFavouriteEventCopyWith<$Res> get event {
  
  return $JmCloudFavouriteEventCopyWith<$Res>(_self.event, (value) {
    return _then(_self.copyWith(event: value));
  });
}
}


/// Adds pattern-matching-related methods to [JmCloudFavouriteState].
extension JmCloudFavouriteStatePatterns on JmCloudFavouriteState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JmCloudFavouriteState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JmCloudFavouriteState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JmCloudFavouriteState value)  $default,){
final _that = this;
switch (_that) {
case _JmCloudFavouriteState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JmCloudFavouriteState value)?  $default,){
final _that = this;
switch (_that) {
case _JmCloudFavouriteState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( JmCloudFavouriteStatus status,  List<ListElement> list,  List<FolderList> folderList,  JmCloudFavouriteEvent event,  bool hasMore,  String result)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JmCloudFavouriteState() when $default != null:
return $default(_that.status,_that.list,_that.folderList,_that.event,_that.hasMore,_that.result);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( JmCloudFavouriteStatus status,  List<ListElement> list,  List<FolderList> folderList,  JmCloudFavouriteEvent event,  bool hasMore,  String result)  $default,) {final _that = this;
switch (_that) {
case _JmCloudFavouriteState():
return $default(_that.status,_that.list,_that.folderList,_that.event,_that.hasMore,_that.result);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( JmCloudFavouriteStatus status,  List<ListElement> list,  List<FolderList> folderList,  JmCloudFavouriteEvent event,  bool hasMore,  String result)?  $default,) {final _that = this;
switch (_that) {
case _JmCloudFavouriteState() when $default != null:
return $default(_that.status,_that.list,_that.folderList,_that.event,_that.hasMore,_that.result);case _:
  return null;

}
}

}

/// @nodoc


class _JmCloudFavouriteState implements JmCloudFavouriteState {
  const _JmCloudFavouriteState({this.status = JmCloudFavouriteStatus.initial, final  List<ListElement> list = const [], final  List<FolderList> folderList = const [], this.event = const JmCloudFavouriteEvent(), this.hasMore = true, this.result = ''}): _list = list,_folderList = folderList;
  

@override@JsonKey() final  JmCloudFavouriteStatus status;
 final  List<ListElement> _list;
@override@JsonKey() List<ListElement> get list {
  if (_list is EqualUnmodifiableListView) return _list;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_list);
}

 final  List<FolderList> _folderList;
@override@JsonKey() List<FolderList> get folderList {
  if (_folderList is EqualUnmodifiableListView) return _folderList;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_folderList);
}

@override@JsonKey() final  JmCloudFavouriteEvent event;
@override@JsonKey() final  bool hasMore;
@override@JsonKey() final  String result;

/// Create a copy of JmCloudFavouriteState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JmCloudFavouriteStateCopyWith<_JmCloudFavouriteState> get copyWith => __$JmCloudFavouriteStateCopyWithImpl<_JmCloudFavouriteState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JmCloudFavouriteState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._list, _list)&&const DeepCollectionEquality().equals(other._folderList, _folderList)&&(identical(other.event, event) || other.event == event)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_list),const DeepCollectionEquality().hash(_folderList),event,hasMore,result);

@override
String toString() {
  return 'JmCloudFavouriteState(status: $status, list: $list, folderList: $folderList, event: $event, hasMore: $hasMore, result: $result)';
}


}

/// @nodoc
abstract mixin class _$JmCloudFavouriteStateCopyWith<$Res> implements $JmCloudFavouriteStateCopyWith<$Res> {
  factory _$JmCloudFavouriteStateCopyWith(_JmCloudFavouriteState value, $Res Function(_JmCloudFavouriteState) _then) = __$JmCloudFavouriteStateCopyWithImpl;
@override @useResult
$Res call({
 JmCloudFavouriteStatus status, List<ListElement> list, List<FolderList> folderList, JmCloudFavouriteEvent event, bool hasMore, String result
});


@override $JmCloudFavouriteEventCopyWith<$Res> get event;

}
/// @nodoc
class __$JmCloudFavouriteStateCopyWithImpl<$Res>
    implements _$JmCloudFavouriteStateCopyWith<$Res> {
  __$JmCloudFavouriteStateCopyWithImpl(this._self, this._then);

  final _JmCloudFavouriteState _self;
  final $Res Function(_JmCloudFavouriteState) _then;

/// Create a copy of JmCloudFavouriteState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? list = null,Object? folderList = null,Object? event = null,Object? hasMore = null,Object? result = null,}) {
  return _then(_JmCloudFavouriteState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JmCloudFavouriteStatus,list: null == list ? _self._list : list // ignore: cast_nullable_to_non_nullable
as List<ListElement>,folderList: null == folderList ? _self._folderList : folderList // ignore: cast_nullable_to_non_nullable
as List<FolderList>,event: null == event ? _self.event : event // ignore: cast_nullable_to_non_nullable
as JmCloudFavouriteEvent,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of JmCloudFavouriteState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JmCloudFavouriteEventCopyWith<$Res> get event {
  
  return $JmCloudFavouriteEventCopyWith<$Res>(_self.event, (value) {
    return _then(_self.copyWith(event: value));
  });
}
}

// dart format on
