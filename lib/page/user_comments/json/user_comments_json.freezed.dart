// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_comments_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserCommentsJson {

@JsonKey(name: "code") int get code;@JsonKey(name: "message") String get message;@JsonKey(name: "data") Data get data;
/// Create a copy of UserCommentsJson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCommentsJsonCopyWith<UserCommentsJson> get copyWith => _$UserCommentsJsonCopyWithImpl<UserCommentsJson>(this as UserCommentsJson, _$identity);

  /// Serializes this UserCommentsJson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserCommentsJson&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'UserCommentsJson(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $UserCommentsJsonCopyWith<$Res>  {
  factory $UserCommentsJsonCopyWith(UserCommentsJson value, $Res Function(UserCommentsJson) _then) = _$UserCommentsJsonCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "code") int code,@JsonKey(name: "message") String message,@JsonKey(name: "data") Data data
});


$DataCopyWith<$Res> get data;

}
/// @nodoc
class _$UserCommentsJsonCopyWithImpl<$Res>
    implements $UserCommentsJsonCopyWith<$Res> {
  _$UserCommentsJsonCopyWithImpl(this._self, this._then);

  final UserCommentsJson _self;
  final $Res Function(UserCommentsJson) _then;

/// Create a copy of UserCommentsJson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? data = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Data,
  ));
}
/// Create a copy of UserCommentsJson
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

class _UserCommentsJson implements UserCommentsJson {
  const _UserCommentsJson({@JsonKey(name: "code") required this.code, @JsonKey(name: "message") required this.message, @JsonKey(name: "data") required this.data});
  factory _UserCommentsJson.fromJson(Map<String, dynamic> json) => _$UserCommentsJsonFromJson(json);

@override@JsonKey(name: "code") final  int code;
@override@JsonKey(name: "message") final  String message;
@override@JsonKey(name: "data") final  Data data;

/// Create a copy of UserCommentsJson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCommentsJsonCopyWith<_UserCommentsJson> get copyWith => __$UserCommentsJsonCopyWithImpl<_UserCommentsJson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserCommentsJsonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserCommentsJson&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'UserCommentsJson(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$UserCommentsJsonCopyWith<$Res> implements $UserCommentsJsonCopyWith<$Res> {
  factory _$UserCommentsJsonCopyWith(_UserCommentsJson value, $Res Function(_UserCommentsJson) _then) = __$UserCommentsJsonCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "code") int code,@JsonKey(name: "message") String message,@JsonKey(name: "data") Data data
});


@override $DataCopyWith<$Res> get data;

}
/// @nodoc
class __$UserCommentsJsonCopyWithImpl<$Res>
    implements _$UserCommentsJsonCopyWith<$Res> {
  __$UserCommentsJsonCopyWithImpl(this._self, this._then);

  final _UserCommentsJson _self;
  final $Res Function(_UserCommentsJson) _then;

/// Create a copy of UserCommentsJson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? data = null,}) {
  return _then(_UserCommentsJson(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Data,
  ));
}

/// Create a copy of UserCommentsJson
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

@JsonKey(name: "comments") Comments get comments;
/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataCopyWith<Data> get copyWith => _$DataCopyWithImpl<Data>(this as Data, _$identity);

  /// Serializes this Data to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Data&&(identical(other.comments, comments) || other.comments == comments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comments);

@override
String toString() {
  return 'Data(comments: $comments)';
}


}

/// @nodoc
abstract mixin class $DataCopyWith<$Res>  {
  factory $DataCopyWith(Data value, $Res Function(Data) _then) = _$DataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "comments") Comments comments
});


$CommentsCopyWith<$Res> get comments;

}
/// @nodoc
class _$DataCopyWithImpl<$Res>
    implements $DataCopyWith<$Res> {
  _$DataCopyWithImpl(this._self, this._then);

  final Data _self;
  final $Res Function(Data) _then;

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? comments = null,}) {
  return _then(_self.copyWith(
comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as Comments,
  ));
}
/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommentsCopyWith<$Res> get comments {
  
  return $CommentsCopyWith<$Res>(_self.comments, (value) {
    return _then(_self.copyWith(comments: value));
  });
}
}


/// @nodoc
@JsonSerializable()

class _Data implements Data {
  const _Data({@JsonKey(name: "comments") required this.comments});
  factory _Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);

@override@JsonKey(name: "comments") final  Comments comments;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Data&&(identical(other.comments, comments) || other.comments == comments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comments);

@override
String toString() {
  return 'Data(comments: $comments)';
}


}

/// @nodoc
abstract mixin class _$DataCopyWith<$Res> implements $DataCopyWith<$Res> {
  factory _$DataCopyWith(_Data value, $Res Function(_Data) _then) = __$DataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "comments") Comments comments
});


@override $CommentsCopyWith<$Res> get comments;

}
/// @nodoc
class __$DataCopyWithImpl<$Res>
    implements _$DataCopyWith<$Res> {
  __$DataCopyWithImpl(this._self, this._then);

  final _Data _self;
  final $Res Function(_Data) _then;

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? comments = null,}) {
  return _then(_Data(
comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as Comments,
  ));
}

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommentsCopyWith<$Res> get comments {
  
  return $CommentsCopyWith<$Res>(_self.comments, (value) {
    return _then(_self.copyWith(comments: value));
  });
}
}


/// @nodoc
mixin _$Comments {

@JsonKey(name: "docs") List<Doc> get docs;@JsonKey(name: "total") int get total;@JsonKey(name: "limit") int get limit;@JsonKey(name: "page") String get page;@JsonKey(name: "pages") int get pages;
/// Create a copy of Comments
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentsCopyWith<Comments> get copyWith => _$CommentsCopyWithImpl<Comments>(this as Comments, _$identity);

  /// Serializes this Comments to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Comments&&const DeepCollectionEquality().equals(other.docs, docs)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.page, page) || other.page == page)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(docs),total,limit,page,pages);

@override
String toString() {
  return 'Comments(docs: $docs, total: $total, limit: $limit, page: $page, pages: $pages)';
}


}

/// @nodoc
abstract mixin class $CommentsCopyWith<$Res>  {
  factory $CommentsCopyWith(Comments value, $Res Function(Comments) _then) = _$CommentsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "docs") List<Doc> docs,@JsonKey(name: "total") int total,@JsonKey(name: "limit") int limit,@JsonKey(name: "page") String page,@JsonKey(name: "pages") int pages
});




}
/// @nodoc
class _$CommentsCopyWithImpl<$Res>
    implements $CommentsCopyWith<$Res> {
  _$CommentsCopyWithImpl(this._self, this._then);

  final Comments _self;
  final $Res Function(Comments) _then;

/// Create a copy of Comments
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? docs = null,Object? total = null,Object? limit = null,Object? page = null,Object? pages = null,}) {
  return _then(_self.copyWith(
docs: null == docs ? _self.docs : docs // ignore: cast_nullable_to_non_nullable
as List<Doc>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as String,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Comments implements Comments {
  const _Comments({@JsonKey(name: "docs") required final  List<Doc> docs, @JsonKey(name: "total") required this.total, @JsonKey(name: "limit") required this.limit, @JsonKey(name: "page") required this.page, @JsonKey(name: "pages") required this.pages}): _docs = docs;
  factory _Comments.fromJson(Map<String, dynamic> json) => _$CommentsFromJson(json);

 final  List<Doc> _docs;
@override@JsonKey(name: "docs") List<Doc> get docs {
  if (_docs is EqualUnmodifiableListView) return _docs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_docs);
}

@override@JsonKey(name: "total") final  int total;
@override@JsonKey(name: "limit") final  int limit;
@override@JsonKey(name: "page") final  String page;
@override@JsonKey(name: "pages") final  int pages;

/// Create a copy of Comments
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentsCopyWith<_Comments> get copyWith => __$CommentsCopyWithImpl<_Comments>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Comments&&const DeepCollectionEquality().equals(other._docs, _docs)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.page, page) || other.page == page)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_docs),total,limit,page,pages);

@override
String toString() {
  return 'Comments(docs: $docs, total: $total, limit: $limit, page: $page, pages: $pages)';
}


}

/// @nodoc
abstract mixin class _$CommentsCopyWith<$Res> implements $CommentsCopyWith<$Res> {
  factory _$CommentsCopyWith(_Comments value, $Res Function(_Comments) _then) = __$CommentsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "docs") List<Doc> docs,@JsonKey(name: "total") int total,@JsonKey(name: "limit") int limit,@JsonKey(name: "page") String page,@JsonKey(name: "pages") int pages
});




}
/// @nodoc
class __$CommentsCopyWithImpl<$Res>
    implements _$CommentsCopyWith<$Res> {
  __$CommentsCopyWithImpl(this._self, this._then);

  final _Comments _self;
  final $Res Function(_Comments) _then;

/// Create a copy of Comments
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? docs = null,Object? total = null,Object? limit = null,Object? page = null,Object? pages = null,}) {
  return _then(_Comments(
docs: null == docs ? _self._docs : docs // ignore: cast_nullable_to_non_nullable
as List<Doc>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as String,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Doc {

@JsonKey(name: "_id") String get id;@JsonKey(name: "content") String get content;@JsonKey(name: "_comic") Comic get comic;@JsonKey(name: "totalComments") int get totalComments;@JsonKey(name: "hide") bool get hide;@JsonKey(name: "created_at") DateTime get createdAt;@JsonKey(name: "id") String get docId;@JsonKey(name: "likesCount") int get likesCount;@JsonKey(name: "commentsCount") int get commentsCount;@JsonKey(name: "isLiked") bool get isLiked;
/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocCopyWith<Doc> get copyWith => _$DocCopyWithImpl<Doc>(this as Doc, _$identity);

  /// Serializes this Doc to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Doc&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.comic, comic) || other.comic == comic)&&(identical(other.totalComments, totalComments) || other.totalComments == totalComments)&&(identical(other.hide, hide) || other.hide == hide)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.docId, docId) || other.docId == docId)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.commentsCount, commentsCount) || other.commentsCount == commentsCount)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,content,comic,totalComments,hide,createdAt,docId,likesCount,commentsCount,isLiked);

@override
String toString() {
  return 'Doc(id: $id, content: $content, comic: $comic, totalComments: $totalComments, hide: $hide, createdAt: $createdAt, docId: $docId, likesCount: $likesCount, commentsCount: $commentsCount, isLiked: $isLiked)';
}


}

/// @nodoc
abstract mixin class $DocCopyWith<$Res>  {
  factory $DocCopyWith(Doc value, $Res Function(Doc) _then) = _$DocCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "content") String content,@JsonKey(name: "_comic") Comic comic,@JsonKey(name: "totalComments") int totalComments,@JsonKey(name: "hide") bool hide,@JsonKey(name: "created_at") DateTime createdAt,@JsonKey(name: "id") String docId,@JsonKey(name: "likesCount") int likesCount,@JsonKey(name: "commentsCount") int commentsCount,@JsonKey(name: "isLiked") bool isLiked
});


$ComicCopyWith<$Res> get comic;

}
/// @nodoc
class _$DocCopyWithImpl<$Res>
    implements $DocCopyWith<$Res> {
  _$DocCopyWithImpl(this._self, this._then);

  final Doc _self;
  final $Res Function(Doc) _then;

/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? content = null,Object? comic = null,Object? totalComments = null,Object? hide = null,Object? createdAt = null,Object? docId = null,Object? likesCount = null,Object? commentsCount = null,Object? isLiked = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,comic: null == comic ? _self.comic : comic // ignore: cast_nullable_to_non_nullable
as Comic,totalComments: null == totalComments ? _self.totalComments : totalComments // ignore: cast_nullable_to_non_nullable
as int,hide: null == hide ? _self.hide : hide // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,docId: null == docId ? _self.docId : docId // ignore: cast_nullable_to_non_nullable
as String,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,commentsCount: null == commentsCount ? _self.commentsCount : commentsCount // ignore: cast_nullable_to_non_nullable
as int,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicCopyWith<$Res> get comic {
  
  return $ComicCopyWith<$Res>(_self.comic, (value) {
    return _then(_self.copyWith(comic: value));
  });
}
}


/// @nodoc
@JsonSerializable()

class _Doc implements Doc {
  const _Doc({@JsonKey(name: "_id") required this.id, @JsonKey(name: "content") required this.content, @JsonKey(name: "_comic") required this.comic, @JsonKey(name: "totalComments") required this.totalComments, @JsonKey(name: "hide") required this.hide, @JsonKey(name: "created_at") required this.createdAt, @JsonKey(name: "id") required this.docId, @JsonKey(name: "likesCount") required this.likesCount, @JsonKey(name: "commentsCount") required this.commentsCount, @JsonKey(name: "isLiked") required this.isLiked});
  factory _Doc.fromJson(Map<String, dynamic> json) => _$DocFromJson(json);

@override@JsonKey(name: "_id") final  String id;
@override@JsonKey(name: "content") final  String content;
@override@JsonKey(name: "_comic") final  Comic comic;
@override@JsonKey(name: "totalComments") final  int totalComments;
@override@JsonKey(name: "hide") final  bool hide;
@override@JsonKey(name: "created_at") final  DateTime createdAt;
@override@JsonKey(name: "id") final  String docId;
@override@JsonKey(name: "likesCount") final  int likesCount;
@override@JsonKey(name: "commentsCount") final  int commentsCount;
@override@JsonKey(name: "isLiked") final  bool isLiked;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Doc&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.comic, comic) || other.comic == comic)&&(identical(other.totalComments, totalComments) || other.totalComments == totalComments)&&(identical(other.hide, hide) || other.hide == hide)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.docId, docId) || other.docId == docId)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.commentsCount, commentsCount) || other.commentsCount == commentsCount)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,content,comic,totalComments,hide,createdAt,docId,likesCount,commentsCount,isLiked);

@override
String toString() {
  return 'Doc(id: $id, content: $content, comic: $comic, totalComments: $totalComments, hide: $hide, createdAt: $createdAt, docId: $docId, likesCount: $likesCount, commentsCount: $commentsCount, isLiked: $isLiked)';
}


}

/// @nodoc
abstract mixin class _$DocCopyWith<$Res> implements $DocCopyWith<$Res> {
  factory _$DocCopyWith(_Doc value, $Res Function(_Doc) _then) = __$DocCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "content") String content,@JsonKey(name: "_comic") Comic comic,@JsonKey(name: "totalComments") int totalComments,@JsonKey(name: "hide") bool hide,@JsonKey(name: "created_at") DateTime createdAt,@JsonKey(name: "id") String docId,@JsonKey(name: "likesCount") int likesCount,@JsonKey(name: "commentsCount") int commentsCount,@JsonKey(name: "isLiked") bool isLiked
});


@override $ComicCopyWith<$Res> get comic;

}
/// @nodoc
class __$DocCopyWithImpl<$Res>
    implements _$DocCopyWith<$Res> {
  __$DocCopyWithImpl(this._self, this._then);

  final _Doc _self;
  final $Res Function(_Doc) _then;

/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? content = null,Object? comic = null,Object? totalComments = null,Object? hide = null,Object? createdAt = null,Object? docId = null,Object? likesCount = null,Object? commentsCount = null,Object? isLiked = null,}) {
  return _then(_Doc(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,comic: null == comic ? _self.comic : comic // ignore: cast_nullable_to_non_nullable
as Comic,totalComments: null == totalComments ? _self.totalComments : totalComments // ignore: cast_nullable_to_non_nullable
as int,hide: null == hide ? _self.hide : hide // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,docId: null == docId ? _self.docId : docId // ignore: cast_nullable_to_non_nullable
as String,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,commentsCount: null == commentsCount ? _self.commentsCount : commentsCount // ignore: cast_nullable_to_non_nullable
as int,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicCopyWith<$Res> get comic {
  
  return $ComicCopyWith<$Res>(_self.comic, (value) {
    return _then(_self.copyWith(comic: value));
  });
}
}


/// @nodoc
mixin _$Comic {

@JsonKey(name: "_id") String get id;@JsonKey(name: "title") String get title;
/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicCopyWith<Comic> get copyWith => _$ComicCopyWithImpl<Comic>(this as Comic, _$identity);

  /// Serializes this Comic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Comic&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title);

@override
String toString() {
  return 'Comic(id: $id, title: $title)';
}


}

/// @nodoc
abstract mixin class $ComicCopyWith<$Res>  {
  factory $ComicCopyWith(Comic value, $Res Function(Comic) _then) = _$ComicCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "title") String title
});




}
/// @nodoc
class _$ComicCopyWithImpl<$Res>
    implements $ComicCopyWith<$Res> {
  _$ComicCopyWithImpl(this._self, this._then);

  final Comic _self;
  final $Res Function(Comic) _then;

/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Comic implements Comic {
  const _Comic({@JsonKey(name: "_id") required this.id, @JsonKey(name: "title") required this.title});
  factory _Comic.fromJson(Map<String, dynamic> json) => _$ComicFromJson(json);

@override@JsonKey(name: "_id") final  String id;
@override@JsonKey(name: "title") final  String title;

/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicCopyWith<_Comic> get copyWith => __$ComicCopyWithImpl<_Comic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Comic&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title);

@override
String toString() {
  return 'Comic(id: $id, title: $title)';
}


}

/// @nodoc
abstract mixin class _$ComicCopyWith<$Res> implements $ComicCopyWith<$Res> {
  factory _$ComicCopyWith(_Comic value, $Res Function(_Comic) _then) = __$ComicCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "title") String title
});




}
/// @nodoc
class __$ComicCopyWithImpl<$Res>
    implements _$ComicCopyWith<$Res> {
  __$ComicCopyWithImpl(this._self, this._then);

  final _Comic _self;
  final $Res Function(_Comic) _then;

/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,}) {
  return _then(_Comic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
