// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'common_ep_info_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CommonEpInfoJson {

@JsonKey(name: "epId") String get epId;@JsonKey(name: "epName") String get epName;@JsonKey(name: "series") List<Series> get series;@JsonKey(name: "docs") List<Doc> get docs;
/// Create a copy of CommonEpInfoJson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommonEpInfoJsonCopyWith<CommonEpInfoJson> get copyWith => _$CommonEpInfoJsonCopyWithImpl<CommonEpInfoJson>(this as CommonEpInfoJson, _$identity);

  /// Serializes this CommonEpInfoJson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommonEpInfoJson&&(identical(other.epId, epId) || other.epId == epId)&&(identical(other.epName, epName) || other.epName == epName)&&const DeepCollectionEquality().equals(other.series, series)&&const DeepCollectionEquality().equals(other.docs, docs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,epId,epName,const DeepCollectionEquality().hash(series),const DeepCollectionEquality().hash(docs));

@override
String toString() {
  return 'CommonEpInfoJson(epId: $epId, epName: $epName, series: $series, docs: $docs)';
}


}

/// @nodoc
abstract mixin class $CommonEpInfoJsonCopyWith<$Res>  {
  factory $CommonEpInfoJsonCopyWith(CommonEpInfoJson value, $Res Function(CommonEpInfoJson) _then) = _$CommonEpInfoJsonCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "epId") String epId,@JsonKey(name: "epName") String epName,@JsonKey(name: "series") List<Series> series,@JsonKey(name: "docs") List<Doc> docs
});




}
/// @nodoc
class _$CommonEpInfoJsonCopyWithImpl<$Res>
    implements $CommonEpInfoJsonCopyWith<$Res> {
  _$CommonEpInfoJsonCopyWithImpl(this._self, this._then);

  final CommonEpInfoJson _self;
  final $Res Function(CommonEpInfoJson) _then;

/// Create a copy of CommonEpInfoJson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? epId = null,Object? epName = null,Object? series = null,Object? docs = null,}) {
  return _then(_self.copyWith(
epId: null == epId ? _self.epId : epId // ignore: cast_nullable_to_non_nullable
as String,epName: null == epName ? _self.epName : epName // ignore: cast_nullable_to_non_nullable
as String,series: null == series ? _self.series : series // ignore: cast_nullable_to_non_nullable
as List<Series>,docs: null == docs ? _self.docs : docs // ignore: cast_nullable_to_non_nullable
as List<Doc>,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _CommonEpInfoJson implements CommonEpInfoJson {
  const _CommonEpInfoJson({@JsonKey(name: "epId") required this.epId, @JsonKey(name: "epName") required this.epName, @JsonKey(name: "series") required final  List<Series> series, @JsonKey(name: "docs") required final  List<Doc> docs}): _series = series,_docs = docs;
  factory _CommonEpInfoJson.fromJson(Map<String, dynamic> json) => _$CommonEpInfoJsonFromJson(json);

@override@JsonKey(name: "epId") final  String epId;
@override@JsonKey(name: "epName") final  String epName;
 final  List<Series> _series;
@override@JsonKey(name: "series") List<Series> get series {
  if (_series is EqualUnmodifiableListView) return _series;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_series);
}

 final  List<Doc> _docs;
@override@JsonKey(name: "docs") List<Doc> get docs {
  if (_docs is EqualUnmodifiableListView) return _docs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_docs);
}


/// Create a copy of CommonEpInfoJson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommonEpInfoJsonCopyWith<_CommonEpInfoJson> get copyWith => __$CommonEpInfoJsonCopyWithImpl<_CommonEpInfoJson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommonEpInfoJsonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommonEpInfoJson&&(identical(other.epId, epId) || other.epId == epId)&&(identical(other.epName, epName) || other.epName == epName)&&const DeepCollectionEquality().equals(other._series, _series)&&const DeepCollectionEquality().equals(other._docs, _docs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,epId,epName,const DeepCollectionEquality().hash(_series),const DeepCollectionEquality().hash(_docs));

@override
String toString() {
  return 'CommonEpInfoJson(epId: $epId, epName: $epName, series: $series, docs: $docs)';
}


}

/// @nodoc
abstract mixin class _$CommonEpInfoJsonCopyWith<$Res> implements $CommonEpInfoJsonCopyWith<$Res> {
  factory _$CommonEpInfoJsonCopyWith(_CommonEpInfoJson value, $Res Function(_CommonEpInfoJson) _then) = __$CommonEpInfoJsonCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "epId") String epId,@JsonKey(name: "epName") String epName,@JsonKey(name: "series") List<Series> series,@JsonKey(name: "docs") List<Doc> docs
});




}
/// @nodoc
class __$CommonEpInfoJsonCopyWithImpl<$Res>
    implements _$CommonEpInfoJsonCopyWith<$Res> {
  __$CommonEpInfoJsonCopyWithImpl(this._self, this._then);

  final _CommonEpInfoJson _self;
  final $Res Function(_CommonEpInfoJson) _then;

/// Create a copy of CommonEpInfoJson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? epId = null,Object? epName = null,Object? series = null,Object? docs = null,}) {
  return _then(_CommonEpInfoJson(
epId: null == epId ? _self.epId : epId // ignore: cast_nullable_to_non_nullable
as String,epName: null == epName ? _self.epName : epName // ignore: cast_nullable_to_non_nullable
as String,series: null == series ? _self._series : series // ignore: cast_nullable_to_non_nullable
as List<Series>,docs: null == docs ? _self._docs : docs // ignore: cast_nullable_to_non_nullable
as List<Doc>,
  ));
}


}


/// @nodoc
mixin _$Doc {

@JsonKey(name: "originalName") String get originalName;@JsonKey(name: "path") String get path;@JsonKey(name: "fileServer") String get fileServer;@JsonKey(name: "id") String get id;
/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocCopyWith<Doc> get copyWith => _$DocCopyWithImpl<Doc>(this as Doc, _$identity);

  /// Serializes this Doc to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Doc&&(identical(other.originalName, originalName) || other.originalName == originalName)&&(identical(other.path, path) || other.path == path)&&(identical(other.fileServer, fileServer) || other.fileServer == fileServer)&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,originalName,path,fileServer,id);

@override
String toString() {
  return 'Doc(originalName: $originalName, path: $path, fileServer: $fileServer, id: $id)';
}


}

/// @nodoc
abstract mixin class $DocCopyWith<$Res>  {
  factory $DocCopyWith(Doc value, $Res Function(Doc) _then) = _$DocCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "originalName") String originalName,@JsonKey(name: "path") String path,@JsonKey(name: "fileServer") String fileServer,@JsonKey(name: "id") String id
});




}
/// @nodoc
class _$DocCopyWithImpl<$Res>
    implements $DocCopyWith<$Res> {
  _$DocCopyWithImpl(this._self, this._then);

  final Doc _self;
  final $Res Function(Doc) _then;

/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? originalName = null,Object? path = null,Object? fileServer = null,Object? id = null,}) {
  return _then(_self.copyWith(
originalName: null == originalName ? _self.originalName : originalName // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,fileServer: null == fileServer ? _self.fileServer : fileServer // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Doc implements Doc {
  const _Doc({@JsonKey(name: "originalName") required this.originalName, @JsonKey(name: "path") required this.path, @JsonKey(name: "fileServer") required this.fileServer, @JsonKey(name: "id") required this.id});
  factory _Doc.fromJson(Map<String, dynamic> json) => _$DocFromJson(json);

@override@JsonKey(name: "originalName") final  String originalName;
@override@JsonKey(name: "path") final  String path;
@override@JsonKey(name: "fileServer") final  String fileServer;
@override@JsonKey(name: "id") final  String id;

/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocCopyWith<_Doc> get copyWith => __$DocCopyWithImpl<_Doc>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Doc&&(identical(other.originalName, originalName) || other.originalName == originalName)&&(identical(other.path, path) || other.path == path)&&(identical(other.fileServer, fileServer) || other.fileServer == fileServer)&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,originalName,path,fileServer,id);

@override
String toString() {
  return 'Doc(originalName: $originalName, path: $path, fileServer: $fileServer, id: $id)';
}


}

/// @nodoc
abstract mixin class _$DocCopyWith<$Res> implements $DocCopyWith<$Res> {
  factory _$DocCopyWith(_Doc value, $Res Function(_Doc) _then) = __$DocCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "originalName") String originalName,@JsonKey(name: "path") String path,@JsonKey(name: "fileServer") String fileServer,@JsonKey(name: "id") String id
});




}
/// @nodoc
class __$DocCopyWithImpl<$Res>
    implements _$DocCopyWith<$Res> {
  __$DocCopyWithImpl(this._self, this._then);

  final _Doc _self;
  final $Res Function(_Doc) _then;

/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? originalName = null,Object? path = null,Object? fileServer = null,Object? id = null,}) {
  return _then(_Doc(
originalName: null == originalName ? _self.originalName : originalName // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,fileServer: null == fileServer ? _self.fileServer : fileServer // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Series {

@JsonKey(name: "id") String get id;@JsonKey(name: "name") String get name;@JsonKey(name: "sort") String get sort;
/// Create a copy of Series
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeriesCopyWith<Series> get copyWith => _$SeriesCopyWithImpl<Series>(this as Series, _$identity);

  /// Serializes this Series to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Series&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sort, sort) || other.sort == sort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,sort);

@override
String toString() {
  return 'Series(id: $id, name: $name, sort: $sort)';
}


}

/// @nodoc
abstract mixin class $SeriesCopyWith<$Res>  {
  factory $SeriesCopyWith(Series value, $Res Function(Series) _then) = _$SeriesCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "name") String name,@JsonKey(name: "sort") String sort
});




}
/// @nodoc
class _$SeriesCopyWithImpl<$Res>
    implements $SeriesCopyWith<$Res> {
  _$SeriesCopyWithImpl(this._self, this._then);

  final Series _self;
  final $Res Function(Series) _then;

/// Create a copy of Series
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? sort = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Series implements Series {
  const _Series({@JsonKey(name: "id") required this.id, @JsonKey(name: "name") required this.name, @JsonKey(name: "sort") required this.sort});
  factory _Series.fromJson(Map<String, dynamic> json) => _$SeriesFromJson(json);

@override@JsonKey(name: "id") final  String id;
@override@JsonKey(name: "name") final  String name;
@override@JsonKey(name: "sort") final  String sort;

/// Create a copy of Series
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeriesCopyWith<_Series> get copyWith => __$SeriesCopyWithImpl<_Series>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeriesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Series&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sort, sort) || other.sort == sort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,sort);

@override
String toString() {
  return 'Series(id: $id, name: $name, sort: $sort)';
}


}

/// @nodoc
abstract mixin class _$SeriesCopyWith<$Res> implements $SeriesCopyWith<$Res> {
  factory _$SeriesCopyWith(_Series value, $Res Function(_Series) _then) = __$SeriesCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "name") String name,@JsonKey(name: "sort") String sort
});




}
/// @nodoc
class __$SeriesCopyWithImpl<$Res>
    implements _$SeriesCopyWith<$Res> {
  __$SeriesCopyWithImpl(this._self, this._then);

  final _Series _self;
  final $Res Function(_Series) _then;

/// Create a copy of Series
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? sort = null,}) {
  return _then(_Series(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
