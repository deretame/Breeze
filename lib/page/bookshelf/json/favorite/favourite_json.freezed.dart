// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'favourite_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FavouriteJson {

@JsonKey(name: "code") int get code;@JsonKey(name: "message") String get message;@JsonKey(name: "data") Data get data;
/// Create a copy of FavouriteJson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavouriteJsonCopyWith<FavouriteJson> get copyWith => _$FavouriteJsonCopyWithImpl<FavouriteJson>(this as FavouriteJson, _$identity);

  /// Serializes this FavouriteJson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavouriteJson&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'FavouriteJson(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $FavouriteJsonCopyWith<$Res>  {
  factory $FavouriteJsonCopyWith(FavouriteJson value, $Res Function(FavouriteJson) _then) = _$FavouriteJsonCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "code") int code,@JsonKey(name: "message") String message,@JsonKey(name: "data") Data data
});


$DataCopyWith<$Res> get data;

}
/// @nodoc
class _$FavouriteJsonCopyWithImpl<$Res>
    implements $FavouriteJsonCopyWith<$Res> {
  _$FavouriteJsonCopyWithImpl(this._self, this._then);

  final FavouriteJson _self;
  final $Res Function(FavouriteJson) _then;

/// Create a copy of FavouriteJson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? data = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Data,
  ));
}
/// Create a copy of FavouriteJson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataCopyWith<$Res> get data {
  
  return $DataCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// @nodoc
@JsonSerializable()

class _FavouriteJson implements FavouriteJson {
  const _FavouriteJson({@JsonKey(name: "code") required this.code, @JsonKey(name: "message") required this.message, @JsonKey(name: "data") required this.data});
  factory _FavouriteJson.fromJson(Map<String, dynamic> json) => _$FavouriteJsonFromJson(json);

@override@JsonKey(name: "code") final  int code;
@override@JsonKey(name: "message") final  String message;
@override@JsonKey(name: "data") final  Data data;

/// Create a copy of FavouriteJson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FavouriteJsonCopyWith<_FavouriteJson> get copyWith => __$FavouriteJsonCopyWithImpl<_FavouriteJson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FavouriteJsonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FavouriteJson&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'FavouriteJson(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$FavouriteJsonCopyWith<$Res> implements $FavouriteJsonCopyWith<$Res> {
  factory _$FavouriteJsonCopyWith(_FavouriteJson value, $Res Function(_FavouriteJson) _then) = __$FavouriteJsonCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "code") int code,@JsonKey(name: "message") String message,@JsonKey(name: "data") Data data
});


@override $DataCopyWith<$Res> get data;

}
/// @nodoc
class __$FavouriteJsonCopyWithImpl<$Res>
    implements _$FavouriteJsonCopyWith<$Res> {
  __$FavouriteJsonCopyWithImpl(this._self, this._then);

  final _FavouriteJson _self;
  final $Res Function(_FavouriteJson) _then;

/// Create a copy of FavouriteJson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? data = null,}) {
  return _then(_FavouriteJson(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Data,
  ));
}

/// Create a copy of FavouriteJson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataCopyWith<$Res> get data {
  
  return $DataCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// @nodoc
mixin _$Data {

@JsonKey(name: "comics") Comics get comics;
/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataCopyWith<Data> get copyWith => _$DataCopyWithImpl<Data>(this as Data, _$identity);

  /// Serializes this Data to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Data&&(identical(other.comics, comics) || other.comics == comics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comics);

@override
String toString() {
  return 'Data(comics: $comics)';
}


}

/// @nodoc
abstract mixin class $DataCopyWith<$Res>  {
  factory $DataCopyWith(Data value, $Res Function(Data) _then) = _$DataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "comics") Comics comics
});


$ComicsCopyWith<$Res> get comics;

}
/// @nodoc
class _$DataCopyWithImpl<$Res>
    implements $DataCopyWith<$Res> {
  _$DataCopyWithImpl(this._self, this._then);

  final Data _self;
  final $Res Function(Data) _then;

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? comics = null,}) {
  return _then(_self.copyWith(
comics: null == comics ? _self.comics : comics // ignore: cast_nullable_to_non_nullable
as Comics,
  ));
}
/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicsCopyWith<$Res> get comics {
  
  return $ComicsCopyWith<$Res>(_self.comics, (value) {
    return _then(_self.copyWith(comics: value));
  });
}
}


/// @nodoc
@JsonSerializable()

class _Data implements Data {
  const _Data({@JsonKey(name: "comics") required this.comics});
  factory _Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);

@override@JsonKey(name: "comics") final  Comics comics;

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DataCopyWith<_Data> get copyWith => __$DataCopyWithImpl<_Data>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Data&&(identical(other.comics, comics) || other.comics == comics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comics);

@override
String toString() {
  return 'Data(comics: $comics)';
}


}

/// @nodoc
abstract mixin class _$DataCopyWith<$Res> implements $DataCopyWith<$Res> {
  factory _$DataCopyWith(_Data value, $Res Function(_Data) _then) = __$DataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "comics") Comics comics
});


@override $ComicsCopyWith<$Res> get comics;

}
/// @nodoc
class __$DataCopyWithImpl<$Res>
    implements _$DataCopyWith<$Res> {
  __$DataCopyWithImpl(this._self, this._then);

  final _Data _self;
  final $Res Function(_Data) _then;

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? comics = null,}) {
  return _then(_Data(
comics: null == comics ? _self.comics : comics // ignore: cast_nullable_to_non_nullable
as Comics,
  ));
}

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicsCopyWith<$Res> get comics {
  
  return $ComicsCopyWith<$Res>(_self.comics, (value) {
    return _then(_self.copyWith(comics: value));
  });
}
}


/// @nodoc
mixin _$Comics {

@JsonKey(name: "pages") int get pages;@JsonKey(name: "total") int get total;@JsonKey(name: "docs") List<Doc> get docs;@JsonKey(name: "page") int get page;@JsonKey(name: "limit") int get limit;
/// Create a copy of Comics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicsCopyWith<Comics> get copyWith => _$ComicsCopyWithImpl<Comics>(this as Comics, _$identity);

  /// Serializes this Comics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Comics&&(identical(other.pages, pages) || other.pages == pages)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.docs, docs)&&(identical(other.page, page) || other.page == page)&&(identical(other.limit, limit) || other.limit == limit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pages,total,const DeepCollectionEquality().hash(docs),page,limit);

@override
String toString() {
  return 'Comics(pages: $pages, total: $total, docs: $docs, page: $page, limit: $limit)';
}


}

/// @nodoc
abstract mixin class $ComicsCopyWith<$Res>  {
  factory $ComicsCopyWith(Comics value, $Res Function(Comics) _then) = _$ComicsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "pages") int pages,@JsonKey(name: "total") int total,@JsonKey(name: "docs") List<Doc> docs,@JsonKey(name: "page") int page,@JsonKey(name: "limit") int limit
});




}
/// @nodoc
class _$ComicsCopyWithImpl<$Res>
    implements $ComicsCopyWith<$Res> {
  _$ComicsCopyWithImpl(this._self, this._then);

  final Comics _self;
  final $Res Function(Comics) _then;

/// Create a copy of Comics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pages = null,Object? total = null,Object? docs = null,Object? page = null,Object? limit = null,}) {
  return _then(_self.copyWith(
pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,docs: null == docs ? _self.docs : docs // ignore: cast_nullable_to_non_nullable
as List<Doc>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Comics implements Comics {
  const _Comics({@JsonKey(name: "pages") required this.pages, @JsonKey(name: "total") required this.total, @JsonKey(name: "docs") required final  List<Doc> docs, @JsonKey(name: "page") required this.page, @JsonKey(name: "limit") required this.limit}): _docs = docs;
  factory _Comics.fromJson(Map<String, dynamic> json) => _$ComicsFromJson(json);

@override@JsonKey(name: "pages") final  int pages;
@override@JsonKey(name: "total") final  int total;
 final  List<Doc> _docs;
@override@JsonKey(name: "docs") List<Doc> get docs {
  if (_docs is EqualUnmodifiableListView) return _docs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_docs);
}

@override@JsonKey(name: "page") final  int page;
@override@JsonKey(name: "limit") final  int limit;

/// Create a copy of Comics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicsCopyWith<_Comics> get copyWith => __$ComicsCopyWithImpl<_Comics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Comics&&(identical(other.pages, pages) || other.pages == pages)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other._docs, _docs)&&(identical(other.page, page) || other.page == page)&&(identical(other.limit, limit) || other.limit == limit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pages,total,const DeepCollectionEquality().hash(_docs),page,limit);

@override
String toString() {
  return 'Comics(pages: $pages, total: $total, docs: $docs, page: $page, limit: $limit)';
}


}

/// @nodoc
abstract mixin class _$ComicsCopyWith<$Res> implements $ComicsCopyWith<$Res> {
  factory _$ComicsCopyWith(_Comics value, $Res Function(_Comics) _then) = __$ComicsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "pages") int pages,@JsonKey(name: "total") int total,@JsonKey(name: "docs") List<Doc> docs,@JsonKey(name: "page") int page,@JsonKey(name: "limit") int limit
});




}
/// @nodoc
class __$ComicsCopyWithImpl<$Res>
    implements _$ComicsCopyWith<$Res> {
  __$ComicsCopyWithImpl(this._self, this._then);

  final _Comics _self;
  final $Res Function(_Comics) _then;

/// Create a copy of Comics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pages = null,Object? total = null,Object? docs = null,Object? page = null,Object? limit = null,}) {
  return _then(_Comics(
pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,docs: null == docs ? _self._docs : docs // ignore: cast_nullable_to_non_nullable
as List<Doc>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Doc {

@JsonKey(name: "_id") String get id;@JsonKey(name: "title") String get title;@JsonKey(name: "author") String get author;@JsonKey(name: "totalViews") int get totalViews;@JsonKey(name: "totalLikes") int get totalLikes;@JsonKey(name: "pagesCount") int get pagesCount;@JsonKey(name: "epsCount") int get epsCount;@JsonKey(name: "finished") bool get finished;@JsonKey(name: "categories") List<String> get categories;@JsonKey(name: "thumb") Thumb get thumb;@JsonKey(name: "likesCount") int get likesCount;
/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocCopyWith<Doc> get copyWith => _$DocCopyWithImpl<Doc>(this as Doc, _$identity);

  /// Serializes this Doc to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Doc&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.totalViews, totalViews) || other.totalViews == totalViews)&&(identical(other.totalLikes, totalLikes) || other.totalLikes == totalLikes)&&(identical(other.pagesCount, pagesCount) || other.pagesCount == pagesCount)&&(identical(other.epsCount, epsCount) || other.epsCount == epsCount)&&(identical(other.finished, finished) || other.finished == finished)&&const DeepCollectionEquality().equals(other.categories, categories)&&(identical(other.thumb, thumb) || other.thumb == thumb)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,author,totalViews,totalLikes,pagesCount,epsCount,finished,const DeepCollectionEquality().hash(categories),thumb,likesCount);

@override
String toString() {
  return 'Doc(id: $id, title: $title, author: $author, totalViews: $totalViews, totalLikes: $totalLikes, pagesCount: $pagesCount, epsCount: $epsCount, finished: $finished, categories: $categories, thumb: $thumb, likesCount: $likesCount)';
}


}

/// @nodoc
abstract mixin class $DocCopyWith<$Res>  {
  factory $DocCopyWith(Doc value, $Res Function(Doc) _then) = _$DocCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "title") String title,@JsonKey(name: "author") String author,@JsonKey(name: "totalViews") int totalViews,@JsonKey(name: "totalLikes") int totalLikes,@JsonKey(name: "pagesCount") int pagesCount,@JsonKey(name: "epsCount") int epsCount,@JsonKey(name: "finished") bool finished,@JsonKey(name: "categories") List<String> categories,@JsonKey(name: "thumb") Thumb thumb,@JsonKey(name: "likesCount") int likesCount
});


$ThumbCopyWith<$Res> get thumb;

}
/// @nodoc
class _$DocCopyWithImpl<$Res>
    implements $DocCopyWith<$Res> {
  _$DocCopyWithImpl(this._self, this._then);

  final Doc _self;
  final $Res Function(Doc) _then;

/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? author = null,Object? totalViews = null,Object? totalLikes = null,Object? pagesCount = null,Object? epsCount = null,Object? finished = null,Object? categories = null,Object? thumb = null,Object? likesCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,totalViews: null == totalViews ? _self.totalViews : totalViews // ignore: cast_nullable_to_non_nullable
as int,totalLikes: null == totalLikes ? _self.totalLikes : totalLikes // ignore: cast_nullable_to_non_nullable
as int,pagesCount: null == pagesCount ? _self.pagesCount : pagesCount // ignore: cast_nullable_to_non_nullable
as int,epsCount: null == epsCount ? _self.epsCount : epsCount // ignore: cast_nullable_to_non_nullable
as int,finished: null == finished ? _self.finished : finished // ignore: cast_nullable_to_non_nullable
as bool,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,thumb: null == thumb ? _self.thumb : thumb // ignore: cast_nullable_to_non_nullable
as Thumb,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThumbCopyWith<$Res> get thumb {
  
  return $ThumbCopyWith<$Res>(_self.thumb, (value) {
    return _then(_self.copyWith(thumb: value));
  });
}
}


/// @nodoc
@JsonSerializable()

class _Doc implements Doc {
  const _Doc({@JsonKey(name: "_id") required this.id, @JsonKey(name: "title") required this.title, @JsonKey(name: "author") required this.author, @JsonKey(name: "totalViews") required this.totalViews, @JsonKey(name: "totalLikes") required this.totalLikes, @JsonKey(name: "pagesCount") required this.pagesCount, @JsonKey(name: "epsCount") required this.epsCount, @JsonKey(name: "finished") required this.finished, @JsonKey(name: "categories") required final  List<String> categories, @JsonKey(name: "thumb") required this.thumb, @JsonKey(name: "likesCount") required this.likesCount}): _categories = categories;
  factory _Doc.fromJson(Map<String, dynamic> json) => _$DocFromJson(json);

@override@JsonKey(name: "_id") final  String id;
@override@JsonKey(name: "title") final  String title;
@override@JsonKey(name: "author") final  String author;
@override@JsonKey(name: "totalViews") final  int totalViews;
@override@JsonKey(name: "totalLikes") final  int totalLikes;
@override@JsonKey(name: "pagesCount") final  int pagesCount;
@override@JsonKey(name: "epsCount") final  int epsCount;
@override@JsonKey(name: "finished") final  bool finished;
 final  List<String> _categories;
@override@JsonKey(name: "categories") List<String> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

@override@JsonKey(name: "thumb") final  Thumb thumb;
@override@JsonKey(name: "likesCount") final  int likesCount;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Doc&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.totalViews, totalViews) || other.totalViews == totalViews)&&(identical(other.totalLikes, totalLikes) || other.totalLikes == totalLikes)&&(identical(other.pagesCount, pagesCount) || other.pagesCount == pagesCount)&&(identical(other.epsCount, epsCount) || other.epsCount == epsCount)&&(identical(other.finished, finished) || other.finished == finished)&&const DeepCollectionEquality().equals(other._categories, _categories)&&(identical(other.thumb, thumb) || other.thumb == thumb)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,author,totalViews,totalLikes,pagesCount,epsCount,finished,const DeepCollectionEquality().hash(_categories),thumb,likesCount);

@override
String toString() {
  return 'Doc(id: $id, title: $title, author: $author, totalViews: $totalViews, totalLikes: $totalLikes, pagesCount: $pagesCount, epsCount: $epsCount, finished: $finished, categories: $categories, thumb: $thumb, likesCount: $likesCount)';
}


}

/// @nodoc
abstract mixin class _$DocCopyWith<$Res> implements $DocCopyWith<$Res> {
  factory _$DocCopyWith(_Doc value, $Res Function(_Doc) _then) = __$DocCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "title") String title,@JsonKey(name: "author") String author,@JsonKey(name: "totalViews") int totalViews,@JsonKey(name: "totalLikes") int totalLikes,@JsonKey(name: "pagesCount") int pagesCount,@JsonKey(name: "epsCount") int epsCount,@JsonKey(name: "finished") bool finished,@JsonKey(name: "categories") List<String> categories,@JsonKey(name: "thumb") Thumb thumb,@JsonKey(name: "likesCount") int likesCount
});


@override $ThumbCopyWith<$Res> get thumb;

}
/// @nodoc
class __$DocCopyWithImpl<$Res>
    implements _$DocCopyWith<$Res> {
  __$DocCopyWithImpl(this._self, this._then);

  final _Doc _self;
  final $Res Function(_Doc) _then;

/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? author = null,Object? totalViews = null,Object? totalLikes = null,Object? pagesCount = null,Object? epsCount = null,Object? finished = null,Object? categories = null,Object? thumb = null,Object? likesCount = null,}) {
  return _then(_Doc(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,totalViews: null == totalViews ? _self.totalViews : totalViews // ignore: cast_nullable_to_non_nullable
as int,totalLikes: null == totalLikes ? _self.totalLikes : totalLikes // ignore: cast_nullable_to_non_nullable
as int,pagesCount: null == pagesCount ? _self.pagesCount : pagesCount // ignore: cast_nullable_to_non_nullable
as int,epsCount: null == epsCount ? _self.epsCount : epsCount // ignore: cast_nullable_to_non_nullable
as int,finished: null == finished ? _self.finished : finished // ignore: cast_nullable_to_non_nullable
as bool,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,thumb: null == thumb ? _self.thumb : thumb // ignore: cast_nullable_to_non_nullable
as Thumb,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThumbCopyWith<$Res> get thumb {
  
  return $ThumbCopyWith<$Res>(_self.thumb, (value) {
    return _then(_self.copyWith(thumb: value));
  });
}
}


/// @nodoc
mixin _$Thumb {

@JsonKey(name: "fileServer") String get fileServer;@JsonKey(name: "path") String get path;@JsonKey(name: "originalName") String get originalName;
/// Create a copy of Thumb
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ThumbCopyWith<Thumb> get copyWith => _$ThumbCopyWithImpl<Thumb>(this as Thumb, _$identity);

  /// Serializes this Thumb to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Thumb&&(identical(other.fileServer, fileServer) || other.fileServer == fileServer)&&(identical(other.path, path) || other.path == path)&&(identical(other.originalName, originalName) || other.originalName == originalName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileServer,path,originalName);

@override
String toString() {
  return 'Thumb(fileServer: $fileServer, path: $path, originalName: $originalName)';
}


}

/// @nodoc
abstract mixin class $ThumbCopyWith<$Res>  {
  factory $ThumbCopyWith(Thumb value, $Res Function(Thumb) _then) = _$ThumbCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "fileServer") String fileServer,@JsonKey(name: "path") String path,@JsonKey(name: "originalName") String originalName
});




}
/// @nodoc
class _$ThumbCopyWithImpl<$Res>
    implements $ThumbCopyWith<$Res> {
  _$ThumbCopyWithImpl(this._self, this._then);

  final Thumb _self;
  final $Res Function(Thumb) _then;

/// Create a copy of Thumb
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileServer = null,Object? path = null,Object? originalName = null,}) {
  return _then(_self.copyWith(
fileServer: null == fileServer ? _self.fileServer : fileServer // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,originalName: null == originalName ? _self.originalName : originalName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Thumb implements Thumb {
  const _Thumb({@JsonKey(name: "fileServer") required this.fileServer, @JsonKey(name: "path") required this.path, @JsonKey(name: "originalName") required this.originalName});
  factory _Thumb.fromJson(Map<String, dynamic> json) => _$ThumbFromJson(json);

@override@JsonKey(name: "fileServer") final  String fileServer;
@override@JsonKey(name: "path") final  String path;
@override@JsonKey(name: "originalName") final  String originalName;

/// Create a copy of Thumb
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ThumbCopyWith<_Thumb> get copyWith => __$ThumbCopyWithImpl<_Thumb>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ThumbToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Thumb&&(identical(other.fileServer, fileServer) || other.fileServer == fileServer)&&(identical(other.path, path) || other.path == path)&&(identical(other.originalName, originalName) || other.originalName == originalName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileServer,path,originalName);

@override
String toString() {
  return 'Thumb(fileServer: $fileServer, path: $path, originalName: $originalName)';
}


}

/// @nodoc
abstract mixin class _$ThumbCopyWith<$Res> implements $ThumbCopyWith<$Res> {
  factory _$ThumbCopyWith(_Thumb value, $Res Function(_Thumb) _then) = __$ThumbCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "fileServer") String fileServer,@JsonKey(name: "path") String path,@JsonKey(name: "originalName") String originalName
});




}
/// @nodoc
class __$ThumbCopyWithImpl<$Res>
    implements _$ThumbCopyWith<$Res> {
  __$ThumbCopyWithImpl(this._self, this._then);

  final _Thumb _self;
  final $Res Function(_Thumb) _then;

/// Create a copy of Thumb
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileServer = null,Object? path = null,Object? originalName = null,}) {
  return _then(_Thumb(
fileServer: null == fileServer ? _self.fileServer : fileServer // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,originalName: null == originalName ? _self.originalName : originalName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
