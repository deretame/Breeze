// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comments_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommentsViewState {

 List<CommentItem> get topItems; List<CommentItem> get items; bool get loading; bool get loadingMore; bool get hasReachedMax; bool get canCommentComic; bool get canCommentReply; bool get posting; String get replyMode; int get page; String? get error; Set<String> get expandedIds; Map<String, List<CommentItem>> get replyItems; Map<String, bool> get replyLoading; Map<String, bool> get replyHasReachedMax; Map<String, int> get replyPage; String get noticeMessage; int get noticeId;
/// Create a copy of CommentsViewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentsViewStateCopyWith<CommentsViewState> get copyWith => _$CommentsViewStateCopyWithImpl<CommentsViewState>(this as CommentsViewState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentsViewState&&const DeepCollectionEquality().equals(other.topItems, topItems)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.hasReachedMax, hasReachedMax) || other.hasReachedMax == hasReachedMax)&&(identical(other.canCommentComic, canCommentComic) || other.canCommentComic == canCommentComic)&&(identical(other.canCommentReply, canCommentReply) || other.canCommentReply == canCommentReply)&&(identical(other.posting, posting) || other.posting == posting)&&(identical(other.replyMode, replyMode) || other.replyMode == replyMode)&&(identical(other.page, page) || other.page == page)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other.expandedIds, expandedIds)&&const DeepCollectionEquality().equals(other.replyItems, replyItems)&&const DeepCollectionEquality().equals(other.replyLoading, replyLoading)&&const DeepCollectionEquality().equals(other.replyHasReachedMax, replyHasReachedMax)&&const DeepCollectionEquality().equals(other.replyPage, replyPage)&&(identical(other.noticeMessage, noticeMessage) || other.noticeMessage == noticeMessage)&&(identical(other.noticeId, noticeId) || other.noticeId == noticeId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(topItems),const DeepCollectionEquality().hash(items),loading,loadingMore,hasReachedMax,canCommentComic,canCommentReply,posting,replyMode,page,error,const DeepCollectionEquality().hash(expandedIds),const DeepCollectionEquality().hash(replyItems),const DeepCollectionEquality().hash(replyLoading),const DeepCollectionEquality().hash(replyHasReachedMax),const DeepCollectionEquality().hash(replyPage),noticeMessage,noticeId);

@override
String toString() {
  return 'CommentsViewState(topItems: $topItems, items: $items, loading: $loading, loadingMore: $loadingMore, hasReachedMax: $hasReachedMax, canCommentComic: $canCommentComic, canCommentReply: $canCommentReply, posting: $posting, replyMode: $replyMode, page: $page, error: $error, expandedIds: $expandedIds, replyItems: $replyItems, replyLoading: $replyLoading, replyHasReachedMax: $replyHasReachedMax, replyPage: $replyPage, noticeMessage: $noticeMessage, noticeId: $noticeId)';
}


}

/// @nodoc
abstract mixin class $CommentsViewStateCopyWith<$Res>  {
  factory $CommentsViewStateCopyWith(CommentsViewState value, $Res Function(CommentsViewState) _then) = _$CommentsViewStateCopyWithImpl;
@useResult
$Res call({
 List<CommentItem> topItems, List<CommentItem> items, bool loading, bool loadingMore, bool hasReachedMax, bool canCommentComic, bool canCommentReply, bool posting, String replyMode, int page, String? error, Set<String> expandedIds, Map<String, List<CommentItem>> replyItems, Map<String, bool> replyLoading, Map<String, bool> replyHasReachedMax, Map<String, int> replyPage, String noticeMessage, int noticeId
});




}
/// @nodoc
class _$CommentsViewStateCopyWithImpl<$Res>
    implements $CommentsViewStateCopyWith<$Res> {
  _$CommentsViewStateCopyWithImpl(this._self, this._then);

  final CommentsViewState _self;
  final $Res Function(CommentsViewState) _then;

/// Create a copy of CommentsViewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? topItems = null,Object? items = null,Object? loading = null,Object? loadingMore = null,Object? hasReachedMax = null,Object? canCommentComic = null,Object? canCommentReply = null,Object? posting = null,Object? replyMode = null,Object? page = null,Object? error = freezed,Object? expandedIds = null,Object? replyItems = null,Object? replyLoading = null,Object? replyHasReachedMax = null,Object? replyPage = null,Object? noticeMessage = null,Object? noticeId = null,}) {
  return _then(_self.copyWith(
topItems: null == topItems ? _self.topItems : topItems // ignore: cast_nullable_to_non_nullable
as List<CommentItem>,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CommentItem>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,hasReachedMax: null == hasReachedMax ? _self.hasReachedMax : hasReachedMax // ignore: cast_nullable_to_non_nullable
as bool,canCommentComic: null == canCommentComic ? _self.canCommentComic : canCommentComic // ignore: cast_nullable_to_non_nullable
as bool,canCommentReply: null == canCommentReply ? _self.canCommentReply : canCommentReply // ignore: cast_nullable_to_non_nullable
as bool,posting: null == posting ? _self.posting : posting // ignore: cast_nullable_to_non_nullable
as bool,replyMode: null == replyMode ? _self.replyMode : replyMode // ignore: cast_nullable_to_non_nullable
as String,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,expandedIds: null == expandedIds ? _self.expandedIds : expandedIds // ignore: cast_nullable_to_non_nullable
as Set<String>,replyItems: null == replyItems ? _self.replyItems : replyItems // ignore: cast_nullable_to_non_nullable
as Map<String, List<CommentItem>>,replyLoading: null == replyLoading ? _self.replyLoading : replyLoading // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,replyHasReachedMax: null == replyHasReachedMax ? _self.replyHasReachedMax : replyHasReachedMax // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,replyPage: null == replyPage ? _self.replyPage : replyPage // ignore: cast_nullable_to_non_nullable
as Map<String, int>,noticeMessage: null == noticeMessage ? _self.noticeMessage : noticeMessage // ignore: cast_nullable_to_non_nullable
as String,noticeId: null == noticeId ? _self.noticeId : noticeId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentsViewState].
extension CommentsViewStatePatterns on CommentsViewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentsViewState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentsViewState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentsViewState value)  $default,){
final _that = this;
switch (_that) {
case _CommentsViewState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentsViewState value)?  $default,){
final _that = this;
switch (_that) {
case _CommentsViewState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CommentItem> topItems,  List<CommentItem> items,  bool loading,  bool loadingMore,  bool hasReachedMax,  bool canCommentComic,  bool canCommentReply,  bool posting,  String replyMode,  int page,  String? error,  Set<String> expandedIds,  Map<String, List<CommentItem>> replyItems,  Map<String, bool> replyLoading,  Map<String, bool> replyHasReachedMax,  Map<String, int> replyPage,  String noticeMessage,  int noticeId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentsViewState() when $default != null:
return $default(_that.topItems,_that.items,_that.loading,_that.loadingMore,_that.hasReachedMax,_that.canCommentComic,_that.canCommentReply,_that.posting,_that.replyMode,_that.page,_that.error,_that.expandedIds,_that.replyItems,_that.replyLoading,_that.replyHasReachedMax,_that.replyPage,_that.noticeMessage,_that.noticeId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CommentItem> topItems,  List<CommentItem> items,  bool loading,  bool loadingMore,  bool hasReachedMax,  bool canCommentComic,  bool canCommentReply,  bool posting,  String replyMode,  int page,  String? error,  Set<String> expandedIds,  Map<String, List<CommentItem>> replyItems,  Map<String, bool> replyLoading,  Map<String, bool> replyHasReachedMax,  Map<String, int> replyPage,  String noticeMessage,  int noticeId)  $default,) {final _that = this;
switch (_that) {
case _CommentsViewState():
return $default(_that.topItems,_that.items,_that.loading,_that.loadingMore,_that.hasReachedMax,_that.canCommentComic,_that.canCommentReply,_that.posting,_that.replyMode,_that.page,_that.error,_that.expandedIds,_that.replyItems,_that.replyLoading,_that.replyHasReachedMax,_that.replyPage,_that.noticeMessage,_that.noticeId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CommentItem> topItems,  List<CommentItem> items,  bool loading,  bool loadingMore,  bool hasReachedMax,  bool canCommentComic,  bool canCommentReply,  bool posting,  String replyMode,  int page,  String? error,  Set<String> expandedIds,  Map<String, List<CommentItem>> replyItems,  Map<String, bool> replyLoading,  Map<String, bool> replyHasReachedMax,  Map<String, int> replyPage,  String noticeMessage,  int noticeId)?  $default,) {final _that = this;
switch (_that) {
case _CommentsViewState() when $default != null:
return $default(_that.topItems,_that.items,_that.loading,_that.loadingMore,_that.hasReachedMax,_that.canCommentComic,_that.canCommentReply,_that.posting,_that.replyMode,_that.page,_that.error,_that.expandedIds,_that.replyItems,_that.replyLoading,_that.replyHasReachedMax,_that.replyPage,_that.noticeMessage,_that.noticeId);case _:
  return null;

}
}

}

/// @nodoc


class _CommentsViewState implements CommentsViewState {
  const _CommentsViewState({final  List<CommentItem> topItems = const <CommentItem>[], final  List<CommentItem> items = const <CommentItem>[], this.loading = false, this.loadingMore = false, this.hasReachedMax = false, this.canCommentComic = false, this.canCommentReply = false, this.posting = false, this.replyMode = 'lazy', this.page = 1, this.error, final  Set<String> expandedIds = const <String>{}, final  Map<String, List<CommentItem>> replyItems = const <String, List<CommentItem>>{}, final  Map<String, bool> replyLoading = const <String, bool>{}, final  Map<String, bool> replyHasReachedMax = const <String, bool>{}, final  Map<String, int> replyPage = const <String, int>{}, this.noticeMessage = '', this.noticeId = 0}): _topItems = topItems,_items = items,_expandedIds = expandedIds,_replyItems = replyItems,_replyLoading = replyLoading,_replyHasReachedMax = replyHasReachedMax,_replyPage = replyPage;
  

 final  List<CommentItem> _topItems;
@override@JsonKey() List<CommentItem> get topItems {
  if (_topItems is EqualUnmodifiableListView) return _topItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topItems);
}

 final  List<CommentItem> _items;
@override@JsonKey() List<CommentItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  bool loading;
@override@JsonKey() final  bool loadingMore;
@override@JsonKey() final  bool hasReachedMax;
@override@JsonKey() final  bool canCommentComic;
@override@JsonKey() final  bool canCommentReply;
@override@JsonKey() final  bool posting;
@override@JsonKey() final  String replyMode;
@override@JsonKey() final  int page;
@override final  String? error;
 final  Set<String> _expandedIds;
@override@JsonKey() Set<String> get expandedIds {
  if (_expandedIds is EqualUnmodifiableSetView) return _expandedIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_expandedIds);
}

 final  Map<String, List<CommentItem>> _replyItems;
@override@JsonKey() Map<String, List<CommentItem>> get replyItems {
  if (_replyItems is EqualUnmodifiableMapView) return _replyItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_replyItems);
}

 final  Map<String, bool> _replyLoading;
@override@JsonKey() Map<String, bool> get replyLoading {
  if (_replyLoading is EqualUnmodifiableMapView) return _replyLoading;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_replyLoading);
}

 final  Map<String, bool> _replyHasReachedMax;
@override@JsonKey() Map<String, bool> get replyHasReachedMax {
  if (_replyHasReachedMax is EqualUnmodifiableMapView) return _replyHasReachedMax;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_replyHasReachedMax);
}

 final  Map<String, int> _replyPage;
@override@JsonKey() Map<String, int> get replyPage {
  if (_replyPage is EqualUnmodifiableMapView) return _replyPage;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_replyPage);
}

@override@JsonKey() final  String noticeMessage;
@override@JsonKey() final  int noticeId;

/// Create a copy of CommentsViewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentsViewStateCopyWith<_CommentsViewState> get copyWith => __$CommentsViewStateCopyWithImpl<_CommentsViewState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentsViewState&&const DeepCollectionEquality().equals(other._topItems, _topItems)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.hasReachedMax, hasReachedMax) || other.hasReachedMax == hasReachedMax)&&(identical(other.canCommentComic, canCommentComic) || other.canCommentComic == canCommentComic)&&(identical(other.canCommentReply, canCommentReply) || other.canCommentReply == canCommentReply)&&(identical(other.posting, posting) || other.posting == posting)&&(identical(other.replyMode, replyMode) || other.replyMode == replyMode)&&(identical(other.page, page) || other.page == page)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other._expandedIds, _expandedIds)&&const DeepCollectionEquality().equals(other._replyItems, _replyItems)&&const DeepCollectionEquality().equals(other._replyLoading, _replyLoading)&&const DeepCollectionEquality().equals(other._replyHasReachedMax, _replyHasReachedMax)&&const DeepCollectionEquality().equals(other._replyPage, _replyPage)&&(identical(other.noticeMessage, noticeMessage) || other.noticeMessage == noticeMessage)&&(identical(other.noticeId, noticeId) || other.noticeId == noticeId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_topItems),const DeepCollectionEquality().hash(_items),loading,loadingMore,hasReachedMax,canCommentComic,canCommentReply,posting,replyMode,page,error,const DeepCollectionEquality().hash(_expandedIds),const DeepCollectionEquality().hash(_replyItems),const DeepCollectionEquality().hash(_replyLoading),const DeepCollectionEquality().hash(_replyHasReachedMax),const DeepCollectionEquality().hash(_replyPage),noticeMessage,noticeId);

@override
String toString() {
  return 'CommentsViewState(topItems: $topItems, items: $items, loading: $loading, loadingMore: $loadingMore, hasReachedMax: $hasReachedMax, canCommentComic: $canCommentComic, canCommentReply: $canCommentReply, posting: $posting, replyMode: $replyMode, page: $page, error: $error, expandedIds: $expandedIds, replyItems: $replyItems, replyLoading: $replyLoading, replyHasReachedMax: $replyHasReachedMax, replyPage: $replyPage, noticeMessage: $noticeMessage, noticeId: $noticeId)';
}


}

/// @nodoc
abstract mixin class _$CommentsViewStateCopyWith<$Res> implements $CommentsViewStateCopyWith<$Res> {
  factory _$CommentsViewStateCopyWith(_CommentsViewState value, $Res Function(_CommentsViewState) _then) = __$CommentsViewStateCopyWithImpl;
@override @useResult
$Res call({
 List<CommentItem> topItems, List<CommentItem> items, bool loading, bool loadingMore, bool hasReachedMax, bool canCommentComic, bool canCommentReply, bool posting, String replyMode, int page, String? error, Set<String> expandedIds, Map<String, List<CommentItem>> replyItems, Map<String, bool> replyLoading, Map<String, bool> replyHasReachedMax, Map<String, int> replyPage, String noticeMessage, int noticeId
});




}
/// @nodoc
class __$CommentsViewStateCopyWithImpl<$Res>
    implements _$CommentsViewStateCopyWith<$Res> {
  __$CommentsViewStateCopyWithImpl(this._self, this._then);

  final _CommentsViewState _self;
  final $Res Function(_CommentsViewState) _then;

/// Create a copy of CommentsViewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? topItems = null,Object? items = null,Object? loading = null,Object? loadingMore = null,Object? hasReachedMax = null,Object? canCommentComic = null,Object? canCommentReply = null,Object? posting = null,Object? replyMode = null,Object? page = null,Object? error = freezed,Object? expandedIds = null,Object? replyItems = null,Object? replyLoading = null,Object? replyHasReachedMax = null,Object? replyPage = null,Object? noticeMessage = null,Object? noticeId = null,}) {
  return _then(_CommentsViewState(
topItems: null == topItems ? _self._topItems : topItems // ignore: cast_nullable_to_non_nullable
as List<CommentItem>,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CommentItem>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,hasReachedMax: null == hasReachedMax ? _self.hasReachedMax : hasReachedMax // ignore: cast_nullable_to_non_nullable
as bool,canCommentComic: null == canCommentComic ? _self.canCommentComic : canCommentComic // ignore: cast_nullable_to_non_nullable
as bool,canCommentReply: null == canCommentReply ? _self.canCommentReply : canCommentReply // ignore: cast_nullable_to_non_nullable
as bool,posting: null == posting ? _self.posting : posting // ignore: cast_nullable_to_non_nullable
as bool,replyMode: null == replyMode ? _self.replyMode : replyMode // ignore: cast_nullable_to_non_nullable
as String,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,expandedIds: null == expandedIds ? _self._expandedIds : expandedIds // ignore: cast_nullable_to_non_nullable
as Set<String>,replyItems: null == replyItems ? _self._replyItems : replyItems // ignore: cast_nullable_to_non_nullable
as Map<String, List<CommentItem>>,replyLoading: null == replyLoading ? _self._replyLoading : replyLoading // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,replyHasReachedMax: null == replyHasReachedMax ? _self._replyHasReachedMax : replyHasReachedMax // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,replyPage: null == replyPage ? _self._replyPage : replyPage // ignore: cast_nullable_to_non_nullable
as Map<String, int>,noticeMessage: null == noticeMessage ? _self.noticeMessage : noticeMessage // ignore: cast_nullable_to_non_nullable
as String,noticeId: null == noticeId ? _self.noticeId : noticeId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
