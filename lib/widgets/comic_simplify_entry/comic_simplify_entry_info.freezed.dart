// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comic_simplify_entry_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ComicSimplifyEntryInfo {

@JsonKey(name: "title") String get title;@JsonKey(name: "id") String get id;@JsonKey(name: "fileServer") String get fileServer;@JsonKey(name: "path") String get path;@JsonKey(name: "pictureType") PictureType get pictureType;@JsonKey(name: "from") From get from;
/// Create a copy of ComicSimplifyEntryInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicSimplifyEntryInfoCopyWith<ComicSimplifyEntryInfo> get copyWith => _$ComicSimplifyEntryInfoCopyWithImpl<ComicSimplifyEntryInfo>(this as ComicSimplifyEntryInfo, _$identity);

  /// Serializes this ComicSimplifyEntryInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicSimplifyEntryInfo&&(identical(other.title, title) || other.title == title)&&(identical(other.id, id) || other.id == id)&&(identical(other.fileServer, fileServer) || other.fileServer == fileServer)&&(identical(other.path, path) || other.path == path)&&(identical(other.pictureType, pictureType) || other.pictureType == pictureType)&&(identical(other.from, from) || other.from == from));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,id,fileServer,path,pictureType,from);

@override
String toString() {
  return 'ComicSimplifyEntryInfo(title: $title, id: $id, fileServer: $fileServer, path: $path, pictureType: $pictureType, from: $from)';
}


}

/// @nodoc
abstract mixin class $ComicSimplifyEntryInfoCopyWith<$Res>  {
  factory $ComicSimplifyEntryInfoCopyWith(ComicSimplifyEntryInfo value, $Res Function(ComicSimplifyEntryInfo) _then) = _$ComicSimplifyEntryInfoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "title") String title,@JsonKey(name: "id") String id,@JsonKey(name: "fileServer") String fileServer,@JsonKey(name: "path") String path,@JsonKey(name: "pictureType") PictureType pictureType,@JsonKey(name: "from") From from
});




}
/// @nodoc
class _$ComicSimplifyEntryInfoCopyWithImpl<$Res>
    implements $ComicSimplifyEntryInfoCopyWith<$Res> {
  _$ComicSimplifyEntryInfoCopyWithImpl(this._self, this._then);

  final ComicSimplifyEntryInfo _self;
  final $Res Function(ComicSimplifyEntryInfo) _then;

/// Create a copy of ComicSimplifyEntryInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? id = null,Object? fileServer = null,Object? path = null,Object? pictureType = null,Object? from = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileServer: null == fileServer ? _self.fileServer : fileServer // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,pictureType: null == pictureType ? _self.pictureType : pictureType // ignore: cast_nullable_to_non_nullable
as PictureType,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as From,
  ));
}

}


/// Adds pattern-matching-related methods to [ComicSimplifyEntryInfo].
extension ComicSimplifyEntryInfoPatterns on ComicSimplifyEntryInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicSimplifyEntryInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicSimplifyEntryInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicSimplifyEntryInfo value)  $default,){
final _that = this;
switch (_that) {
case _ComicSimplifyEntryInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicSimplifyEntryInfo value)?  $default,){
final _that = this;
switch (_that) {
case _ComicSimplifyEntryInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "title")  String title, @JsonKey(name: "id")  String id, @JsonKey(name: "fileServer")  String fileServer, @JsonKey(name: "path")  String path, @JsonKey(name: "pictureType")  PictureType pictureType, @JsonKey(name: "from")  From from)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicSimplifyEntryInfo() when $default != null:
return $default(_that.title,_that.id,_that.fileServer,_that.path,_that.pictureType,_that.from);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "title")  String title, @JsonKey(name: "id")  String id, @JsonKey(name: "fileServer")  String fileServer, @JsonKey(name: "path")  String path, @JsonKey(name: "pictureType")  PictureType pictureType, @JsonKey(name: "from")  From from)  $default,) {final _that = this;
switch (_that) {
case _ComicSimplifyEntryInfo():
return $default(_that.title,_that.id,_that.fileServer,_that.path,_that.pictureType,_that.from);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "title")  String title, @JsonKey(name: "id")  String id, @JsonKey(name: "fileServer")  String fileServer, @JsonKey(name: "path")  String path, @JsonKey(name: "pictureType")  PictureType pictureType, @JsonKey(name: "from")  From from)?  $default,) {final _that = this;
switch (_that) {
case _ComicSimplifyEntryInfo() when $default != null:
return $default(_that.title,_that.id,_that.fileServer,_that.path,_that.pictureType,_that.from);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComicSimplifyEntryInfo implements ComicSimplifyEntryInfo {
  const _ComicSimplifyEntryInfo({@JsonKey(name: "title") required this.title, @JsonKey(name: "id") required this.id, @JsonKey(name: "fileServer") required this.fileServer, @JsonKey(name: "path") required this.path, @JsonKey(name: "pictureType") required this.pictureType, @JsonKey(name: "from") required this.from});
  factory _ComicSimplifyEntryInfo.fromJson(Map<String, dynamic> json) => _$ComicSimplifyEntryInfoFromJson(json);

@override@JsonKey(name: "title") final  String title;
@override@JsonKey(name: "id") final  String id;
@override@JsonKey(name: "fileServer") final  String fileServer;
@override@JsonKey(name: "path") final  String path;
@override@JsonKey(name: "pictureType") final  PictureType pictureType;
@override@JsonKey(name: "from") final  From from;

/// Create a copy of ComicSimplifyEntryInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicSimplifyEntryInfoCopyWith<_ComicSimplifyEntryInfo> get copyWith => __$ComicSimplifyEntryInfoCopyWithImpl<_ComicSimplifyEntryInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicSimplifyEntryInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicSimplifyEntryInfo&&(identical(other.title, title) || other.title == title)&&(identical(other.id, id) || other.id == id)&&(identical(other.fileServer, fileServer) || other.fileServer == fileServer)&&(identical(other.path, path) || other.path == path)&&(identical(other.pictureType, pictureType) || other.pictureType == pictureType)&&(identical(other.from, from) || other.from == from));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,id,fileServer,path,pictureType,from);

@override
String toString() {
  return 'ComicSimplifyEntryInfo(title: $title, id: $id, fileServer: $fileServer, path: $path, pictureType: $pictureType, from: $from)';
}


}

/// @nodoc
abstract mixin class _$ComicSimplifyEntryInfoCopyWith<$Res> implements $ComicSimplifyEntryInfoCopyWith<$Res> {
  factory _$ComicSimplifyEntryInfoCopyWith(_ComicSimplifyEntryInfo value, $Res Function(_ComicSimplifyEntryInfo) _then) = __$ComicSimplifyEntryInfoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "title") String title,@JsonKey(name: "id") String id,@JsonKey(name: "fileServer") String fileServer,@JsonKey(name: "path") String path,@JsonKey(name: "pictureType") PictureType pictureType,@JsonKey(name: "from") From from
});




}
/// @nodoc
class __$ComicSimplifyEntryInfoCopyWithImpl<$Res>
    implements _$ComicSimplifyEntryInfoCopyWith<$Res> {
  __$ComicSimplifyEntryInfoCopyWithImpl(this._self, this._then);

  final _ComicSimplifyEntryInfo _self;
  final $Res Function(_ComicSimplifyEntryInfo) _then;

/// Create a copy of ComicSimplifyEntryInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? id = null,Object? fileServer = null,Object? path = null,Object? pictureType = null,Object? from = null,}) {
  return _then(_ComicSimplifyEntryInfo(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileServer: null == fileServer ? _self.fileServer : fileServer // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,pictureType: null == pictureType ? _self.pictureType : pictureType // ignore: cast_nullable_to_non_nullable
as PictureType,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as From,
  ));
}


}

// dart format on
