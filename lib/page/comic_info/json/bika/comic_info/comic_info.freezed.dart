// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comic_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ComicInfo {

@JsonKey(name: "code") int get code;@JsonKey(name: "message") String get message;@JsonKey(name: "data") Data get data;
/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicInfoCopyWith<ComicInfo> get copyWith => _$ComicInfoCopyWithImpl<ComicInfo>(this as ComicInfo, _$identity);

  /// Serializes this ComicInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicInfo&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'ComicInfo(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $ComicInfoCopyWith<$Res>  {
  factory $ComicInfoCopyWith(ComicInfo value, $Res Function(ComicInfo) _then) = _$ComicInfoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "code") int code,@JsonKey(name: "message") String message,@JsonKey(name: "data") Data data
});


$DataCopyWith<$Res> get data;

}
/// @nodoc
class _$ComicInfoCopyWithImpl<$Res>
    implements $ComicInfoCopyWith<$Res> {
  _$ComicInfoCopyWithImpl(this._self, this._then);

  final ComicInfo _self;
  final $Res Function(ComicInfo) _then;

/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? data = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Data,
  ));
}
/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataCopyWith<$Res> get data {
  
  return $DataCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [ComicInfo].
extension ComicInfoPatterns on ComicInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicInfo value)  $default,){
final _that = this;
switch (_that) {
case _ComicInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicInfo value)?  $default,){
final _that = this;
switch (_that) {
case _ComicInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "code")  int code, @JsonKey(name: "message")  String message, @JsonKey(name: "data")  Data data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicInfo() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "code")  int code, @JsonKey(name: "message")  String message, @JsonKey(name: "data")  Data data)  $default,) {final _that = this;
switch (_that) {
case _ComicInfo():
return $default(_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "code")  int code, @JsonKey(name: "message")  String message, @JsonKey(name: "data")  Data data)?  $default,) {final _that = this;
switch (_that) {
case _ComicInfo() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComicInfo implements ComicInfo {
  const _ComicInfo({@JsonKey(name: "code") required this.code, @JsonKey(name: "message") required this.message, @JsonKey(name: "data") required this.data});
  factory _ComicInfo.fromJson(Map<String, dynamic> json) => _$ComicInfoFromJson(json);

@override@JsonKey(name: "code") final  int code;
@override@JsonKey(name: "message") final  String message;
@override@JsonKey(name: "data") final  Data data;

/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicInfoCopyWith<_ComicInfo> get copyWith => __$ComicInfoCopyWithImpl<_ComicInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicInfo&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'ComicInfo(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$ComicInfoCopyWith<$Res> implements $ComicInfoCopyWith<$Res> {
  factory _$ComicInfoCopyWith(_ComicInfo value, $Res Function(_ComicInfo) _then) = __$ComicInfoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "code") int code,@JsonKey(name: "message") String message,@JsonKey(name: "data") Data data
});


@override $DataCopyWith<$Res> get data;

}
/// @nodoc
class __$ComicInfoCopyWithImpl<$Res>
    implements _$ComicInfoCopyWith<$Res> {
  __$ComicInfoCopyWithImpl(this._self, this._then);

  final _ComicInfo _self;
  final $Res Function(_ComicInfo) _then;

/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? data = null,}) {
  return _then(_ComicInfo(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Data,
  ));
}

/// Create a copy of ComicInfo
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

@JsonKey(name: "comic") Comic get comic;
/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataCopyWith<Data> get copyWith => _$DataCopyWithImpl<Data>(this as Data, _$identity);

  /// Serializes this Data to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Data&&(identical(other.comic, comic) || other.comic == comic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comic);

@override
String toString() {
  return 'Data(comic: $comic)';
}


}

/// @nodoc
abstract mixin class $DataCopyWith<$Res>  {
  factory $DataCopyWith(Data value, $Res Function(Data) _then) = _$DataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "comic") Comic comic
});


$ComicCopyWith<$Res> get comic;

}
/// @nodoc
class _$DataCopyWithImpl<$Res>
    implements $DataCopyWith<$Res> {
  _$DataCopyWithImpl(this._self, this._then);

  final Data _self;
  final $Res Function(Data) _then;

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? comic = null,}) {
  return _then(_self.copyWith(
comic: null == comic ? _self.comic : comic // ignore: cast_nullable_to_non_nullable
as Comic,
  ));
}
/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicCopyWith<$Res> get comic {
  
  return $ComicCopyWith<$Res>(_self.comic, (value) {
    return _then(_self.copyWith(comic: value));
  });
}
}


/// Adds pattern-matching-related methods to [Data].
extension DataPatterns on Data {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Data value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Data() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Data value)  $default,){
final _that = this;
switch (_that) {
case _Data():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Data value)?  $default,){
final _that = this;
switch (_that) {
case _Data() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "comic")  Comic comic)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Data() when $default != null:
return $default(_that.comic);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "comic")  Comic comic)  $default,) {final _that = this;
switch (_that) {
case _Data():
return $default(_that.comic);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "comic")  Comic comic)?  $default,) {final _that = this;
switch (_that) {
case _Data() when $default != null:
return $default(_that.comic);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Data implements Data {
  const _Data({@JsonKey(name: "comic") required this.comic});
  factory _Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);

@override@JsonKey(name: "comic") final  Comic comic;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Data&&(identical(other.comic, comic) || other.comic == comic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comic);

@override
String toString() {
  return 'Data(comic: $comic)';
}


}

/// @nodoc
abstract mixin class _$DataCopyWith<$Res> implements $DataCopyWith<$Res> {
  factory _$DataCopyWith(_Data value, $Res Function(_Data) _then) = __$DataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "comic") Comic comic
});


@override $ComicCopyWith<$Res> get comic;

}
/// @nodoc
class __$DataCopyWithImpl<$Res>
    implements _$DataCopyWith<$Res> {
  __$DataCopyWithImpl(this._self, this._then);

  final _Data _self;
  final $Res Function(_Data) _then;

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? comic = null,}) {
  return _then(_Data(
comic: null == comic ? _self.comic : comic // ignore: cast_nullable_to_non_nullable
as Comic,
  ));
}

/// Create a copy of Data
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

@JsonKey(name: "_id") String get id;@JsonKey(name: "_creator") Creator get creator;@JsonKey(name: "title") String get title;@JsonKey(name: "description") String get description;@JsonKey(name: "thumb") Thumb get thumb;@JsonKey(name: "author") String get author;@JsonKey(name: "chineseTeam") String get chineseTeam;@JsonKey(name: "categories") List<String> get categories;@JsonKey(name: "tags") List<String> get tags;@JsonKey(name: "pagesCount") int get pagesCount;@JsonKey(name: "epsCount") int get epsCount;@JsonKey(name: "finished") bool get finished;@JsonKey(name: "updated_at") DateTime get updatedAt;@JsonKey(name: "created_at") DateTime get createdAt;@JsonKey(name: "allowDownload") bool get allowDownload;@JsonKey(name: "allowComment") bool get allowComment;@JsonKey(name: "totalLikes") int get totalLikes;@JsonKey(name: "totalViews") int get totalViews;@JsonKey(name: "totalComments") int get totalComments;@JsonKey(name: "viewsCount") int get viewsCount;@JsonKey(name: "likesCount") int get likesCount;@JsonKey(name: "commentsCount") int get commentsCount;@JsonKey(name: "isFavourite") bool get isFavourite;@JsonKey(name: "isLiked") bool get isLiked;
/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicCopyWith<Comic> get copyWith => _$ComicCopyWithImpl<Comic>(this as Comic, _$identity);

  /// Serializes this Comic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Comic&&(identical(other.id, id) || other.id == id)&&(identical(other.creator, creator) || other.creator == creator)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.thumb, thumb) || other.thumb == thumb)&&(identical(other.author, author) || other.author == author)&&(identical(other.chineseTeam, chineseTeam) || other.chineseTeam == chineseTeam)&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.pagesCount, pagesCount) || other.pagesCount == pagesCount)&&(identical(other.epsCount, epsCount) || other.epsCount == epsCount)&&(identical(other.finished, finished) || other.finished == finished)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.allowDownload, allowDownload) || other.allowDownload == allowDownload)&&(identical(other.allowComment, allowComment) || other.allowComment == allowComment)&&(identical(other.totalLikes, totalLikes) || other.totalLikes == totalLikes)&&(identical(other.totalViews, totalViews) || other.totalViews == totalViews)&&(identical(other.totalComments, totalComments) || other.totalComments == totalComments)&&(identical(other.viewsCount, viewsCount) || other.viewsCount == viewsCount)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.commentsCount, commentsCount) || other.commentsCount == commentsCount)&&(identical(other.isFavourite, isFavourite) || other.isFavourite == isFavourite)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,creator,title,description,thumb,author,chineseTeam,const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(tags),pagesCount,epsCount,finished,updatedAt,createdAt,allowDownload,allowComment,totalLikes,totalViews,totalComments,viewsCount,likesCount,commentsCount,isFavourite,isLiked]);

@override
String toString() {
  return 'Comic(id: $id, creator: $creator, title: $title, description: $description, thumb: $thumb, author: $author, chineseTeam: $chineseTeam, categories: $categories, tags: $tags, pagesCount: $pagesCount, epsCount: $epsCount, finished: $finished, updatedAt: $updatedAt, createdAt: $createdAt, allowDownload: $allowDownload, allowComment: $allowComment, totalLikes: $totalLikes, totalViews: $totalViews, totalComments: $totalComments, viewsCount: $viewsCount, likesCount: $likesCount, commentsCount: $commentsCount, isFavourite: $isFavourite, isLiked: $isLiked)';
}


}

/// @nodoc
abstract mixin class $ComicCopyWith<$Res>  {
  factory $ComicCopyWith(Comic value, $Res Function(Comic) _then) = _$ComicCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "_creator") Creator creator,@JsonKey(name: "title") String title,@JsonKey(name: "description") String description,@JsonKey(name: "thumb") Thumb thumb,@JsonKey(name: "author") String author,@JsonKey(name: "chineseTeam") String chineseTeam,@JsonKey(name: "categories") List<String> categories,@JsonKey(name: "tags") List<String> tags,@JsonKey(name: "pagesCount") int pagesCount,@JsonKey(name: "epsCount") int epsCount,@JsonKey(name: "finished") bool finished,@JsonKey(name: "updated_at") DateTime updatedAt,@JsonKey(name: "created_at") DateTime createdAt,@JsonKey(name: "allowDownload") bool allowDownload,@JsonKey(name: "allowComment") bool allowComment,@JsonKey(name: "totalLikes") int totalLikes,@JsonKey(name: "totalViews") int totalViews,@JsonKey(name: "totalComments") int totalComments,@JsonKey(name: "viewsCount") int viewsCount,@JsonKey(name: "likesCount") int likesCount,@JsonKey(name: "commentsCount") int commentsCount,@JsonKey(name: "isFavourite") bool isFavourite,@JsonKey(name: "isLiked") bool isLiked
});


$CreatorCopyWith<$Res> get creator;$ThumbCopyWith<$Res> get thumb;

}
/// @nodoc
class _$ComicCopyWithImpl<$Res>
    implements $ComicCopyWith<$Res> {
  _$ComicCopyWithImpl(this._self, this._then);

  final Comic _self;
  final $Res Function(Comic) _then;

/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? creator = null,Object? title = null,Object? description = null,Object? thumb = null,Object? author = null,Object? chineseTeam = null,Object? categories = null,Object? tags = null,Object? pagesCount = null,Object? epsCount = null,Object? finished = null,Object? updatedAt = null,Object? createdAt = null,Object? allowDownload = null,Object? allowComment = null,Object? totalLikes = null,Object? totalViews = null,Object? totalComments = null,Object? viewsCount = null,Object? likesCount = null,Object? commentsCount = null,Object? isFavourite = null,Object? isLiked = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,creator: null == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as Creator,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,thumb: null == thumb ? _self.thumb : thumb // ignore: cast_nullable_to_non_nullable
as Thumb,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,chineseTeam: null == chineseTeam ? _self.chineseTeam : chineseTeam // ignore: cast_nullable_to_non_nullable
as String,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,pagesCount: null == pagesCount ? _self.pagesCount : pagesCount // ignore: cast_nullable_to_non_nullable
as int,epsCount: null == epsCount ? _self.epsCount : epsCount // ignore: cast_nullable_to_non_nullable
as int,finished: null == finished ? _self.finished : finished // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,allowDownload: null == allowDownload ? _self.allowDownload : allowDownload // ignore: cast_nullable_to_non_nullable
as bool,allowComment: null == allowComment ? _self.allowComment : allowComment // ignore: cast_nullable_to_non_nullable
as bool,totalLikes: null == totalLikes ? _self.totalLikes : totalLikes // ignore: cast_nullable_to_non_nullable
as int,totalViews: null == totalViews ? _self.totalViews : totalViews // ignore: cast_nullable_to_non_nullable
as int,totalComments: null == totalComments ? _self.totalComments : totalComments // ignore: cast_nullable_to_non_nullable
as int,viewsCount: null == viewsCount ? _self.viewsCount : viewsCount // ignore: cast_nullable_to_non_nullable
as int,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,commentsCount: null == commentsCount ? _self.commentsCount : commentsCount // ignore: cast_nullable_to_non_nullable
as int,isFavourite: null == isFavourite ? _self.isFavourite : isFavourite // ignore: cast_nullable_to_non_nullable
as bool,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CreatorCopyWith<$Res> get creator {
  
  return $CreatorCopyWith<$Res>(_self.creator, (value) {
    return _then(_self.copyWith(creator: value));
  });
}/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThumbCopyWith<$Res> get thumb {
  
  return $ThumbCopyWith<$Res>(_self.thumb, (value) {
    return _then(_self.copyWith(thumb: value));
  });
}
}


/// Adds pattern-matching-related methods to [Comic].
extension ComicPatterns on Comic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Comic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Comic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Comic value)  $default,){
final _that = this;
switch (_that) {
case _Comic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Comic value)?  $default,){
final _that = this;
switch (_that) {
case _Comic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "_creator")  Creator creator, @JsonKey(name: "title")  String title, @JsonKey(name: "description")  String description, @JsonKey(name: "thumb")  Thumb thumb, @JsonKey(name: "author")  String author, @JsonKey(name: "chineseTeam")  String chineseTeam, @JsonKey(name: "categories")  List<String> categories, @JsonKey(name: "tags")  List<String> tags, @JsonKey(name: "pagesCount")  int pagesCount, @JsonKey(name: "epsCount")  int epsCount, @JsonKey(name: "finished")  bool finished, @JsonKey(name: "updated_at")  DateTime updatedAt, @JsonKey(name: "created_at")  DateTime createdAt, @JsonKey(name: "allowDownload")  bool allowDownload, @JsonKey(name: "allowComment")  bool allowComment, @JsonKey(name: "totalLikes")  int totalLikes, @JsonKey(name: "totalViews")  int totalViews, @JsonKey(name: "totalComments")  int totalComments, @JsonKey(name: "viewsCount")  int viewsCount, @JsonKey(name: "likesCount")  int likesCount, @JsonKey(name: "commentsCount")  int commentsCount, @JsonKey(name: "isFavourite")  bool isFavourite, @JsonKey(name: "isLiked")  bool isLiked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Comic() when $default != null:
return $default(_that.id,_that.creator,_that.title,_that.description,_that.thumb,_that.author,_that.chineseTeam,_that.categories,_that.tags,_that.pagesCount,_that.epsCount,_that.finished,_that.updatedAt,_that.createdAt,_that.allowDownload,_that.allowComment,_that.totalLikes,_that.totalViews,_that.totalComments,_that.viewsCount,_that.likesCount,_that.commentsCount,_that.isFavourite,_that.isLiked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "_creator")  Creator creator, @JsonKey(name: "title")  String title, @JsonKey(name: "description")  String description, @JsonKey(name: "thumb")  Thumb thumb, @JsonKey(name: "author")  String author, @JsonKey(name: "chineseTeam")  String chineseTeam, @JsonKey(name: "categories")  List<String> categories, @JsonKey(name: "tags")  List<String> tags, @JsonKey(name: "pagesCount")  int pagesCount, @JsonKey(name: "epsCount")  int epsCount, @JsonKey(name: "finished")  bool finished, @JsonKey(name: "updated_at")  DateTime updatedAt, @JsonKey(name: "created_at")  DateTime createdAt, @JsonKey(name: "allowDownload")  bool allowDownload, @JsonKey(name: "allowComment")  bool allowComment, @JsonKey(name: "totalLikes")  int totalLikes, @JsonKey(name: "totalViews")  int totalViews, @JsonKey(name: "totalComments")  int totalComments, @JsonKey(name: "viewsCount")  int viewsCount, @JsonKey(name: "likesCount")  int likesCount, @JsonKey(name: "commentsCount")  int commentsCount, @JsonKey(name: "isFavourite")  bool isFavourite, @JsonKey(name: "isLiked")  bool isLiked)  $default,) {final _that = this;
switch (_that) {
case _Comic():
return $default(_that.id,_that.creator,_that.title,_that.description,_that.thumb,_that.author,_that.chineseTeam,_that.categories,_that.tags,_that.pagesCount,_that.epsCount,_that.finished,_that.updatedAt,_that.createdAt,_that.allowDownload,_that.allowComment,_that.totalLikes,_that.totalViews,_that.totalComments,_that.viewsCount,_that.likesCount,_that.commentsCount,_that.isFavourite,_that.isLiked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "_creator")  Creator creator, @JsonKey(name: "title")  String title, @JsonKey(name: "description")  String description, @JsonKey(name: "thumb")  Thumb thumb, @JsonKey(name: "author")  String author, @JsonKey(name: "chineseTeam")  String chineseTeam, @JsonKey(name: "categories")  List<String> categories, @JsonKey(name: "tags")  List<String> tags, @JsonKey(name: "pagesCount")  int pagesCount, @JsonKey(name: "epsCount")  int epsCount, @JsonKey(name: "finished")  bool finished, @JsonKey(name: "updated_at")  DateTime updatedAt, @JsonKey(name: "created_at")  DateTime createdAt, @JsonKey(name: "allowDownload")  bool allowDownload, @JsonKey(name: "allowComment")  bool allowComment, @JsonKey(name: "totalLikes")  int totalLikes, @JsonKey(name: "totalViews")  int totalViews, @JsonKey(name: "totalComments")  int totalComments, @JsonKey(name: "viewsCount")  int viewsCount, @JsonKey(name: "likesCount")  int likesCount, @JsonKey(name: "commentsCount")  int commentsCount, @JsonKey(name: "isFavourite")  bool isFavourite, @JsonKey(name: "isLiked")  bool isLiked)?  $default,) {final _that = this;
switch (_that) {
case _Comic() when $default != null:
return $default(_that.id,_that.creator,_that.title,_that.description,_that.thumb,_that.author,_that.chineseTeam,_that.categories,_that.tags,_that.pagesCount,_that.epsCount,_that.finished,_that.updatedAt,_that.createdAt,_that.allowDownload,_that.allowComment,_that.totalLikes,_that.totalViews,_that.totalComments,_that.viewsCount,_that.likesCount,_that.commentsCount,_that.isFavourite,_that.isLiked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Comic implements Comic {
  const _Comic({@JsonKey(name: "_id") required this.id, @JsonKey(name: "_creator") required this.creator, @JsonKey(name: "title") required this.title, @JsonKey(name: "description") required this.description, @JsonKey(name: "thumb") required this.thumb, @JsonKey(name: "author") required this.author, @JsonKey(name: "chineseTeam") required this.chineseTeam, @JsonKey(name: "categories") required final  List<String> categories, @JsonKey(name: "tags") required final  List<String> tags, @JsonKey(name: "pagesCount") required this.pagesCount, @JsonKey(name: "epsCount") required this.epsCount, @JsonKey(name: "finished") required this.finished, @JsonKey(name: "updated_at") required this.updatedAt, @JsonKey(name: "created_at") required this.createdAt, @JsonKey(name: "allowDownload") required this.allowDownload, @JsonKey(name: "allowComment") required this.allowComment, @JsonKey(name: "totalLikes") required this.totalLikes, @JsonKey(name: "totalViews") required this.totalViews, @JsonKey(name: "totalComments") required this.totalComments, @JsonKey(name: "viewsCount") required this.viewsCount, @JsonKey(name: "likesCount") required this.likesCount, @JsonKey(name: "commentsCount") required this.commentsCount, @JsonKey(name: "isFavourite") required this.isFavourite, @JsonKey(name: "isLiked") required this.isLiked}): _categories = categories,_tags = tags;
  factory _Comic.fromJson(Map<String, dynamic> json) => _$ComicFromJson(json);

@override@JsonKey(name: "_id") final  String id;
@override@JsonKey(name: "_creator") final  Creator creator;
@override@JsonKey(name: "title") final  String title;
@override@JsonKey(name: "description") final  String description;
@override@JsonKey(name: "thumb") final  Thumb thumb;
@override@JsonKey(name: "author") final  String author;
@override@JsonKey(name: "chineseTeam") final  String chineseTeam;
 final  List<String> _categories;
@override@JsonKey(name: "categories") List<String> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  List<String> _tags;
@override@JsonKey(name: "tags") List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey(name: "pagesCount") final  int pagesCount;
@override@JsonKey(name: "epsCount") final  int epsCount;
@override@JsonKey(name: "finished") final  bool finished;
@override@JsonKey(name: "updated_at") final  DateTime updatedAt;
@override@JsonKey(name: "created_at") final  DateTime createdAt;
@override@JsonKey(name: "allowDownload") final  bool allowDownload;
@override@JsonKey(name: "allowComment") final  bool allowComment;
@override@JsonKey(name: "totalLikes") final  int totalLikes;
@override@JsonKey(name: "totalViews") final  int totalViews;
@override@JsonKey(name: "totalComments") final  int totalComments;
@override@JsonKey(name: "viewsCount") final  int viewsCount;
@override@JsonKey(name: "likesCount") final  int likesCount;
@override@JsonKey(name: "commentsCount") final  int commentsCount;
@override@JsonKey(name: "isFavourite") final  bool isFavourite;
@override@JsonKey(name: "isLiked") final  bool isLiked;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Comic&&(identical(other.id, id) || other.id == id)&&(identical(other.creator, creator) || other.creator == creator)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.thumb, thumb) || other.thumb == thumb)&&(identical(other.author, author) || other.author == author)&&(identical(other.chineseTeam, chineseTeam) || other.chineseTeam == chineseTeam)&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.pagesCount, pagesCount) || other.pagesCount == pagesCount)&&(identical(other.epsCount, epsCount) || other.epsCount == epsCount)&&(identical(other.finished, finished) || other.finished == finished)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.allowDownload, allowDownload) || other.allowDownload == allowDownload)&&(identical(other.allowComment, allowComment) || other.allowComment == allowComment)&&(identical(other.totalLikes, totalLikes) || other.totalLikes == totalLikes)&&(identical(other.totalViews, totalViews) || other.totalViews == totalViews)&&(identical(other.totalComments, totalComments) || other.totalComments == totalComments)&&(identical(other.viewsCount, viewsCount) || other.viewsCount == viewsCount)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.commentsCount, commentsCount) || other.commentsCount == commentsCount)&&(identical(other.isFavourite, isFavourite) || other.isFavourite == isFavourite)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,creator,title,description,thumb,author,chineseTeam,const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_tags),pagesCount,epsCount,finished,updatedAt,createdAt,allowDownload,allowComment,totalLikes,totalViews,totalComments,viewsCount,likesCount,commentsCount,isFavourite,isLiked]);

@override
String toString() {
  return 'Comic(id: $id, creator: $creator, title: $title, description: $description, thumb: $thumb, author: $author, chineseTeam: $chineseTeam, categories: $categories, tags: $tags, pagesCount: $pagesCount, epsCount: $epsCount, finished: $finished, updatedAt: $updatedAt, createdAt: $createdAt, allowDownload: $allowDownload, allowComment: $allowComment, totalLikes: $totalLikes, totalViews: $totalViews, totalComments: $totalComments, viewsCount: $viewsCount, likesCount: $likesCount, commentsCount: $commentsCount, isFavourite: $isFavourite, isLiked: $isLiked)';
}


}

/// @nodoc
abstract mixin class _$ComicCopyWith<$Res> implements $ComicCopyWith<$Res> {
  factory _$ComicCopyWith(_Comic value, $Res Function(_Comic) _then) = __$ComicCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "_creator") Creator creator,@JsonKey(name: "title") String title,@JsonKey(name: "description") String description,@JsonKey(name: "thumb") Thumb thumb,@JsonKey(name: "author") String author,@JsonKey(name: "chineseTeam") String chineseTeam,@JsonKey(name: "categories") List<String> categories,@JsonKey(name: "tags") List<String> tags,@JsonKey(name: "pagesCount") int pagesCount,@JsonKey(name: "epsCount") int epsCount,@JsonKey(name: "finished") bool finished,@JsonKey(name: "updated_at") DateTime updatedAt,@JsonKey(name: "created_at") DateTime createdAt,@JsonKey(name: "allowDownload") bool allowDownload,@JsonKey(name: "allowComment") bool allowComment,@JsonKey(name: "totalLikes") int totalLikes,@JsonKey(name: "totalViews") int totalViews,@JsonKey(name: "totalComments") int totalComments,@JsonKey(name: "viewsCount") int viewsCount,@JsonKey(name: "likesCount") int likesCount,@JsonKey(name: "commentsCount") int commentsCount,@JsonKey(name: "isFavourite") bool isFavourite,@JsonKey(name: "isLiked") bool isLiked
});


@override $CreatorCopyWith<$Res> get creator;@override $ThumbCopyWith<$Res> get thumb;

}
/// @nodoc
class __$ComicCopyWithImpl<$Res>
    implements _$ComicCopyWith<$Res> {
  __$ComicCopyWithImpl(this._self, this._then);

  final _Comic _self;
  final $Res Function(_Comic) _then;

/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? creator = null,Object? title = null,Object? description = null,Object? thumb = null,Object? author = null,Object? chineseTeam = null,Object? categories = null,Object? tags = null,Object? pagesCount = null,Object? epsCount = null,Object? finished = null,Object? updatedAt = null,Object? createdAt = null,Object? allowDownload = null,Object? allowComment = null,Object? totalLikes = null,Object? totalViews = null,Object? totalComments = null,Object? viewsCount = null,Object? likesCount = null,Object? commentsCount = null,Object? isFavourite = null,Object? isLiked = null,}) {
  return _then(_Comic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,creator: null == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as Creator,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,thumb: null == thumb ? _self.thumb : thumb // ignore: cast_nullable_to_non_nullable
as Thumb,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,chineseTeam: null == chineseTeam ? _self.chineseTeam : chineseTeam // ignore: cast_nullable_to_non_nullable
as String,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,pagesCount: null == pagesCount ? _self.pagesCount : pagesCount // ignore: cast_nullable_to_non_nullable
as int,epsCount: null == epsCount ? _self.epsCount : epsCount // ignore: cast_nullable_to_non_nullable
as int,finished: null == finished ? _self.finished : finished // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,allowDownload: null == allowDownload ? _self.allowDownload : allowDownload // ignore: cast_nullable_to_non_nullable
as bool,allowComment: null == allowComment ? _self.allowComment : allowComment // ignore: cast_nullable_to_non_nullable
as bool,totalLikes: null == totalLikes ? _self.totalLikes : totalLikes // ignore: cast_nullable_to_non_nullable
as int,totalViews: null == totalViews ? _self.totalViews : totalViews // ignore: cast_nullable_to_non_nullable
as int,totalComments: null == totalComments ? _self.totalComments : totalComments // ignore: cast_nullable_to_non_nullable
as int,viewsCount: null == viewsCount ? _self.viewsCount : viewsCount // ignore: cast_nullable_to_non_nullable
as int,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,commentsCount: null == commentsCount ? _self.commentsCount : commentsCount // ignore: cast_nullable_to_non_nullable
as int,isFavourite: null == isFavourite ? _self.isFavourite : isFavourite // ignore: cast_nullable_to_non_nullable
as bool,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CreatorCopyWith<$Res> get creator {
  
  return $CreatorCopyWith<$Res>(_self.creator, (value) {
    return _then(_self.copyWith(creator: value));
  });
}/// Create a copy of Comic
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
mixin _$Creator {

@JsonKey(name: "_id") String get id;@JsonKey(name: "gender") String get gender;@JsonKey(name: "name") String get name;@JsonKey(name: "verified") bool get verified;@JsonKey(name: "exp") int get exp;@JsonKey(name: "level") int get level;@JsonKey(name: "characters") List<String> get characters;@JsonKey(name: "role") String get role;@JsonKey(name: "title") String get title;@JsonKey(name: "avatar") Thumb get avatar;@JsonKey(name: "slogan") String get slogan;
/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatorCopyWith<Creator> get copyWith => _$CreatorCopyWithImpl<Creator>(this as Creator, _$identity);

  /// Serializes this Creator to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Creator&&(identical(other.id, id) || other.id == id)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.name, name) || other.name == name)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.exp, exp) || other.exp == exp)&&(identical(other.level, level) || other.level == level)&&const DeepCollectionEquality().equals(other.characters, characters)&&(identical(other.role, role) || other.role == role)&&(identical(other.title, title) || other.title == title)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.slogan, slogan) || other.slogan == slogan));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,gender,name,verified,exp,level,const DeepCollectionEquality().hash(characters),role,title,avatar,slogan);

@override
String toString() {
  return 'Creator(id: $id, gender: $gender, name: $name, verified: $verified, exp: $exp, level: $level, characters: $characters, role: $role, title: $title, avatar: $avatar, slogan: $slogan)';
}


}

/// @nodoc
abstract mixin class $CreatorCopyWith<$Res>  {
  factory $CreatorCopyWith(Creator value, $Res Function(Creator) _then) = _$CreatorCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "gender") String gender,@JsonKey(name: "name") String name,@JsonKey(name: "verified") bool verified,@JsonKey(name: "exp") int exp,@JsonKey(name: "level") int level,@JsonKey(name: "characters") List<String> characters,@JsonKey(name: "role") String role,@JsonKey(name: "title") String title,@JsonKey(name: "avatar") Thumb avatar,@JsonKey(name: "slogan") String slogan
});


$ThumbCopyWith<$Res> get avatar;

}
/// @nodoc
class _$CreatorCopyWithImpl<$Res>
    implements $CreatorCopyWith<$Res> {
  _$CreatorCopyWithImpl(this._self, this._then);

  final Creator _self;
  final $Res Function(Creator) _then;

/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? gender = null,Object? name = null,Object? verified = null,Object? exp = null,Object? level = null,Object? characters = null,Object? role = null,Object? title = null,Object? avatar = null,Object? slogan = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,exp: null == exp ? _self.exp : exp // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,characters: null == characters ? _self.characters : characters // ignore: cast_nullable_to_non_nullable
as List<String>,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as Thumb,slogan: null == slogan ? _self.slogan : slogan // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThumbCopyWith<$Res> get avatar {
  
  return $ThumbCopyWith<$Res>(_self.avatar, (value) {
    return _then(_self.copyWith(avatar: value));
  });
}
}


/// Adds pattern-matching-related methods to [Creator].
extension CreatorPatterns on Creator {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Creator value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Creator() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Creator value)  $default,){
final _that = this;
switch (_that) {
case _Creator():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Creator value)?  $default,){
final _that = this;
switch (_that) {
case _Creator() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "gender")  String gender, @JsonKey(name: "name")  String name, @JsonKey(name: "verified")  bool verified, @JsonKey(name: "exp")  int exp, @JsonKey(name: "level")  int level, @JsonKey(name: "characters")  List<String> characters, @JsonKey(name: "role")  String role, @JsonKey(name: "title")  String title, @JsonKey(name: "avatar")  Thumb avatar, @JsonKey(name: "slogan")  String slogan)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Creator() when $default != null:
return $default(_that.id,_that.gender,_that.name,_that.verified,_that.exp,_that.level,_that.characters,_that.role,_that.title,_that.avatar,_that.slogan);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "gender")  String gender, @JsonKey(name: "name")  String name, @JsonKey(name: "verified")  bool verified, @JsonKey(name: "exp")  int exp, @JsonKey(name: "level")  int level, @JsonKey(name: "characters")  List<String> characters, @JsonKey(name: "role")  String role, @JsonKey(name: "title")  String title, @JsonKey(name: "avatar")  Thumb avatar, @JsonKey(name: "slogan")  String slogan)  $default,) {final _that = this;
switch (_that) {
case _Creator():
return $default(_that.id,_that.gender,_that.name,_that.verified,_that.exp,_that.level,_that.characters,_that.role,_that.title,_that.avatar,_that.slogan);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "gender")  String gender, @JsonKey(name: "name")  String name, @JsonKey(name: "verified")  bool verified, @JsonKey(name: "exp")  int exp, @JsonKey(name: "level")  int level, @JsonKey(name: "characters")  List<String> characters, @JsonKey(name: "role")  String role, @JsonKey(name: "title")  String title, @JsonKey(name: "avatar")  Thumb avatar, @JsonKey(name: "slogan")  String slogan)?  $default,) {final _that = this;
switch (_that) {
case _Creator() when $default != null:
return $default(_that.id,_that.gender,_that.name,_that.verified,_that.exp,_that.level,_that.characters,_that.role,_that.title,_that.avatar,_that.slogan);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Creator implements Creator {
  const _Creator({@JsonKey(name: "_id") required this.id, @JsonKey(name: "gender") required this.gender, @JsonKey(name: "name") required this.name, @JsonKey(name: "verified") required this.verified, @JsonKey(name: "exp") required this.exp, @JsonKey(name: "level") required this.level, @JsonKey(name: "characters") required final  List<String> characters, @JsonKey(name: "role") required this.role, @JsonKey(name: "title") required this.title, @JsonKey(name: "avatar") required this.avatar, @JsonKey(name: "slogan") required this.slogan}): _characters = characters;
  factory _Creator.fromJson(Map<String, dynamic> json) => _$CreatorFromJson(json);

@override@JsonKey(name: "_id") final  String id;
@override@JsonKey(name: "gender") final  String gender;
@override@JsonKey(name: "name") final  String name;
@override@JsonKey(name: "verified") final  bool verified;
@override@JsonKey(name: "exp") final  int exp;
@override@JsonKey(name: "level") final  int level;
 final  List<String> _characters;
@override@JsonKey(name: "characters") List<String> get characters {
  if (_characters is EqualUnmodifiableListView) return _characters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_characters);
}

@override@JsonKey(name: "role") final  String role;
@override@JsonKey(name: "title") final  String title;
@override@JsonKey(name: "avatar") final  Thumb avatar;
@override@JsonKey(name: "slogan") final  String slogan;

/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatorCopyWith<_Creator> get copyWith => __$CreatorCopyWithImpl<_Creator>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreatorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Creator&&(identical(other.id, id) || other.id == id)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.name, name) || other.name == name)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.exp, exp) || other.exp == exp)&&(identical(other.level, level) || other.level == level)&&const DeepCollectionEquality().equals(other._characters, _characters)&&(identical(other.role, role) || other.role == role)&&(identical(other.title, title) || other.title == title)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.slogan, slogan) || other.slogan == slogan));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,gender,name,verified,exp,level,const DeepCollectionEquality().hash(_characters),role,title,avatar,slogan);

@override
String toString() {
  return 'Creator(id: $id, gender: $gender, name: $name, verified: $verified, exp: $exp, level: $level, characters: $characters, role: $role, title: $title, avatar: $avatar, slogan: $slogan)';
}


}

/// @nodoc
abstract mixin class _$CreatorCopyWith<$Res> implements $CreatorCopyWith<$Res> {
  factory _$CreatorCopyWith(_Creator value, $Res Function(_Creator) _then) = __$CreatorCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "gender") String gender,@JsonKey(name: "name") String name,@JsonKey(name: "verified") bool verified,@JsonKey(name: "exp") int exp,@JsonKey(name: "level") int level,@JsonKey(name: "characters") List<String> characters,@JsonKey(name: "role") String role,@JsonKey(name: "title") String title,@JsonKey(name: "avatar") Thumb avatar,@JsonKey(name: "slogan") String slogan
});


@override $ThumbCopyWith<$Res> get avatar;

}
/// @nodoc
class __$CreatorCopyWithImpl<$Res>
    implements _$CreatorCopyWith<$Res> {
  __$CreatorCopyWithImpl(this._self, this._then);

  final _Creator _self;
  final $Res Function(_Creator) _then;

/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? gender = null,Object? name = null,Object? verified = null,Object? exp = null,Object? level = null,Object? characters = null,Object? role = null,Object? title = null,Object? avatar = null,Object? slogan = null,}) {
  return _then(_Creator(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,exp: null == exp ? _self.exp : exp // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,characters: null == characters ? _self._characters : characters // ignore: cast_nullable_to_non_nullable
as List<String>,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as Thumb,slogan: null == slogan ? _self.slogan : slogan // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThumbCopyWith<$Res> get avatar {
  
  return $ThumbCopyWith<$Res>(_self.avatar, (value) {
    return _then(_self.copyWith(avatar: value));
  });
}
}


/// @nodoc
mixin _$Thumb {

@JsonKey(name: "originalName") String get originalName;@JsonKey(name: "path") String get path;@JsonKey(name: "fileServer") String get fileServer;
/// Create a copy of Thumb
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ThumbCopyWith<Thumb> get copyWith => _$ThumbCopyWithImpl<Thumb>(this as Thumb, _$identity);

  /// Serializes this Thumb to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Thumb&&(identical(other.originalName, originalName) || other.originalName == originalName)&&(identical(other.path, path) || other.path == path)&&(identical(other.fileServer, fileServer) || other.fileServer == fileServer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,originalName,path,fileServer);

@override
String toString() {
  return 'Thumb(originalName: $originalName, path: $path, fileServer: $fileServer)';
}


}

/// @nodoc
abstract mixin class $ThumbCopyWith<$Res>  {
  factory $ThumbCopyWith(Thumb value, $Res Function(Thumb) _then) = _$ThumbCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "originalName") String originalName,@JsonKey(name: "path") String path,@JsonKey(name: "fileServer") String fileServer
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
@pragma('vm:prefer-inline') @override $Res call({Object? originalName = null,Object? path = null,Object? fileServer = null,}) {
  return _then(_self.copyWith(
originalName: null == originalName ? _self.originalName : originalName // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,fileServer: null == fileServer ? _self.fileServer : fileServer // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Thumb].
extension ThumbPatterns on Thumb {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Thumb value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Thumb() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Thumb value)  $default,){
final _that = this;
switch (_that) {
case _Thumb():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Thumb value)?  $default,){
final _that = this;
switch (_that) {
case _Thumb() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "originalName")  String originalName, @JsonKey(name: "path")  String path, @JsonKey(name: "fileServer")  String fileServer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Thumb() when $default != null:
return $default(_that.originalName,_that.path,_that.fileServer);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "originalName")  String originalName, @JsonKey(name: "path")  String path, @JsonKey(name: "fileServer")  String fileServer)  $default,) {final _that = this;
switch (_that) {
case _Thumb():
return $default(_that.originalName,_that.path,_that.fileServer);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "originalName")  String originalName, @JsonKey(name: "path")  String path, @JsonKey(name: "fileServer")  String fileServer)?  $default,) {final _that = this;
switch (_that) {
case _Thumb() when $default != null:
return $default(_that.originalName,_that.path,_that.fileServer);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Thumb implements Thumb {
  const _Thumb({@JsonKey(name: "originalName") required this.originalName, @JsonKey(name: "path") required this.path, @JsonKey(name: "fileServer") required this.fileServer});
  factory _Thumb.fromJson(Map<String, dynamic> json) => _$ThumbFromJson(json);

@override@JsonKey(name: "originalName") final  String originalName;
@override@JsonKey(name: "path") final  String path;
@override@JsonKey(name: "fileServer") final  String fileServer;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Thumb&&(identical(other.originalName, originalName) || other.originalName == originalName)&&(identical(other.path, path) || other.path == path)&&(identical(other.fileServer, fileServer) || other.fileServer == fileServer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,originalName,path,fileServer);

@override
String toString() {
  return 'Thumb(originalName: $originalName, path: $path, fileServer: $fileServer)';
}


}

/// @nodoc
abstract mixin class _$ThumbCopyWith<$Res> implements $ThumbCopyWith<$Res> {
  factory _$ThumbCopyWith(_Thumb value, $Res Function(_Thumb) _then) = __$ThumbCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "originalName") String originalName,@JsonKey(name: "path") String path,@JsonKey(name: "fileServer") String fileServer
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
@override @pragma('vm:prefer-inline') $Res call({Object? originalName = null,Object? path = null,Object? fileServer = null,}) {
  return _then(_Thumb(
originalName: null == originalName ? _self.originalName : originalName // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,fileServer: null == fileServer ? _self.fileServer : fileServer // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
