// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'download_task_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
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
  final _this = this as DownloadChapterTaskRef;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadChapterTaskRef&&(identical(other.chapterId, _this.chapterId) || other.chapterId == _this.chapterId)&&(identical(other.requestId, _this.requestId) || other.requestId == _this.requestId)&&(identical(other.storageChapterId, _this.storageChapterId) || other.storageChapterId == _this.storageChapterId)&&(identical(other.logicalKey, _this.logicalKey) || other.logicalKey == _this.logicalKey)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.order, _this.order) || other.order == _this.order)&&const DeepCollectionEquality().equals(other.extern, _this.extern));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DownloadChapterTaskRef;
  return Object.hash(runtimeType,_this.chapterId,_this.requestId,_this.storageChapterId,_this.logicalKey,_this.title,_this.order,const DeepCollectionEquality().hash(_this.extern));
}

@override
String toString() {
  final _this = this as DownloadChapterTaskRef;
  return 'DownloadChapterTaskRef(chapterId: ${_this.chapterId}, requestId: ${_this.requestId}, storageChapterId: ${_this.storageChapterId}, logicalKey: ${_this.logicalKey}, title: ${_this.title}, order: ${_this.order}, extern: ${_this.extern})';
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
  return _then(DownloadChapterTaskRef(
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
  const _DownloadChapterTaskRef({this.chapterId = '', this.requestId = '', this.storageChapterId = '', this.logicalKey = '', this.title = '', this.order = 0,  Map<String, dynamic> extern = const <String, dynamic>{}}): _extern = extern;
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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadChapterTaskRef&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.storageChapterId, storageChapterId) || other.storageChapterId == storageChapterId)&&(identical(other.logicalKey, logicalKey) || other.logicalKey == logicalKey)&&(identical(other.title, title) || other.title == title)&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other.extern, _extern));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,chapterId,requestId,storageChapterId,logicalKey,title,order,const DeepCollectionEquality().hash(_extern));
}

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

 String get from; String get comicId; String get comicName; DownloadChapterTaskRef get chapterRef; int get schemaVersion; String get stateCode; String get phaseCode; int get completedImages; int get reusedImages; int get totalImages; List<String> get imagePaths; int get attempt; String get lastErrorCode; String get lastErrorMessage;
/// Create a copy of DownloadTaskJson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadTaskJsonCopyWith<DownloadTaskJson> get copyWith => _$DownloadTaskJsonCopyWithImpl<DownloadTaskJson>(this as DownloadTaskJson, _$identity);

  /// Serializes this DownloadTaskJson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DownloadTaskJson;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadTaskJson&&(identical(other.from, _this.from) || other.from == _this.from)&&(identical(other.comicId, _this.comicId) || other.comicId == _this.comicId)&&(identical(other.comicName, _this.comicName) || other.comicName == _this.comicName)&&(identical(other.chapterRef, _this.chapterRef) || other.chapterRef == _this.chapterRef)&&(identical(other.schemaVersion, _this.schemaVersion) || other.schemaVersion == _this.schemaVersion)&&(identical(other.stateCode, _this.stateCode) || other.stateCode == _this.stateCode)&&(identical(other.phaseCode, _this.phaseCode) || other.phaseCode == _this.phaseCode)&&(identical(other.completedImages, _this.completedImages) || other.completedImages == _this.completedImages)&&(identical(other.reusedImages, _this.reusedImages) || other.reusedImages == _this.reusedImages)&&(identical(other.totalImages, _this.totalImages) || other.totalImages == _this.totalImages)&&const DeepCollectionEquality().equals(other.imagePaths, _this.imagePaths)&&(identical(other.attempt, _this.attempt) || other.attempt == _this.attempt)&&(identical(other.lastErrorCode, _this.lastErrorCode) || other.lastErrorCode == _this.lastErrorCode)&&(identical(other.lastErrorMessage, _this.lastErrorMessage) || other.lastErrorMessage == _this.lastErrorMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DownloadTaskJson;
  return Object.hash(runtimeType,_this.from,_this.comicId,_this.comicName,_this.chapterRef,_this.schemaVersion,_this.stateCode,_this.phaseCode,_this.completedImages,_this.reusedImages,_this.totalImages,const DeepCollectionEquality().hash(_this.imagePaths),_this.attempt,_this.lastErrorCode,_this.lastErrorMessage);
}

@override
String toString() {
  final _this = this as DownloadTaskJson;
  return 'DownloadTaskJson(from: ${_this.from}, comicId: ${_this.comicId}, comicName: ${_this.comicName}, chapterRef: ${_this.chapterRef}, schemaVersion: ${_this.schemaVersion}, stateCode: ${_this.stateCode}, phaseCode: ${_this.phaseCode}, completedImages: ${_this.completedImages}, reusedImages: ${_this.reusedImages}, totalImages: ${_this.totalImages}, imagePaths: ${_this.imagePaths}, attempt: ${_this.attempt}, lastErrorCode: ${_this.lastErrorCode}, lastErrorMessage: ${_this.lastErrorMessage})';
}


}

/// @nodoc
abstract mixin class $DownloadTaskJsonCopyWith<$Res>  {
  factory $DownloadTaskJsonCopyWith(DownloadTaskJson value, $Res Function(DownloadTaskJson) _then) = _$DownloadTaskJsonCopyWithImpl;
@useResult
$Res call({
 String from, String comicId, String comicName, DownloadChapterTaskRef chapterRef, int schemaVersion, String stateCode, String phaseCode, int completedImages, int reusedImages, int totalImages, List<String> imagePaths, int attempt, String lastErrorCode, String lastErrorMessage
});


$DownloadChapterTaskRefCopyWith<$Res> get chapterRef;

}
/// @nodoc
class _$DownloadTaskJsonCopyWithImpl<$Res>
    implements $DownloadTaskJsonCopyWith<$Res> {
  _$DownloadTaskJsonCopyWithImpl(this._self, this._then);

  final DownloadTaskJson _self;
  final $Res Function(DownloadTaskJson) _then;

/// Create a copy of DownloadTaskJson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? comicId = null,Object? comicName = null,Object? chapterRef = null,Object? schemaVersion = null,Object? stateCode = null,Object? phaseCode = null,Object? completedImages = null,Object? reusedImages = null,Object? totalImages = null,Object? imagePaths = null,Object? attempt = null,Object? lastErrorCode = null,Object? lastErrorMessage = null,}) {
  return _then(DownloadTaskJson(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,comicId: null == comicId ? _self.comicId : comicId // ignore: cast_nullable_to_non_nullable
as String,comicName: null == comicName ? _self.comicName : comicName // ignore: cast_nullable_to_non_nullable
as String,chapterRef: null == chapterRef ? _self.chapterRef : chapterRef // ignore: cast_nullable_to_non_nullable
as DownloadChapterTaskRef,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,stateCode: null == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String,phaseCode: null == phaseCode ? _self.phaseCode : phaseCode // ignore: cast_nullable_to_non_nullable
as String,completedImages: null == completedImages ? _self.completedImages : completedImages // ignore: cast_nullable_to_non_nullable
as int,reusedImages: null == reusedImages ? _self.reusedImages : reusedImages // ignore: cast_nullable_to_non_nullable
as int,totalImages: null == totalImages ? _self.totalImages : totalImages // ignore: cast_nullable_to_non_nullable
as int,imagePaths: null == imagePaths ? _self.imagePaths : imagePaths // ignore: cast_nullable_to_non_nullable
as List<String>,attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,lastErrorCode: null == lastErrorCode ? _self.lastErrorCode : lastErrorCode // ignore: cast_nullable_to_non_nullable
as String,lastErrorMessage: null == lastErrorMessage ? _self.lastErrorMessage : lastErrorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of DownloadTaskJson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DownloadChapterTaskRefCopyWith<$Res> get chapterRef {
  
  return $DownloadChapterTaskRefCopyWith<$Res>(_self.chapterRef, (value) {
    return _then(_self.copyWith(chapterRef: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String from,  String comicId,  String comicName,  DownloadChapterTaskRef chapterRef,  int schemaVersion,  String stateCode,  String phaseCode,  int completedImages,  int reusedImages,  int totalImages,  List<String> imagePaths,  int attempt,  String lastErrorCode,  String lastErrorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadTaskJson() when $default != null:
return $default(_that.from,_that.comicId,_that.comicName,_that.chapterRef,_that.schemaVersion,_that.stateCode,_that.phaseCode,_that.completedImages,_that.reusedImages,_that.totalImages,_that.imagePaths,_that.attempt,_that.lastErrorCode,_that.lastErrorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String from,  String comicId,  String comicName,  DownloadChapterTaskRef chapterRef,  int schemaVersion,  String stateCode,  String phaseCode,  int completedImages,  int reusedImages,  int totalImages,  List<String> imagePaths,  int attempt,  String lastErrorCode,  String lastErrorMessage)  $default,) {final _that = this;
switch (_that) {
case _DownloadTaskJson():
return $default(_that.from,_that.comicId,_that.comicName,_that.chapterRef,_that.schemaVersion,_that.stateCode,_that.phaseCode,_that.completedImages,_that.reusedImages,_that.totalImages,_that.imagePaths,_that.attempt,_that.lastErrorCode,_that.lastErrorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String from,  String comicId,  String comicName,  DownloadChapterTaskRef chapterRef,  int schemaVersion,  String stateCode,  String phaseCode,  int completedImages,  int reusedImages,  int totalImages,  List<String> imagePaths,  int attempt,  String lastErrorCode,  String lastErrorMessage)?  $default,) {final _that = this;
switch (_that) {
case _DownloadTaskJson() when $default != null:
return $default(_that.from,_that.comicId,_that.comicName,_that.chapterRef,_that.schemaVersion,_that.stateCode,_that.phaseCode,_that.completedImages,_that.reusedImages,_that.totalImages,_that.imagePaths,_that.attempt,_that.lastErrorCode,_that.lastErrorMessage);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _DownloadTaskJson extends DownloadTaskJson {
  const _DownloadTaskJson({required this.from, required this.comicId, required this.comicName, required this.chapterRef, this.schemaVersion = currentDownloadTaskSchemaVersion, this.stateCode = 'queued', this.phaseCode = '', this.completedImages = 0, this.reusedImages = 0, this.totalImages = 0, this.imagePaths = const <String>[], this.attempt = 0, this.lastErrorCode = '', this.lastErrorMessage = ''}): super._();
  factory _DownloadTaskJson.fromJson(Map<String, dynamic> json) => _$DownloadTaskJsonFromJson(json);

@override final  String from;
@override final  String comicId;
@override final  String comicName;
@override final  DownloadChapterTaskRef chapterRef;
@override@JsonKey() final  int schemaVersion;
@override@JsonKey() final  String stateCode;
@override@JsonKey() final  String phaseCode;
@override@JsonKey() final  int completedImages;
@override@JsonKey() final  int reusedImages;
@override@JsonKey() final  int totalImages;
@override@JsonKey() final  List<String> imagePaths;
@override@JsonKey() final  int attempt;
@override@JsonKey() final  String lastErrorCode;
@override@JsonKey() final  String lastErrorMessage;

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadTaskJson&&(identical(other.from, from) || other.from == from)&&(identical(other.comicId, comicId) || other.comicId == comicId)&&(identical(other.comicName, comicName) || other.comicName == comicName)&&(identical(other.chapterRef, chapterRef) || other.chapterRef == chapterRef)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.stateCode, stateCode) || other.stateCode == stateCode)&&(identical(other.phaseCode, phaseCode) || other.phaseCode == phaseCode)&&(identical(other.completedImages, completedImages) || other.completedImages == completedImages)&&(identical(other.reusedImages, reusedImages) || other.reusedImages == reusedImages)&&(identical(other.totalImages, totalImages) || other.totalImages == totalImages)&&const DeepCollectionEquality().equals(other.imagePaths, imagePaths)&&(identical(other.attempt, attempt) || other.attempt == attempt)&&(identical(other.lastErrorCode, lastErrorCode) || other.lastErrorCode == lastErrorCode)&&(identical(other.lastErrorMessage, lastErrorMessage) || other.lastErrorMessage == lastErrorMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,from,comicId,comicName,chapterRef,schemaVersion,stateCode,phaseCode,completedImages,reusedImages,totalImages,const DeepCollectionEquality().hash(imagePaths),attempt,lastErrorCode,lastErrorMessage);
}

@override
String toString() {
    return 'DownloadTaskJson(from: $from, comicId: $comicId, comicName: $comicName, chapterRef: $chapterRef, schemaVersion: $schemaVersion, stateCode: $stateCode, phaseCode: $phaseCode, completedImages: $completedImages, reusedImages: $reusedImages, totalImages: $totalImages, imagePaths: $imagePaths, attempt: $attempt, lastErrorCode: $lastErrorCode, lastErrorMessage: $lastErrorMessage)';
}


}

/// @nodoc
abstract mixin class _$DownloadTaskJsonCopyWith<$Res> implements $DownloadTaskJsonCopyWith<$Res> {
  factory _$DownloadTaskJsonCopyWith(_DownloadTaskJson value, $Res Function(_DownloadTaskJson) _then) = __$DownloadTaskJsonCopyWithImpl;
@override @useResult
$Res call({
 String from, String comicId, String comicName, DownloadChapterTaskRef chapterRef, int schemaVersion, String stateCode, String phaseCode, int completedImages, int reusedImages, int totalImages, List<String> imagePaths, int attempt, String lastErrorCode, String lastErrorMessage
});


@override $DownloadChapterTaskRefCopyWith<$Res> get chapterRef;

}
/// @nodoc
class __$DownloadTaskJsonCopyWithImpl<$Res>
    implements _$DownloadTaskJsonCopyWith<$Res> {
  __$DownloadTaskJsonCopyWithImpl(this._self, this._then);

  final _DownloadTaskJson _self;
  final $Res Function(_DownloadTaskJson) _then;

/// Create a copy of DownloadTaskJson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? comicId = null,Object? comicName = null,Object? chapterRef = null,Object? schemaVersion = null,Object? stateCode = null,Object? phaseCode = null,Object? completedImages = null,Object? reusedImages = null,Object? totalImages = null,Object? imagePaths = null,Object? attempt = null,Object? lastErrorCode = null,Object? lastErrorMessage = null,}) {
  return _then(_DownloadTaskJson(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,comicId: null == comicId ? _self.comicId : comicId // ignore: cast_nullable_to_non_nullable
as String,comicName: null == comicName ? _self.comicName : comicName // ignore: cast_nullable_to_non_nullable
as String,chapterRef: null == chapterRef ? _self.chapterRef : chapterRef // ignore: cast_nullable_to_non_nullable
as DownloadChapterTaskRef,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,stateCode: null == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String,phaseCode: null == phaseCode ? _self.phaseCode : phaseCode // ignore: cast_nullable_to_non_nullable
as String,completedImages: null == completedImages ? _self.completedImages : completedImages // ignore: cast_nullable_to_non_nullable
as int,reusedImages: null == reusedImages ? _self.reusedImages : reusedImages // ignore: cast_nullable_to_non_nullable
as int,totalImages: null == totalImages ? _self.totalImages : totalImages // ignore: cast_nullable_to_non_nullable
as int,imagePaths: null == imagePaths ? _self.imagePaths : imagePaths // ignore: cast_nullable_to_non_nullable
as List<String>,attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,lastErrorCode: null == lastErrorCode ? _self.lastErrorCode : lastErrorCode // ignore: cast_nullable_to_non_nullable
as String,lastErrorMessage: null == lastErrorMessage ? _self.lastErrorMessage : lastErrorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of DownloadTaskJson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DownloadChapterTaskRefCopyWith<$Res> get chapterRef {
  
  return $DownloadChapterTaskRefCopyWith<$Res>(_self.chapterRef, (value) {
    return _then(_self.copyWith(chapterRef: value));
  });
}
}

// dart format on
