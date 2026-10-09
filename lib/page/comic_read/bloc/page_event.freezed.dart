// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'page_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PageEvent {

 String get comicId; int get epsId; String get chapterId; String get requestId; String get storageChapterId; String get logicalKey; ChapterExtern get chapterExtern; String get from; ComicEntryType get type; dynamic get comicInfo;
/// Create a copy of PageEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageEventCopyWith<PageEvent> get copyWith => _$PageEventCopyWithImpl<PageEvent>(this as PageEvent, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PageEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageEvent&&(identical(other.comicId, _this.comicId) || other.comicId == _this.comicId)&&(identical(other.epsId, _this.epsId) || other.epsId == _this.epsId)&&(identical(other.chapterId, _this.chapterId) || other.chapterId == _this.chapterId)&&(identical(other.requestId, _this.requestId) || other.requestId == _this.requestId)&&(identical(other.storageChapterId, _this.storageChapterId) || other.storageChapterId == _this.storageChapterId)&&(identical(other.logicalKey, _this.logicalKey) || other.logicalKey == _this.logicalKey)&&const DeepCollectionEquality().equals(other.chapterExtern, _this.chapterExtern)&&(identical(other.from, _this.from) || other.from == _this.from)&&(identical(other.type, _this.type) || other.type == _this.type)&&const DeepCollectionEquality().equals(other.comicInfo, _this.comicInfo));
}


@override
int get hashCode {
  final _this = this as PageEvent;
  return Object.hash(runtimeType,_this.comicId,_this.epsId,_this.chapterId,_this.requestId,_this.storageChapterId,_this.logicalKey,const DeepCollectionEquality().hash(_this.chapterExtern),_this.from,_this.type,const DeepCollectionEquality().hash(_this.comicInfo));
}

@override
String toString() {
  final _this = this as PageEvent;
  return 'PageEvent(comicId: ${_this.comicId}, epsId: ${_this.epsId}, chapterId: ${_this.chapterId}, requestId: ${_this.requestId}, storageChapterId: ${_this.storageChapterId}, logicalKey: ${_this.logicalKey}, chapterExtern: ${_this.chapterExtern}, from: ${_this.from}, type: ${_this.type}, comicInfo: ${_this.comicInfo})';
}


}

/// @nodoc
abstract mixin class $PageEventCopyWith<$Res>  {
  factory $PageEventCopyWith(PageEvent value, $Res Function(PageEvent) _then) = _$PageEventCopyWithImpl;
@useResult
$Res call({
 String comicId, int epsId, String chapterId, String requestId, String storageChapterId, String logicalKey, ChapterExtern chapterExtern, String from, ComicEntryType type, dynamic comicInfo
});




}
/// @nodoc
class _$PageEventCopyWithImpl<$Res>
    implements $PageEventCopyWith<$Res> {
  _$PageEventCopyWithImpl(this._self, this._then);

  final PageEvent _self;
  final $Res Function(PageEvent) _then;

/// Create a copy of PageEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? comicId = null,Object? epsId = null,Object? chapterId = null,Object? requestId = null,Object? storageChapterId = null,Object? logicalKey = null,Object? chapterExtern = null,Object? from = null,Object? type = null,Object? comicInfo = freezed,}) {
  return _then(PageEvent(
null == comicId ? _self.comicId : comicId // ignore: cast_nullable_to_non_nullable
as String,null == epsId ? _self.epsId : epsId // ignore: cast_nullable_to_non_nullable
as int,null == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String,null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,null == storageChapterId ? _self.storageChapterId : storageChapterId // ignore: cast_nullable_to_non_nullable
as String,null == logicalKey ? _self.logicalKey : logicalKey // ignore: cast_nullable_to_non_nullable
as String,null == chapterExtern ? _self.chapterExtern : chapterExtern // ignore: cast_nullable_to_non_nullable
as ChapterExtern,null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ComicEntryType,comicInfo: freezed == comicInfo ? _self.comicInfo : comicInfo // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}

}


/// Adds pattern-matching-related methods to [PageEvent].
extension PageEventPatterns on PageEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PageEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PageEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PageEvent value)  $default,){
final _that = this;
switch (_that) {
case _PageEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PageEvent value)?  $default,){
final _that = this;
switch (_that) {
case _PageEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String comicId,  int epsId,  String chapterId,  String requestId,  String storageChapterId,  String logicalKey,  ChapterExtern chapterExtern,  String from,  ComicEntryType type,  dynamic comicInfo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PageEvent() when $default != null:
return $default(_that.comicId,_that.epsId,_that.chapterId,_that.requestId,_that.storageChapterId,_that.logicalKey,_that.chapterExtern,_that.from,_that.type,_that.comicInfo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String comicId,  int epsId,  String chapterId,  String requestId,  String storageChapterId,  String logicalKey,  ChapterExtern chapterExtern,  String from,  ComicEntryType type,  dynamic comicInfo)  $default,) {final _that = this;
switch (_that) {
case _PageEvent():
return $default(_that.comicId,_that.epsId,_that.chapterId,_that.requestId,_that.storageChapterId,_that.logicalKey,_that.chapterExtern,_that.from,_that.type,_that.comicInfo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String comicId,  int epsId,  String chapterId,  String requestId,  String storageChapterId,  String logicalKey,  ChapterExtern chapterExtern,  String from,  ComicEntryType type,  dynamic comicInfo)?  $default,) {final _that = this;
switch (_that) {
case _PageEvent() when $default != null:
return $default(_that.comicId,_that.epsId,_that.chapterId,_that.requestId,_that.storageChapterId,_that.logicalKey,_that.chapterExtern,_that.from,_that.type,_that.comicInfo);case _:
  return null;

}
}

}

/// @nodoc


class _PageEvent implements PageEvent {
  const _PageEvent(this.comicId, this.epsId, this.chapterId, this.requestId, this.storageChapterId, this.logicalKey,  ChapterExtern chapterExtern, this.from, this.type, {this.comicInfo}): _chapterExtern = chapterExtern;
  

@override final  String comicId;
@override final  int epsId;
@override final  String chapterId;
@override final  String requestId;
@override final  String storageChapterId;
@override final  String logicalKey;
 final  ChapterExtern _chapterExtern;
@override ChapterExtern get chapterExtern {
  if (_chapterExtern is EqualUnmodifiableMapView) return _chapterExtern;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_chapterExtern);
}

@override final  String from;
@override final  ComicEntryType type;
@override final  dynamic comicInfo;

/// Create a copy of PageEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageEventCopyWith<_PageEvent> get copyWith => __$PageEventCopyWithImpl<_PageEvent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PageEvent&&(identical(other.comicId, comicId) || other.comicId == comicId)&&(identical(other.epsId, epsId) || other.epsId == epsId)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.storageChapterId, storageChapterId) || other.storageChapterId == storageChapterId)&&(identical(other.logicalKey, logicalKey) || other.logicalKey == logicalKey)&&const DeepCollectionEquality().equals(other.chapterExtern, _chapterExtern)&&(identical(other.from, from) || other.from == from)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.comicInfo, comicInfo));
}


@override
int get hashCode {
    return Object.hash(runtimeType,comicId,epsId,chapterId,requestId,storageChapterId,logicalKey,const DeepCollectionEquality().hash(_chapterExtern),from,type,const DeepCollectionEquality().hash(comicInfo));
}

@override
String toString() {
    return 'PageEvent(comicId: $comicId, epsId: $epsId, chapterId: $chapterId, requestId: $requestId, storageChapterId: $storageChapterId, logicalKey: $logicalKey, chapterExtern: $chapterExtern, from: $from, type: $type, comicInfo: $comicInfo)';
}


}

/// @nodoc
abstract mixin class _$PageEventCopyWith<$Res> implements $PageEventCopyWith<$Res> {
  factory _$PageEventCopyWith(_PageEvent value, $Res Function(_PageEvent) _then) = __$PageEventCopyWithImpl;
@override @useResult
$Res call({
 String comicId, int epsId, String chapterId, String requestId, String storageChapterId, String logicalKey, ChapterExtern chapterExtern, String from, ComicEntryType type, dynamic comicInfo
});




}
/// @nodoc
class __$PageEventCopyWithImpl<$Res>
    implements _$PageEventCopyWith<$Res> {
  __$PageEventCopyWithImpl(this._self, this._then);

  final _PageEvent _self;
  final $Res Function(_PageEvent) _then;

/// Create a copy of PageEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? comicId = null,Object? epsId = null,Object? chapterId = null,Object? requestId = null,Object? storageChapterId = null,Object? logicalKey = null,Object? chapterExtern = null,Object? from = null,Object? type = null,Object? comicInfo = freezed,}) {
  return _then(_PageEvent(
null == comicId ? _self.comicId : comicId // ignore: cast_nullable_to_non_nullable
as String,null == epsId ? _self.epsId : epsId // ignore: cast_nullable_to_non_nullable
as int,null == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String,null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,null == storageChapterId ? _self.storageChapterId : storageChapterId // ignore: cast_nullable_to_non_nullable
as String,null == logicalKey ? _self.logicalKey : logicalKey // ignore: cast_nullable_to_non_nullable
as String,null == chapterExtern ? _self._chapterExtern : chapterExtern // ignore: cast_nullable_to_non_nullable
as ChapterExtern,null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ComicEntryType,comicInfo: freezed == comicInfo ? _self.comicInfo : comicInfo // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}


}

// dart format on
