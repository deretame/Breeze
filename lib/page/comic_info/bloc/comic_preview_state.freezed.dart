// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comic_preview_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ComicPreviewState {

 ComicPreviewStatus get status; List<UnifiedPluginPreviewItem> get items; int get page; bool get hasReachedMax; Map<String, dynamic> get pluginExtern; String get result;
/// Create a copy of ComicPreviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicPreviewStateCopyWith<ComicPreviewState> get copyWith => _$ComicPreviewStateCopyWithImpl<ComicPreviewState>(this as ComicPreviewState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ComicPreviewState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicPreviewState&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.page, _this.page) || other.page == _this.page)&&(identical(other.hasReachedMax, _this.hasReachedMax) || other.hasReachedMax == _this.hasReachedMax)&&const DeepCollectionEquality().equals(other.pluginExtern, _this.pluginExtern)&&(identical(other.result, _this.result) || other.result == _this.result));
}


@override
int get hashCode {
  final _this = this as ComicPreviewState;
  return Object.hash(runtimeType,_this.status,const DeepCollectionEquality().hash(_this.items),_this.page,_this.hasReachedMax,const DeepCollectionEquality().hash(_this.pluginExtern),_this.result);
}

@override
String toString() {
  final _this = this as ComicPreviewState;
  return 'ComicPreviewState(status: ${_this.status}, items: ${_this.items}, page: ${_this.page}, hasReachedMax: ${_this.hasReachedMax}, pluginExtern: ${_this.pluginExtern}, result: ${_this.result})';
}


}

/// @nodoc
abstract mixin class $ComicPreviewStateCopyWith<$Res>  {
  factory $ComicPreviewStateCopyWith(ComicPreviewState value, $Res Function(ComicPreviewState) _then) = _$ComicPreviewStateCopyWithImpl;
@useResult
$Res call({
 ComicPreviewStatus status, List<UnifiedPluginPreviewItem> items, int page, bool hasReachedMax, Map<String, dynamic> pluginExtern, String result
});




}
/// @nodoc
class _$ComicPreviewStateCopyWithImpl<$Res>
    implements $ComicPreviewStateCopyWith<$Res> {
  _$ComicPreviewStateCopyWithImpl(this._self, this._then);

  final ComicPreviewState _self;
  final $Res Function(ComicPreviewState) _then;

/// Create a copy of ComicPreviewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? items = null,Object? page = null,Object? hasReachedMax = null,Object? pluginExtern = null,Object? result = null,}) {
  return _then(ComicPreviewState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ComicPreviewStatus,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<UnifiedPluginPreviewItem>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,hasReachedMax: null == hasReachedMax ? _self.hasReachedMax : hasReachedMax // ignore: cast_nullable_to_non_nullable
as bool,pluginExtern: null == pluginExtern ? _self.pluginExtern : pluginExtern // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ComicPreviewState].
extension ComicPreviewStatePatterns on ComicPreviewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicPreviewState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicPreviewState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicPreviewState value)  $default,){
final _that = this;
switch (_that) {
case _ComicPreviewState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicPreviewState value)?  $default,){
final _that = this;
switch (_that) {
case _ComicPreviewState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ComicPreviewStatus status,  List<UnifiedPluginPreviewItem> items,  int page,  bool hasReachedMax,  Map<String, dynamic> pluginExtern,  String result)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicPreviewState() when $default != null:
return $default(_that.status,_that.items,_that.page,_that.hasReachedMax,_that.pluginExtern,_that.result);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ComicPreviewStatus status,  List<UnifiedPluginPreviewItem> items,  int page,  bool hasReachedMax,  Map<String, dynamic> pluginExtern,  String result)  $default,) {final _that = this;
switch (_that) {
case _ComicPreviewState():
return $default(_that.status,_that.items,_that.page,_that.hasReachedMax,_that.pluginExtern,_that.result);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ComicPreviewStatus status,  List<UnifiedPluginPreviewItem> items,  int page,  bool hasReachedMax,  Map<String, dynamic> pluginExtern,  String result)?  $default,) {final _that = this;
switch (_that) {
case _ComicPreviewState() when $default != null:
return $default(_that.status,_that.items,_that.page,_that.hasReachedMax,_that.pluginExtern,_that.result);case _:
  return null;

}
}

}

/// @nodoc


class _ComicPreviewState implements ComicPreviewState {
  const _ComicPreviewState({this.status = ComicPreviewStatus.initial,  List<UnifiedPluginPreviewItem> items = const <UnifiedPluginPreviewItem>[], this.page = 0, this.hasReachedMax = false,  Map<String, dynamic> pluginExtern = const <String, dynamic>{}, this.result = ''}): _items = items,_pluginExtern = pluginExtern;
  

@override@JsonKey() final  ComicPreviewStatus status;
 final  List<UnifiedPluginPreviewItem> _items;
@override@JsonKey() List<UnifiedPluginPreviewItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int page;
@override@JsonKey() final  bool hasReachedMax;
 final  Map<String, dynamic> _pluginExtern;
@override@JsonKey() Map<String, dynamic> get pluginExtern {
  if (_pluginExtern is EqualUnmodifiableMapView) return _pluginExtern;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_pluginExtern);
}

@override@JsonKey() final  String result;

/// Create a copy of ComicPreviewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicPreviewStateCopyWith<_ComicPreviewState> get copyWith => __$ComicPreviewStateCopyWithImpl<_ComicPreviewState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicPreviewState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.page, page) || other.page == page)&&(identical(other.hasReachedMax, hasReachedMax) || other.hasReachedMax == hasReachedMax)&&const DeepCollectionEquality().equals(other.pluginExtern, _pluginExtern)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_items),page,hasReachedMax,const DeepCollectionEquality().hash(_pluginExtern),result);
}

@override
String toString() {
    return 'ComicPreviewState(status: $status, items: $items, page: $page, hasReachedMax: $hasReachedMax, pluginExtern: $pluginExtern, result: $result)';
}


}

/// @nodoc
abstract mixin class _$ComicPreviewStateCopyWith<$Res> implements $ComicPreviewStateCopyWith<$Res> {
  factory _$ComicPreviewStateCopyWith(_ComicPreviewState value, $Res Function(_ComicPreviewState) _then) = __$ComicPreviewStateCopyWithImpl;
@override @useResult
$Res call({
 ComicPreviewStatus status, List<UnifiedPluginPreviewItem> items, int page, bool hasReachedMax, Map<String, dynamic> pluginExtern, String result
});




}
/// @nodoc
class __$ComicPreviewStateCopyWithImpl<$Res>
    implements _$ComicPreviewStateCopyWith<$Res> {
  __$ComicPreviewStateCopyWithImpl(this._self, this._then);

  final _ComicPreviewState _self;
  final $Res Function(_ComicPreviewState) _then;

/// Create a copy of ComicPreviewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? items = null,Object? page = null,Object? hasReachedMax = null,Object? pluginExtern = null,Object? result = null,}) {
  return _then(_ComicPreviewState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ComicPreviewStatus,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<UnifiedPluginPreviewItem>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,hasReachedMax: null == hasReachedMax ? _self.hasReachedMax : hasReachedMax // ignore: cast_nullable_to_non_nullable
as bool,pluginExtern: null == pluginExtern ? _self._pluginExtern : pluginExtern // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
