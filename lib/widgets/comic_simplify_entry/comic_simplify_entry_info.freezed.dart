// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
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

@JsonKey(name: "title") String get title;@JsonKey(name: "id") String get id;@JsonKey(name: "fileServer") String get fileServer;@JsonKey(name: "path") String get path;@JsonKey(name: "pictureType") String get pictureType;@JsonKey(name: "from") String get from;
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
@JsonKey(name: "title") String title,@JsonKey(name: "id") String id,@JsonKey(name: "fileServer") String fileServer,@JsonKey(name: "path") String path,@JsonKey(name: "pictureType") String pictureType,@JsonKey(name: "from") String from
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
as String,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,
  ));
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
@override@JsonKey(name: "pictureType") final  String pictureType;
@override@JsonKey(name: "from") final  String from;

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
@JsonKey(name: "title") String title,@JsonKey(name: "id") String id,@JsonKey(name: "fileServer") String fileServer,@JsonKey(name: "path") String path,@JsonKey(name: "pictureType") String pictureType,@JsonKey(name: "from") String from
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
as String,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
