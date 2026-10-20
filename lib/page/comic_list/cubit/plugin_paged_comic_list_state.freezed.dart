// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plugin_paged_comic_list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PluginPagedComicListState {

 PluginPagedComicListStatus get status; List<UnifiedComicListItem> get list; bool get hasReachedMax; int get page; String get result; String get loginPluginId;
/// Create a copy of PluginPagedComicListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PluginPagedComicListStateCopyWith<PluginPagedComicListState> get copyWith => _$PluginPagedComicListStateCopyWithImpl<PluginPagedComicListState>(this as PluginPagedComicListState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PluginPagedComicListState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PluginPagedComicListState&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.list, _this.list)&&(identical(other.hasReachedMax, _this.hasReachedMax) || other.hasReachedMax == _this.hasReachedMax)&&(identical(other.page, _this.page) || other.page == _this.page)&&(identical(other.result, _this.result) || other.result == _this.result)&&(identical(other.loginPluginId, _this.loginPluginId) || other.loginPluginId == _this.loginPluginId));
}


@override
int get hashCode {
  final _this = this as PluginPagedComicListState;
  return Object.hash(runtimeType,_this.status,const DeepCollectionEquality().hash(_this.list),_this.hasReachedMax,_this.page,_this.result,_this.loginPluginId);
}

@override
String toString() {
  final _this = this as PluginPagedComicListState;
  return 'PluginPagedComicListState(status: ${_this.status}, list: ${_this.list}, hasReachedMax: ${_this.hasReachedMax}, page: ${_this.page}, result: ${_this.result}, loginPluginId: ${_this.loginPluginId})';
}


}

/// @nodoc
abstract mixin class $PluginPagedComicListStateCopyWith<$Res>  {
  factory $PluginPagedComicListStateCopyWith(PluginPagedComicListState value, $Res Function(PluginPagedComicListState) _then) = _$PluginPagedComicListStateCopyWithImpl;
@useResult
$Res call({
 PluginPagedComicListStatus status, List<UnifiedComicListItem> list, bool hasReachedMax, int page, String result, String loginPluginId
});




}
/// @nodoc
class _$PluginPagedComicListStateCopyWithImpl<$Res>
    implements $PluginPagedComicListStateCopyWith<$Res> {
  _$PluginPagedComicListStateCopyWithImpl(this._self, this._then);

  final PluginPagedComicListState _self;
  final $Res Function(PluginPagedComicListState) _then;

/// Create a copy of PluginPagedComicListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? list = null,Object? hasReachedMax = null,Object? page = null,Object? result = null,Object? loginPluginId = null,}) {
  return _then(PluginPagedComicListState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PluginPagedComicListStatus,list: null == list ? _self.list : list // ignore: cast_nullable_to_non_nullable
as List<UnifiedComicListItem>,hasReachedMax: null == hasReachedMax ? _self.hasReachedMax : hasReachedMax // ignore: cast_nullable_to_non_nullable
as bool,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,loginPluginId: null == loginPluginId ? _self.loginPluginId : loginPluginId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PluginPagedComicListState].
extension PluginPagedComicListStatePatterns on PluginPagedComicListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PluginPagedComicListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PluginPagedComicListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PluginPagedComicListState value)  $default,){
final _that = this;
switch (_that) {
case _PluginPagedComicListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PluginPagedComicListState value)?  $default,){
final _that = this;
switch (_that) {
case _PluginPagedComicListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PluginPagedComicListStatus status,  List<UnifiedComicListItem> list,  bool hasReachedMax,  int page,  String result,  String loginPluginId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PluginPagedComicListState() when $default != null:
return $default(_that.status,_that.list,_that.hasReachedMax,_that.page,_that.result,_that.loginPluginId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PluginPagedComicListStatus status,  List<UnifiedComicListItem> list,  bool hasReachedMax,  int page,  String result,  String loginPluginId)  $default,) {final _that = this;
switch (_that) {
case _PluginPagedComicListState():
return $default(_that.status,_that.list,_that.hasReachedMax,_that.page,_that.result,_that.loginPluginId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PluginPagedComicListStatus status,  List<UnifiedComicListItem> list,  bool hasReachedMax,  int page,  String result,  String loginPluginId)?  $default,) {final _that = this;
switch (_that) {
case _PluginPagedComicListState() when $default != null:
return $default(_that.status,_that.list,_that.hasReachedMax,_that.page,_that.result,_that.loginPluginId);case _:
  return null;

}
}

}

/// @nodoc


class _PluginPagedComicListState implements PluginPagedComicListState {
  const _PluginPagedComicListState({this.status = PluginPagedComicListStatus.initial,  List<UnifiedComicListItem> list = const <UnifiedComicListItem>[], this.hasReachedMax = false, this.page = 1, this.result = '', this.loginPluginId = ''}): _list = list;
  

@override@JsonKey() final  PluginPagedComicListStatus status;
 final  List<UnifiedComicListItem> _list;
@override@JsonKey() List<UnifiedComicListItem> get list {
  if (_list is EqualUnmodifiableListView) return _list;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_list);
}

@override@JsonKey() final  bool hasReachedMax;
@override@JsonKey() final  int page;
@override@JsonKey() final  String result;
@override@JsonKey() final  String loginPluginId;

/// Create a copy of PluginPagedComicListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PluginPagedComicListStateCopyWith<_PluginPagedComicListState> get copyWith => __$PluginPagedComicListStateCopyWithImpl<_PluginPagedComicListState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PluginPagedComicListState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.list, _list)&&(identical(other.hasReachedMax, hasReachedMax) || other.hasReachedMax == hasReachedMax)&&(identical(other.page, page) || other.page == page)&&(identical(other.result, result) || other.result == result)&&(identical(other.loginPluginId, loginPluginId) || other.loginPluginId == loginPluginId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_list),hasReachedMax,page,result,loginPluginId);
}

@override
String toString() {
    return 'PluginPagedComicListState(status: $status, list: $list, hasReachedMax: $hasReachedMax, page: $page, result: $result, loginPluginId: $loginPluginId)';
}


}

/// @nodoc
abstract mixin class _$PluginPagedComicListStateCopyWith<$Res> implements $PluginPagedComicListStateCopyWith<$Res> {
  factory _$PluginPagedComicListStateCopyWith(_PluginPagedComicListState value, $Res Function(_PluginPagedComicListState) _then) = __$PluginPagedComicListStateCopyWithImpl;
@override @useResult
$Res call({
 PluginPagedComicListStatus status, List<UnifiedComicListItem> list, bool hasReachedMax, int page, String result, String loginPluginId
});




}
/// @nodoc
class __$PluginPagedComicListStateCopyWithImpl<$Res>
    implements _$PluginPagedComicListStateCopyWith<$Res> {
  __$PluginPagedComicListStateCopyWithImpl(this._self, this._then);

  final _PluginPagedComicListState _self;
  final $Res Function(_PluginPagedComicListState) _then;

/// Create a copy of PluginPagedComicListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? list = null,Object? hasReachedMax = null,Object? page = null,Object? result = null,Object? loginPluginId = null,}) {
  return _then(_PluginPagedComicListState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PluginPagedComicListStatus,list: null == list ? _self._list : list // ignore: cast_nullable_to_non_nullable
as List<UnifiedComicListItem>,hasReachedMax: null == hasReachedMax ? _self.hasReachedMax : hasReachedMax // ignore: cast_nullable_to_non_nullable
as bool,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,loginPluginId: null == loginPluginId ? _self.loginPluginId : loginPluginId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
