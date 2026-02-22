// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dowload_task_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DowloadTaskEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DowloadTaskEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DowloadTaskEvent()';
}


}

/// @nodoc
class $DowloadTaskEventCopyWith<$Res>  {
$DowloadTaskEventCopyWith(DowloadTaskEvent _, $Res Function(DowloadTaskEvent) __);
}


/// Adds pattern-matching-related methods to [DowloadTaskEvent].
extension DowloadTaskEventPatterns on DowloadTaskEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Started value)?  started,TResult Function( _TasksUpdated value)?  tasksUpdated,TResult Function( _TaskDeleted value)?  taskDeleted,TResult Function( _ClearCompleted value)?  clearCompleted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Started() when started != null:
return started(_that);case _TasksUpdated() when tasksUpdated != null:
return tasksUpdated(_that);case _TaskDeleted() when taskDeleted != null:
return taskDeleted(_that);case _ClearCompleted() when clearCompleted != null:
return clearCompleted(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Started value)  started,required TResult Function( _TasksUpdated value)  tasksUpdated,required TResult Function( _TaskDeleted value)  taskDeleted,required TResult Function( _ClearCompleted value)  clearCompleted,}){
final _that = this;
switch (_that) {
case _Started():
return started(_that);case _TasksUpdated():
return tasksUpdated(_that);case _TaskDeleted():
return taskDeleted(_that);case _ClearCompleted():
return clearCompleted(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Started value)?  started,TResult? Function( _TasksUpdated value)?  tasksUpdated,TResult? Function( _TaskDeleted value)?  taskDeleted,TResult? Function( _ClearCompleted value)?  clearCompleted,}){
final _that = this;
switch (_that) {
case _Started() when started != null:
return started(_that);case _TasksUpdated() when tasksUpdated != null:
return tasksUpdated(_that);case _TaskDeleted() when taskDeleted != null:
return taskDeleted(_that);case _ClearCompleted() when clearCompleted != null:
return clearCompleted(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function( List<DownloadTask> tasks)?  tasksUpdated,TResult Function( int taskId)?  taskDeleted,TResult Function()?  clearCompleted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Started() when started != null:
return started();case _TasksUpdated() when tasksUpdated != null:
return tasksUpdated(_that.tasks);case _TaskDeleted() when taskDeleted != null:
return taskDeleted(_that.taskId);case _ClearCompleted() when clearCompleted != null:
return clearCompleted();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function( List<DownloadTask> tasks)  tasksUpdated,required TResult Function( int taskId)  taskDeleted,required TResult Function()  clearCompleted,}) {final _that = this;
switch (_that) {
case _Started():
return started();case _TasksUpdated():
return tasksUpdated(_that.tasks);case _TaskDeleted():
return taskDeleted(_that.taskId);case _ClearCompleted():
return clearCompleted();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function( List<DownloadTask> tasks)?  tasksUpdated,TResult? Function( int taskId)?  taskDeleted,TResult? Function()?  clearCompleted,}) {final _that = this;
switch (_that) {
case _Started() when started != null:
return started();case _TasksUpdated() when tasksUpdated != null:
return tasksUpdated(_that.tasks);case _TaskDeleted() when taskDeleted != null:
return taskDeleted(_that.taskId);case _ClearCompleted() when clearCompleted != null:
return clearCompleted();case _:
  return null;

}
}

}

/// @nodoc


class _Started implements DowloadTaskEvent {
  const _Started();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Started);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DowloadTaskEvent.started()';
}


}




/// @nodoc


class _TasksUpdated implements DowloadTaskEvent {
  const _TasksUpdated(final  List<DownloadTask> tasks): _tasks = tasks;
  

 final  List<DownloadTask> _tasks;
 List<DownloadTask> get tasks {
  if (_tasks is EqualUnmodifiableListView) return _tasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tasks);
}


/// Create a copy of DowloadTaskEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TasksUpdatedCopyWith<_TasksUpdated> get copyWith => __$TasksUpdatedCopyWithImpl<_TasksUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TasksUpdated&&const DeepCollectionEquality().equals(other._tasks, _tasks));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tasks));

@override
String toString() {
  return 'DowloadTaskEvent.tasksUpdated(tasks: $tasks)';
}


}

/// @nodoc
abstract mixin class _$TasksUpdatedCopyWith<$Res> implements $DowloadTaskEventCopyWith<$Res> {
  factory _$TasksUpdatedCopyWith(_TasksUpdated value, $Res Function(_TasksUpdated) _then) = __$TasksUpdatedCopyWithImpl;
@useResult
$Res call({
 List<DownloadTask> tasks
});




}
/// @nodoc
class __$TasksUpdatedCopyWithImpl<$Res>
    implements _$TasksUpdatedCopyWith<$Res> {
  __$TasksUpdatedCopyWithImpl(this._self, this._then);

  final _TasksUpdated _self;
  final $Res Function(_TasksUpdated) _then;

/// Create a copy of DowloadTaskEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tasks = null,}) {
  return _then(_TasksUpdated(
null == tasks ? _self._tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<DownloadTask>,
  ));
}


}

/// @nodoc


class _TaskDeleted implements DowloadTaskEvent {
  const _TaskDeleted(this.taskId);
  

 final  int taskId;

/// Create a copy of DowloadTaskEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskDeletedCopyWith<_TaskDeleted> get copyWith => __$TaskDeletedCopyWithImpl<_TaskDeleted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskDeleted&&(identical(other.taskId, taskId) || other.taskId == taskId));
}


@override
int get hashCode => Object.hash(runtimeType,taskId);

@override
String toString() {
  return 'DowloadTaskEvent.taskDeleted(taskId: $taskId)';
}


}

/// @nodoc
abstract mixin class _$TaskDeletedCopyWith<$Res> implements $DowloadTaskEventCopyWith<$Res> {
  factory _$TaskDeletedCopyWith(_TaskDeleted value, $Res Function(_TaskDeleted) _then) = __$TaskDeletedCopyWithImpl;
@useResult
$Res call({
 int taskId
});




}
/// @nodoc
class __$TaskDeletedCopyWithImpl<$Res>
    implements _$TaskDeletedCopyWith<$Res> {
  __$TaskDeletedCopyWithImpl(this._self, this._then);

  final _TaskDeleted _self;
  final $Res Function(_TaskDeleted) _then;

/// Create a copy of DowloadTaskEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? taskId = null,}) {
  return _then(_TaskDeleted(
null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _ClearCompleted implements DowloadTaskEvent {
  const _ClearCompleted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClearCompleted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DowloadTaskEvent.clearCompleted()';
}


}




/// @nodoc
mixin _$DowloadTaskState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DowloadTaskState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DowloadTaskState()';
}


}

/// @nodoc
class $DowloadTaskStateCopyWith<$Res>  {
$DowloadTaskStateCopyWith(DowloadTaskState _, $Res Function(DowloadTaskState) __);
}


/// Adds pattern-matching-related methods to [DowloadTaskState].
extension DowloadTaskStatePatterns on DowloadTaskState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loaded value)?  loaded,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loaded() when loaded != null:
return loaded(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loaded value)  loaded,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loaded():
return loaded(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loaded value)?  loaded,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loaded() when loaded != null:
return loaded(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( List<DownloadTask> tasks,  int pendingCount)?  loaded,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loaded() when loaded != null:
return loaded(_that.tasks,_that.pendingCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( List<DownloadTask> tasks,  int pendingCount)  loaded,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loaded():
return loaded(_that.tasks,_that.pendingCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( List<DownloadTask> tasks,  int pendingCount)?  loaded,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loaded() when loaded != null:
return loaded(_that.tasks,_that.pendingCount);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements DowloadTaskState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DowloadTaskState.initial()';
}


}




/// @nodoc


class _Loaded implements DowloadTaskState {
  const _Loaded({required final  List<DownloadTask> tasks, required this.pendingCount}): _tasks = tasks;
  

 final  List<DownloadTask> _tasks;
 List<DownloadTask> get tasks {
  if (_tasks is EqualUnmodifiableListView) return _tasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tasks);
}

 final  int pendingCount;

/// Create a copy of DowloadTaskState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other._tasks, _tasks)&&(identical(other.pendingCount, pendingCount) || other.pendingCount == pendingCount));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tasks),pendingCount);

@override
String toString() {
  return 'DowloadTaskState.loaded(tasks: $tasks, pendingCount: $pendingCount)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $DowloadTaskStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 List<DownloadTask> tasks, int pendingCount
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of DowloadTaskState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tasks = null,Object? pendingCount = null,}) {
  return _then(_Loaded(
tasks: null == tasks ? _self._tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<DownloadTask>,pendingCount: null == pendingCount ? _self.pendingCount : pendingCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
