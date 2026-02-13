// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'picture_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PictureInfo {

 From get from;// 从那个漫画网站获取的
 String get url;// 网址
 String get path;// 路径
 String get cartoonId;// 漫画id
 String get chapterId;// 章节id
 PictureType get pictureType;
/// Create a copy of PictureInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PictureInfoCopyWith<PictureInfo> get copyWith => _$PictureInfoCopyWithImpl<PictureInfo>(this as PictureInfo, _$identity);

  /// Serializes this PictureInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PictureInfo&&(identical(other.from, from) || other.from == from)&&(identical(other.url, url) || other.url == url)&&(identical(other.path, path) || other.path == path)&&(identical(other.cartoonId, cartoonId) || other.cartoonId == cartoonId)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.pictureType, pictureType) || other.pictureType == pictureType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,url,path,cartoonId,chapterId,pictureType);

@override
String toString() {
  return 'PictureInfo(from: $from, url: $url, path: $path, cartoonId: $cartoonId, chapterId: $chapterId, pictureType: $pictureType)';
}


}

/// @nodoc
abstract mixin class $PictureInfoCopyWith<$Res>  {
  factory $PictureInfoCopyWith(PictureInfo value, $Res Function(PictureInfo) _then) = _$PictureInfoCopyWithImpl;
@useResult
$Res call({
 From from, String url, String path, String cartoonId, String chapterId, PictureType pictureType
});




}
/// @nodoc
class _$PictureInfoCopyWithImpl<$Res>
    implements $PictureInfoCopyWith<$Res> {
  _$PictureInfoCopyWithImpl(this._self, this._then);

  final PictureInfo _self;
  final $Res Function(PictureInfo) _then;

/// Create a copy of PictureInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? url = null,Object? path = null,Object? cartoonId = null,Object? chapterId = null,Object? pictureType = null,}) {
  return _then(_self.copyWith(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as From,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,cartoonId: null == cartoonId ? _self.cartoonId : cartoonId // ignore: cast_nullable_to_non_nullable
as String,chapterId: null == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String,pictureType: null == pictureType ? _self.pictureType : pictureType // ignore: cast_nullable_to_non_nullable
as PictureType,
  ));
}

}


/// Adds pattern-matching-related methods to [PictureInfo].
extension PictureInfoPatterns on PictureInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PictureInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PictureInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PictureInfo value)  $default,){
final _that = this;
switch (_that) {
case _PictureInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PictureInfo value)?  $default,){
final _that = this;
switch (_that) {
case _PictureInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( From from,  String url,  String path,  String cartoonId,  String chapterId,  PictureType pictureType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PictureInfo() when $default != null:
return $default(_that.from,_that.url,_that.path,_that.cartoonId,_that.chapterId,_that.pictureType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( From from,  String url,  String path,  String cartoonId,  String chapterId,  PictureType pictureType)  $default,) {final _that = this;
switch (_that) {
case _PictureInfo():
return $default(_that.from,_that.url,_that.path,_that.cartoonId,_that.chapterId,_that.pictureType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( From from,  String url,  String path,  String cartoonId,  String chapterId,  PictureType pictureType)?  $default,) {final _that = this;
switch (_that) {
case _PictureInfo() when $default != null:
return $default(_that.from,_that.url,_that.path,_that.cartoonId,_that.chapterId,_that.pictureType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PictureInfo implements PictureInfo {
  const _PictureInfo({this.from = From.bika, this.url = '', this.path = '', this.cartoonId = '', this.chapterId = '', this.pictureType = PictureType.comic});
  factory _PictureInfo.fromJson(Map<String, dynamic> json) => _$PictureInfoFromJson(json);

@override@JsonKey() final  From from;
// 从那个漫画网站获取的
@override@JsonKey() final  String url;
// 网址
@override@JsonKey() final  String path;
// 路径
@override@JsonKey() final  String cartoonId;
// 漫画id
@override@JsonKey() final  String chapterId;
// 章节id
@override@JsonKey() final  PictureType pictureType;

/// Create a copy of PictureInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PictureInfoCopyWith<_PictureInfo> get copyWith => __$PictureInfoCopyWithImpl<_PictureInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PictureInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PictureInfo&&(identical(other.from, from) || other.from == from)&&(identical(other.url, url) || other.url == url)&&(identical(other.path, path) || other.path == path)&&(identical(other.cartoonId, cartoonId) || other.cartoonId == cartoonId)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.pictureType, pictureType) || other.pictureType == pictureType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,url,path,cartoonId,chapterId,pictureType);

@override
String toString() {
  return 'PictureInfo(from: $from, url: $url, path: $path, cartoonId: $cartoonId, chapterId: $chapterId, pictureType: $pictureType)';
}


}

/// @nodoc
abstract mixin class _$PictureInfoCopyWith<$Res> implements $PictureInfoCopyWith<$Res> {
  factory _$PictureInfoCopyWith(_PictureInfo value, $Res Function(_PictureInfo) _then) = __$PictureInfoCopyWithImpl;
@override @useResult
$Res call({
 From from, String url, String path, String cartoonId, String chapterId, PictureType pictureType
});




}
/// @nodoc
class __$PictureInfoCopyWithImpl<$Res>
    implements _$PictureInfoCopyWith<$Res> {
  __$PictureInfoCopyWithImpl(this._self, this._then);

  final _PictureInfo _self;
  final $Res Function(_PictureInfo) _then;

/// Create a copy of PictureInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? url = null,Object? path = null,Object? cartoonId = null,Object? chapterId = null,Object? pictureType = null,}) {
  return _then(_PictureInfo(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as From,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,cartoonId: null == cartoonId ? _self.cartoonId : cartoonId // ignore: cast_nullable_to_non_nullable
as String,chapterId: null == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String,pictureType: null == pictureType ? _self.pictureType : pictureType // ignore: cast_nullable_to_non_nullable
as PictureType,
  ));
}


}

// dart format on
