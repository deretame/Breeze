// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'download_task_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DownloadChapterTaskRef {

 String get chapterId; String get requestId; String get storageChapterId; String get logicalKey; String get title; int get order; Map<String, dynamic> get extern;
/// Create a copy of DownloadChapterTaskRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadChapterTaskRefCopyWith<DownloadChapterTaskRef> get copyWith => _$DownloadChapterTaskRefCopyWithImpl<DownloadChapterTaskRef>(this as DownloadChapterTaskRef, _$identity);

  /// Serializes this DownloadChapterTaskRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadChapterTaskRef&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.storageChapterId, storageChapterId) || other.storageChapterId == storageChapterId)&&(identical(other.logicalKey, logicalKey) || other.logicalKey == logicalKey)&&(identical(other.title, title) || other.title == title)&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other.extern, extern));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,chapterId,requestId,storageChapterId,logicalKey,title,order,const DeepCollectionEquality().hash(extern));

@override
String toString() {
  return 'DownloadChapterTaskRef(chapterId: $chapterId, requestId: $requestId, storageChapterId: $storageChapterId, logicalKey: $logicalKey, title: $title, order: $order, extern: $extern)';
}


}

/// @nodoc
abstract mixin class $DownloadChapterTaskRefCopyWith<$Res>  {
  factory $DownloadChapterTaskRefCopyWith(DownloadChapterTaskRef value, $Res Function(DownloadChapterTaskRef) _then) = _$DownloadChapterTaskRefCopyWithImpl;
@useResult
$Res call({
 String chapterId, String requestId, String storageChapterId, String logicalKey, String title, int order, Map<String, dynamic> extern
});




}
/// @nodoc
class _$DownloadChapterTaskRefCopyWithImpl<$Res>
    implements $DownloadChapterTaskRefCopyWith<$Res> {
  _$DownloadChapterTaskRefCopyWithImpl(this._self, this._then);

  final DownloadChapterTaskRef _self;
  final $Res Function(DownloadChapterTaskRef) _then;

/// Create a copy of DownloadChapterTaskRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? chapterId = null,Object? requestId = null,Object? storageChapterId = null,Object? logicalKey = null,Object? title = null,Object? order = null,Object? extern = null,}) {
  return _then(_self.copyWith(
chapterId: null == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,storageChapterId: null == storageChapterId ? _self.storageChapterId : storageChapterId // ignore: cast_nullable_to_non_nullable
as String,logicalKey: null == logicalKey ? _self.logicalKey : logicalKey // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,extern: null == extern ? _self.extern : extern // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [DownloadChapterTaskRef].
extension DownloadChapterTaskRefPatterns on DownloadChapterTaskRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadChapterTaskRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadChapterTaskRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadChapterTaskRef value)  $default,){
final _that = this;
switch (_that) {
case _DownloadChapterTaskRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadChapterTaskRef value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadChapterTaskRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String chapterId,  String requestId,  String storageChapterId,  String logicalKey,  String title,  int order,  Map<String, dynamic> extern)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadChapterTaskRef() when $default != null:
return $default(_that.chapterId,_that.requestId,_that.storageChapterId,_that.logicalKey,_that.title,_that.order,_that.extern);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String chapterId,  String requestId,  String storageChapterId,  String logicalKey,  String title,  int order,  Map<String, dynamic> extern)  $default,) {final _that = this;
switch (_that) {
case _DownloadChapterTaskRef():
return $default(_that.chapterId,_that.requestId,_that.storageChapterId,_that.logicalKey,_that.title,_that.order,_that.extern);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String chapterId,  String requestId,  String storageChapterId,  String logicalKey,  String title,  int order,  Map<String, dynamic> extern)?  $default,) {final _that = this;
switch (_that) {
case _DownloadChapterTaskRef() when $default != null:
return $default(_that.chapterId,_that.requestId,_that.storageChapterId,_that.logicalKey,_that.title,_that.order,_that.extern);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _DownloadChapterTaskRef implements DownloadChapterTaskRef {
  const _DownloadChapterTaskRef({this.chapterId = '', this.requestId = '', this.storageChapterId = '', this.logicalKey = '', this.title = '', this.order = 0, final  Map<String, dynamic> extern = const <String, dynamic>{}}): _extern = extern;
  factory _DownloadChapterTaskRef.fromJson(Map<String, dynamic> json) => _$DownloadChapterTaskRefFromJson(json);

@override@JsonKey() final  String chapterId;
@override@JsonKey() final  String requestId;
@override@JsonKey() final  String storageChapterId;
@override@JsonKey() final  String logicalKey;
@override@JsonKey() final  String title;
@override@JsonKey() final  int order;
 final  Map<String, dynamic> _extern;
@override@JsonKey() Map<String, dynamic> get extern {
  if (_extern is EqualUnmodifiableMapView) return _extern;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extern);
}


/// Create a copy of DownloadChapterTaskRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadChapterTaskRefCopyWith<_DownloadChapterTaskRef> get copyWith => __$DownloadChapterTaskRefCopyWithImpl<_DownloadChapterTaskRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DownloadChapterTaskRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadChapterTaskRef&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.storageChapterId, storageChapterId) || other.storageChapterId == storageChapterId)&&(identical(other.logicalKey, logicalKey) || other.logicalKey == logicalKey)&&(identical(other.title, title) || other.title == title)&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other._extern, _extern));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,chapterId,requestId,storageChapterId,logicalKey,title,order,const DeepCollectionEquality().hash(_extern));

@override
String toString() {
  return 'DownloadChapterTaskRef(chapterId: $chapterId, requestId: $requestId, storageChapterId: $storageChapterId, logicalKey: $logicalKey, title: $title, order: $order, extern: $extern)';
}


}

/// @nodoc
abstract mixin class _$DownloadChapterTaskRefCopyWith<$Res> implements $DownloadChapterTaskRefCopyWith<$Res> {
  factory _$DownloadChapterTaskRefCopyWith(_DownloadChapterTaskRef value, $Res Function(_DownloadChapterTaskRef) _then) = __$DownloadChapterTaskRefCopyWithImpl;
@override @useResult
$Res call({
 String chapterId, String requestId, String storageChapterId, String logicalKey, String title, int order, Map<String, dynamic> extern
});




}
/// @nodoc
class __$DownloadChapterTaskRefCopyWithImpl<$Res>
    implements _$DownloadChapterTaskRefCopyWith<$Res> {
  __$DownloadChapterTaskRefCopyWithImpl(this._self, this._then);

  final _DownloadChapterTaskRef _self;
  final $Res Function(_DownloadChapterTaskRef) _then;

/// Create a copy of DownloadChapterTaskRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? chapterId = null,Object? requestId = null,Object? storageChapterId = null,Object? logicalKey = null,Object? title = null,Object? order = null,Object? extern = null,}) {
  return _then(_DownloadChapterTaskRef(
chapterId: null == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,storageChapterId: null == storageChapterId ? _self.storageChapterId : storageChapterId // ignore: cast_nullable_to_non_nullable
as String,logicalKey: null == logicalKey ? _self.logicalKey : logicalKey // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,extern: null == extern ? _self._extern : extern // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$DownloadTaskJson {

 String get from; String get comicId; String get comicName; List<DownloadChapterTaskRef> get chapterRefs;
/// Create a copy of DownloadTaskJson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadTaskJsonCopyWith<DownloadTaskJson> get copyWith => _$DownloadTaskJsonCopyWithImpl<DownloadTaskJson>(this as DownloadTaskJson, _$identity);

  /// Serializes this DownloadTaskJson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadTaskJson&&(identical(other.from, from) || other.from == from)&&(identical(other.comicId, comicId) || other.comicId == comicId)&&(identical(other.comicName, comicName) || other.comicName == comicName)&&const DeepCollectionEquality().equals(other.chapterRefs, chapterRefs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,comicId,comicName,const DeepCollectionEquality().hash(chapterRefs));

@override
String toString() {
  return 'DownloadTaskJson(from: $from, comicId: $comicId, comicName: $comicName, chapterRefs: $chapterRefs)';
}


}

/// @nodoc
abstract mixin class $DownloadTaskJsonCopyWith<$Res>  {
  factory $DownloadTaskJsonCopyWith(DownloadTaskJson value, $Res Function(DownloadTaskJson) _then) = _$DownloadTaskJsonCopyWithImpl;
@useResult
$Res call({
 String from, String comicId, String comicName, List<DownloadChapterTaskRef> chapterRefs
});




}
/// @nodoc
class _$DownloadTaskJsonCopyWithImpl<$Res>
    implements $DownloadTaskJsonCopyWith<$Res> {
  _$DownloadTaskJsonCopyWithImpl(this._self, this._then);

  final DownloadTaskJson _self;
  final $Res Function(DownloadTaskJson) _then;

/// Create a copy of DownloadTaskJson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? comicId = null,Object? comicName = null,Object? chapterRefs = null,}) {
  return _then(_self.copyWith(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,comicId: null == comicId ? _self.comicId : comicId // ignore: cast_nullable_to_non_nullable
as String,comicName: null == comicName ? _self.comicName : comicName // ignore: cast_nullable_to_non_nullable
as String,chapterRefs: null == chapterRefs ? _self.chapterRefs : chapterRefs // ignore: cast_nullable_to_non_nullable
as List<DownloadChapterTaskRef>,
  ));
}

}


/// Adds pattern-matching-related methods to [DownloadTaskJson].
extension DownloadTaskJsonPatterns on DownloadTaskJson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadTaskJson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadTaskJson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadTaskJson value)  $default,){
final _that = this;
switch (_that) {
case _DownloadTaskJson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadTaskJson value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadTaskJson() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String from,  String comicId,  String comicName,  List<DownloadChapterTaskRef> chapterRefs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadTaskJson() when $default != null:
return $default(_that.from,_that.comicId,_that.comicName,_that.chapterRefs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String from,  String comicId,  String comicName,  List<DownloadChapterTaskRef> chapterRefs)  $default,) {final _that = this;
switch (_that) {
case _DownloadTaskJson():
return $default(_that.from,_that.comicId,_that.comicName,_that.chapterRefs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String from,  String comicId,  String comicName,  List<DownloadChapterTaskRef> chapterRefs)?  $default,) {final _that = this;
switch (_that) {
case _DownloadTaskJson() when $default != null:
return $default(_that.from,_that.comicId,_that.comicName,_that.chapterRefs);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _DownloadTaskJson implements DownloadTaskJson {
  const _DownloadTaskJson({required this.from, required this.comicId, required this.comicName, required this.chapterRefs});
  factory _DownloadTaskJson.fromJson(Map<String, dynamic> json) => _$DownloadTaskJsonFromJson(json);

@override final  String from;
@override final  String comicId;
@override final  String comicName;
@override final  List<DownloadChapterTaskRef> chapterRefs;

/// Create a copy of DownloadTaskJson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadTaskJsonCopyWith<_DownloadTaskJson> get copyWith => __$DownloadTaskJsonCopyWithImpl<_DownloadTaskJson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DownloadTaskJsonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadTaskJson&&(identical(other.from, from) || other.from == from)&&(identical(other.comicId, comicId) || other.comicId == comicId)&&(identical(other.comicName, comicName) || other.comicName == comicName)&&const DeepCollectionEquality().equals(other.chapterRefs, chapterRefs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,comicId,comicName,const DeepCollectionEquality().hash(chapterRefs));

@override
String toString() {
  return 'DownloadTaskJson(from: $from, comicId: $comicId, comicName: $comicName, chapterRefs: $chapterRefs)';
}


}

/// @nodoc
abstract mixin class _$DownloadTaskJsonCopyWith<$Res> implements $DownloadTaskJsonCopyWith<$Res> {
  factory _$DownloadTaskJsonCopyWith(_DownloadTaskJson value, $Res Function(_DownloadTaskJson) _then) = __$DownloadTaskJsonCopyWithImpl;
@override @useResult
$Res call({
 String from, String comicId, String comicName, List<DownloadChapterTaskRef> chapterRefs
});




}
/// @nodoc
class __$DownloadTaskJsonCopyWithImpl<$Res>
    implements _$DownloadTaskJsonCopyWith<$Res> {
  __$DownloadTaskJsonCopyWithImpl(this._self, this._then);

  final _DownloadTaskJson _self;
  final $Res Function(_DownloadTaskJson) _then;

/// Create a copy of DownloadTaskJson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? comicId = null,Object? comicName = null,Object? chapterRefs = null,}) {
  return _then(_DownloadTaskJson(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,comicId: null == comicId ? _self.comicId : comicId // ignore: cast_nullable_to_non_nullable
as String,comicName: null == comicName ? _self.comicName : comicName // ignore: cast_nullable_to_non_nullable
as String,chapterRefs: null == chapterRefs ? _self.chapterRefs : chapterRefs // ignore: cast_nullable_to_non_nullable
as List<DownloadChapterTaskRef>,
  ));
}


}

// dart format on
