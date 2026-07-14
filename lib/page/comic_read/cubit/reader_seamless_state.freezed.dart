// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reader_seamless_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReaderSeamlessState {

 List<SeamlessChapter> get loadedChapters; Map<int, SeamlessTransitionStatus> get transitionStatusByNextOrder; Set<int> get visibleTransitionNextOrders; Set<int> get loadingChapterOrders; Set<int> get prefetchingChapterOrders; Map<int, NormalComicEpInfo> get prefetchedChapterInfoByOrder; int? get currentChapterOrder; int get currentChapterStartSlot; int get currentChapterSlotCount;
/// Create a copy of ReaderSeamlessState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReaderSeamlessStateCopyWith<ReaderSeamlessState> get copyWith => _$ReaderSeamlessStateCopyWithImpl<ReaderSeamlessState>(this as ReaderSeamlessState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderSeamlessState&&const DeepCollectionEquality().equals(other.loadedChapters, loadedChapters)&&const DeepCollectionEquality().equals(other.transitionStatusByNextOrder, transitionStatusByNextOrder)&&const DeepCollectionEquality().equals(other.visibleTransitionNextOrders, visibleTransitionNextOrders)&&const DeepCollectionEquality().equals(other.loadingChapterOrders, loadingChapterOrders)&&const DeepCollectionEquality().equals(other.prefetchingChapterOrders, prefetchingChapterOrders)&&const DeepCollectionEquality().equals(other.prefetchedChapterInfoByOrder, prefetchedChapterInfoByOrder)&&(identical(other.currentChapterOrder, currentChapterOrder) || other.currentChapterOrder == currentChapterOrder)&&(identical(other.currentChapterStartSlot, currentChapterStartSlot) || other.currentChapterStartSlot == currentChapterStartSlot)&&(identical(other.currentChapterSlotCount, currentChapterSlotCount) || other.currentChapterSlotCount == currentChapterSlotCount));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(loadedChapters),const DeepCollectionEquality().hash(transitionStatusByNextOrder),const DeepCollectionEquality().hash(visibleTransitionNextOrders),const DeepCollectionEquality().hash(loadingChapterOrders),const DeepCollectionEquality().hash(prefetchingChapterOrders),const DeepCollectionEquality().hash(prefetchedChapterInfoByOrder),currentChapterOrder,currentChapterStartSlot,currentChapterSlotCount);

@override
String toString() {
  return 'ReaderSeamlessState(loadedChapters: $loadedChapters, transitionStatusByNextOrder: $transitionStatusByNextOrder, visibleTransitionNextOrders: $visibleTransitionNextOrders, loadingChapterOrders: $loadingChapterOrders, prefetchingChapterOrders: $prefetchingChapterOrders, prefetchedChapterInfoByOrder: $prefetchedChapterInfoByOrder, currentChapterOrder: $currentChapterOrder, currentChapterStartSlot: $currentChapterStartSlot, currentChapterSlotCount: $currentChapterSlotCount)';
}


}

/// @nodoc
abstract mixin class $ReaderSeamlessStateCopyWith<$Res>  {
  factory $ReaderSeamlessStateCopyWith(ReaderSeamlessState value, $Res Function(ReaderSeamlessState) _then) = _$ReaderSeamlessStateCopyWithImpl;
@useResult
$Res call({
 List<SeamlessChapter> loadedChapters, Map<int, SeamlessTransitionStatus> transitionStatusByNextOrder, Set<int> visibleTransitionNextOrders, Set<int> loadingChapterOrders, Set<int> prefetchingChapterOrders, Map<int, NormalComicEpInfo> prefetchedChapterInfoByOrder, int? currentChapterOrder, int currentChapterStartSlot, int currentChapterSlotCount
});




}
/// @nodoc
class _$ReaderSeamlessStateCopyWithImpl<$Res>
    implements $ReaderSeamlessStateCopyWith<$Res> {
  _$ReaderSeamlessStateCopyWithImpl(this._self, this._then);

  final ReaderSeamlessState _self;
  final $Res Function(ReaderSeamlessState) _then;

/// Create a copy of ReaderSeamlessState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loadedChapters = null,Object? transitionStatusByNextOrder = null,Object? visibleTransitionNextOrders = null,Object? loadingChapterOrders = null,Object? prefetchingChapterOrders = null,Object? prefetchedChapterInfoByOrder = null,Object? currentChapterOrder = freezed,Object? currentChapterStartSlot = null,Object? currentChapterSlotCount = null,}) {
  return _then(_self.copyWith(
loadedChapters: null == loadedChapters ? _self.loadedChapters : loadedChapters // ignore: cast_nullable_to_non_nullable
as List<SeamlessChapter>,transitionStatusByNextOrder: null == transitionStatusByNextOrder ? _self.transitionStatusByNextOrder : transitionStatusByNextOrder // ignore: cast_nullable_to_non_nullable
as Map<int, SeamlessTransitionStatus>,visibleTransitionNextOrders: null == visibleTransitionNextOrders ? _self.visibleTransitionNextOrders : visibleTransitionNextOrders // ignore: cast_nullable_to_non_nullable
as Set<int>,loadingChapterOrders: null == loadingChapterOrders ? _self.loadingChapterOrders : loadingChapterOrders // ignore: cast_nullable_to_non_nullable
as Set<int>,prefetchingChapterOrders: null == prefetchingChapterOrders ? _self.prefetchingChapterOrders : prefetchingChapterOrders // ignore: cast_nullable_to_non_nullable
as Set<int>,prefetchedChapterInfoByOrder: null == prefetchedChapterInfoByOrder ? _self.prefetchedChapterInfoByOrder : prefetchedChapterInfoByOrder // ignore: cast_nullable_to_non_nullable
as Map<int, NormalComicEpInfo>,currentChapterOrder: freezed == currentChapterOrder ? _self.currentChapterOrder : currentChapterOrder // ignore: cast_nullable_to_non_nullable
as int?,currentChapterStartSlot: null == currentChapterStartSlot ? _self.currentChapterStartSlot : currentChapterStartSlot // ignore: cast_nullable_to_non_nullable
as int,currentChapterSlotCount: null == currentChapterSlotCount ? _self.currentChapterSlotCount : currentChapterSlotCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ReaderSeamlessState].
extension ReaderSeamlessStatePatterns on ReaderSeamlessState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReaderSeamlessState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReaderSeamlessState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReaderSeamlessState value)  $default,){
final _that = this;
switch (_that) {
case _ReaderSeamlessState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReaderSeamlessState value)?  $default,){
final _that = this;
switch (_that) {
case _ReaderSeamlessState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SeamlessChapter> loadedChapters,  Map<int, SeamlessTransitionStatus> transitionStatusByNextOrder,  Set<int> visibleTransitionNextOrders,  Set<int> loadingChapterOrders,  Set<int> prefetchingChapterOrders,  Map<int, NormalComicEpInfo> prefetchedChapterInfoByOrder,  int? currentChapterOrder,  int currentChapterStartSlot,  int currentChapterSlotCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReaderSeamlessState() when $default != null:
return $default(_that.loadedChapters,_that.transitionStatusByNextOrder,_that.visibleTransitionNextOrders,_that.loadingChapterOrders,_that.prefetchingChapterOrders,_that.prefetchedChapterInfoByOrder,_that.currentChapterOrder,_that.currentChapterStartSlot,_that.currentChapterSlotCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SeamlessChapter> loadedChapters,  Map<int, SeamlessTransitionStatus> transitionStatusByNextOrder,  Set<int> visibleTransitionNextOrders,  Set<int> loadingChapterOrders,  Set<int> prefetchingChapterOrders,  Map<int, NormalComicEpInfo> prefetchedChapterInfoByOrder,  int? currentChapterOrder,  int currentChapterStartSlot,  int currentChapterSlotCount)  $default,) {final _that = this;
switch (_that) {
case _ReaderSeamlessState():
return $default(_that.loadedChapters,_that.transitionStatusByNextOrder,_that.visibleTransitionNextOrders,_that.loadingChapterOrders,_that.prefetchingChapterOrders,_that.prefetchedChapterInfoByOrder,_that.currentChapterOrder,_that.currentChapterStartSlot,_that.currentChapterSlotCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SeamlessChapter> loadedChapters,  Map<int, SeamlessTransitionStatus> transitionStatusByNextOrder,  Set<int> visibleTransitionNextOrders,  Set<int> loadingChapterOrders,  Set<int> prefetchingChapterOrders,  Map<int, NormalComicEpInfo> prefetchedChapterInfoByOrder,  int? currentChapterOrder,  int currentChapterStartSlot,  int currentChapterSlotCount)?  $default,) {final _that = this;
switch (_that) {
case _ReaderSeamlessState() when $default != null:
return $default(_that.loadedChapters,_that.transitionStatusByNextOrder,_that.visibleTransitionNextOrders,_that.loadingChapterOrders,_that.prefetchingChapterOrders,_that.prefetchedChapterInfoByOrder,_that.currentChapterOrder,_that.currentChapterStartSlot,_that.currentChapterSlotCount);case _:
  return null;

}
}

}

/// @nodoc


class _ReaderSeamlessState implements ReaderSeamlessState {
  const _ReaderSeamlessState({final  List<SeamlessChapter> loadedChapters = const <SeamlessChapter>[], final  Map<int, SeamlessTransitionStatus> transitionStatusByNextOrder = const <int, SeamlessTransitionStatus>{}, final  Set<int> visibleTransitionNextOrders = const <int>{}, final  Set<int> loadingChapterOrders = const <int>{}, final  Set<int> prefetchingChapterOrders = const <int>{}, final  Map<int, NormalComicEpInfo> prefetchedChapterInfoByOrder = const <int, NormalComicEpInfo>{}, this.currentChapterOrder, this.currentChapterStartSlot = 0, this.currentChapterSlotCount = 0}): _loadedChapters = loadedChapters,_transitionStatusByNextOrder = transitionStatusByNextOrder,_visibleTransitionNextOrders = visibleTransitionNextOrders,_loadingChapterOrders = loadingChapterOrders,_prefetchingChapterOrders = prefetchingChapterOrders,_prefetchedChapterInfoByOrder = prefetchedChapterInfoByOrder;
  

 final  List<SeamlessChapter> _loadedChapters;
@override@JsonKey() List<SeamlessChapter> get loadedChapters {
  if (_loadedChapters is EqualUnmodifiableListView) return _loadedChapters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_loadedChapters);
}

 final  Map<int, SeamlessTransitionStatus> _transitionStatusByNextOrder;
@override@JsonKey() Map<int, SeamlessTransitionStatus> get transitionStatusByNextOrder {
  if (_transitionStatusByNextOrder is EqualUnmodifiableMapView) return _transitionStatusByNextOrder;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_transitionStatusByNextOrder);
}

 final  Set<int> _visibleTransitionNextOrders;
@override@JsonKey() Set<int> get visibleTransitionNextOrders {
  if (_visibleTransitionNextOrders is EqualUnmodifiableSetView) return _visibleTransitionNextOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_visibleTransitionNextOrders);
}

 final  Set<int> _loadingChapterOrders;
@override@JsonKey() Set<int> get loadingChapterOrders {
  if (_loadingChapterOrders is EqualUnmodifiableSetView) return _loadingChapterOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_loadingChapterOrders);
}

 final  Set<int> _prefetchingChapterOrders;
@override@JsonKey() Set<int> get prefetchingChapterOrders {
  if (_prefetchingChapterOrders is EqualUnmodifiableSetView) return _prefetchingChapterOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_prefetchingChapterOrders);
}

 final  Map<int, NormalComicEpInfo> _prefetchedChapterInfoByOrder;
@override@JsonKey() Map<int, NormalComicEpInfo> get prefetchedChapterInfoByOrder {
  if (_prefetchedChapterInfoByOrder is EqualUnmodifiableMapView) return _prefetchedChapterInfoByOrder;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_prefetchedChapterInfoByOrder);
}

@override final  int? currentChapterOrder;
@override@JsonKey() final  int currentChapterStartSlot;
@override@JsonKey() final  int currentChapterSlotCount;

/// Create a copy of ReaderSeamlessState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReaderSeamlessStateCopyWith<_ReaderSeamlessState> get copyWith => __$ReaderSeamlessStateCopyWithImpl<_ReaderSeamlessState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReaderSeamlessState&&const DeepCollectionEquality().equals(other._loadedChapters, _loadedChapters)&&const DeepCollectionEquality().equals(other._transitionStatusByNextOrder, _transitionStatusByNextOrder)&&const DeepCollectionEquality().equals(other._visibleTransitionNextOrders, _visibleTransitionNextOrders)&&const DeepCollectionEquality().equals(other._loadingChapterOrders, _loadingChapterOrders)&&const DeepCollectionEquality().equals(other._prefetchingChapterOrders, _prefetchingChapterOrders)&&const DeepCollectionEquality().equals(other._prefetchedChapterInfoByOrder, _prefetchedChapterInfoByOrder)&&(identical(other.currentChapterOrder, currentChapterOrder) || other.currentChapterOrder == currentChapterOrder)&&(identical(other.currentChapterStartSlot, currentChapterStartSlot) || other.currentChapterStartSlot == currentChapterStartSlot)&&(identical(other.currentChapterSlotCount, currentChapterSlotCount) || other.currentChapterSlotCount == currentChapterSlotCount));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_loadedChapters),const DeepCollectionEquality().hash(_transitionStatusByNextOrder),const DeepCollectionEquality().hash(_visibleTransitionNextOrders),const DeepCollectionEquality().hash(_loadingChapterOrders),const DeepCollectionEquality().hash(_prefetchingChapterOrders),const DeepCollectionEquality().hash(_prefetchedChapterInfoByOrder),currentChapterOrder,currentChapterStartSlot,currentChapterSlotCount);

@override
String toString() {
  return 'ReaderSeamlessState(loadedChapters: $loadedChapters, transitionStatusByNextOrder: $transitionStatusByNextOrder, visibleTransitionNextOrders: $visibleTransitionNextOrders, loadingChapterOrders: $loadingChapterOrders, prefetchingChapterOrders: $prefetchingChapterOrders, prefetchedChapterInfoByOrder: $prefetchedChapterInfoByOrder, currentChapterOrder: $currentChapterOrder, currentChapterStartSlot: $currentChapterStartSlot, currentChapterSlotCount: $currentChapterSlotCount)';
}


}

/// @nodoc
abstract mixin class _$ReaderSeamlessStateCopyWith<$Res> implements $ReaderSeamlessStateCopyWith<$Res> {
  factory _$ReaderSeamlessStateCopyWith(_ReaderSeamlessState value, $Res Function(_ReaderSeamlessState) _then) = __$ReaderSeamlessStateCopyWithImpl;
@override @useResult
$Res call({
 List<SeamlessChapter> loadedChapters, Map<int, SeamlessTransitionStatus> transitionStatusByNextOrder, Set<int> visibleTransitionNextOrders, Set<int> loadingChapterOrders, Set<int> prefetchingChapterOrders, Map<int, NormalComicEpInfo> prefetchedChapterInfoByOrder, int? currentChapterOrder, int currentChapterStartSlot, int currentChapterSlotCount
});




}
/// @nodoc
class __$ReaderSeamlessStateCopyWithImpl<$Res>
    implements _$ReaderSeamlessStateCopyWith<$Res> {
  __$ReaderSeamlessStateCopyWithImpl(this._self, this._then);

  final _ReaderSeamlessState _self;
  final $Res Function(_ReaderSeamlessState) _then;

/// Create a copy of ReaderSeamlessState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? loadedChapters = null,Object? transitionStatusByNextOrder = null,Object? visibleTransitionNextOrders = null,Object? loadingChapterOrders = null,Object? prefetchingChapterOrders = null,Object? prefetchedChapterInfoByOrder = null,Object? currentChapterOrder = freezed,Object? currentChapterStartSlot = null,Object? currentChapterSlotCount = null,}) {
  return _then(_ReaderSeamlessState(
loadedChapters: null == loadedChapters ? _self._loadedChapters : loadedChapters // ignore: cast_nullable_to_non_nullable
as List<SeamlessChapter>,transitionStatusByNextOrder: null == transitionStatusByNextOrder ? _self._transitionStatusByNextOrder : transitionStatusByNextOrder // ignore: cast_nullable_to_non_nullable
as Map<int, SeamlessTransitionStatus>,visibleTransitionNextOrders: null == visibleTransitionNextOrders ? _self._visibleTransitionNextOrders : visibleTransitionNextOrders // ignore: cast_nullable_to_non_nullable
as Set<int>,loadingChapterOrders: null == loadingChapterOrders ? _self._loadingChapterOrders : loadingChapterOrders // ignore: cast_nullable_to_non_nullable
as Set<int>,prefetchingChapterOrders: null == prefetchingChapterOrders ? _self._prefetchingChapterOrders : prefetchingChapterOrders // ignore: cast_nullable_to_non_nullable
as Set<int>,prefetchedChapterInfoByOrder: null == prefetchedChapterInfoByOrder ? _self._prefetchedChapterInfoByOrder : prefetchedChapterInfoByOrder // ignore: cast_nullable_to_non_nullable
as Map<int, NormalComicEpInfo>,currentChapterOrder: freezed == currentChapterOrder ? _self.currentChapterOrder : currentChapterOrder // ignore: cast_nullable_to_non_nullable
as int?,currentChapterStartSlot: null == currentChapterStartSlot ? _self.currentChapterStartSlot : currentChapterStartSlot // ignore: cast_nullable_to_non_nullable
as int,currentChapterSlotCount: null == currentChapterSlotCount ? _self.currentChapterSlotCount : currentChapterSlotCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
