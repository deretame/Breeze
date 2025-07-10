// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comic_all_info_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ComicAllInfoJson {

@JsonKey(name: "comic") Comic get comic;@JsonKey(name: "eps") Eps get eps;
/// Create a copy of ComicAllInfoJson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicAllInfoJsonCopyWith<ComicAllInfoJson> get copyWith => _$ComicAllInfoJsonCopyWithImpl<ComicAllInfoJson>(this as ComicAllInfoJson, _$identity);

  /// Serializes this ComicAllInfoJson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicAllInfoJson&&(identical(other.comic, comic) || other.comic == comic)&&(identical(other.eps, eps) || other.eps == eps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comic,eps);

@override
String toString() {
  return 'ComicAllInfoJson(comic: $comic, eps: $eps)';
}


}

/// @nodoc
abstract mixin class $ComicAllInfoJsonCopyWith<$Res>  {
  factory $ComicAllInfoJsonCopyWith(ComicAllInfoJson value, $Res Function(ComicAllInfoJson) _then) = _$ComicAllInfoJsonCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "comic") Comic comic,@JsonKey(name: "eps") Eps eps
});


$ComicCopyWith<$Res> get comic;$EpsCopyWith<$Res> get eps;

}
/// @nodoc
class _$ComicAllInfoJsonCopyWithImpl<$Res>
    implements $ComicAllInfoJsonCopyWith<$Res> {
  _$ComicAllInfoJsonCopyWithImpl(this._self, this._then);

  final ComicAllInfoJson _self;
  final $Res Function(ComicAllInfoJson) _then;

/// Create a copy of ComicAllInfoJson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? comic = null,Object? eps = null,}) {
  return _then(_self.copyWith(
comic: null == comic ? _self.comic : comic // ignore: cast_nullable_to_non_nullable
as Comic,eps: null == eps ? _self.eps : eps // ignore: cast_nullable_to_non_nullable
as Eps,
  ));
}
/// Create a copy of ComicAllInfoJson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicCopyWith<$Res> get comic {
  
  return $ComicCopyWith<$Res>(_self.comic, (value) {
    return _then(_self.copyWith(comic: value));
  });
}/// Create a copy of ComicAllInfoJson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EpsCopyWith<$Res> get eps {
  
  return $EpsCopyWith<$Res>(_self.eps, (value) {
    return _then(_self.copyWith(eps: value));
  });
}
}


/// Adds pattern-matching-related methods to [ComicAllInfoJson].
extension ComicAllInfoJsonPatterns on ComicAllInfoJson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicAllInfoJson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicAllInfoJson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicAllInfoJson value)  $default,){
final _that = this;
switch (_that) {
case _ComicAllInfoJson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicAllInfoJson value)?  $default,){
final _that = this;
switch (_that) {
case _ComicAllInfoJson() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "comic")  Comic comic, @JsonKey(name: "eps")  Eps eps)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicAllInfoJson() when $default != null:
return $default(_that.comic,_that.eps);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "comic")  Comic comic, @JsonKey(name: "eps")  Eps eps)  $default,) {final _that = this;
switch (_that) {
case _ComicAllInfoJson():
return $default(_that.comic,_that.eps);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "comic")  Comic comic, @JsonKey(name: "eps")  Eps eps)?  $default,) {final _that = this;
switch (_that) {
case _ComicAllInfoJson() when $default != null:
return $default(_that.comic,_that.eps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComicAllInfoJson implements ComicAllInfoJson {
  const _ComicAllInfoJson({@JsonKey(name: "comic") required this.comic, @JsonKey(name: "eps") required this.eps});
  factory _ComicAllInfoJson.fromJson(Map<String, dynamic> json) => _$ComicAllInfoJsonFromJson(json);

@override@JsonKey(name: "comic") final  Comic comic;
@override@JsonKey(name: "eps") final  Eps eps;

/// Create a copy of ComicAllInfoJson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicAllInfoJsonCopyWith<_ComicAllInfoJson> get copyWith => __$ComicAllInfoJsonCopyWithImpl<_ComicAllInfoJson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicAllInfoJsonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicAllInfoJson&&(identical(other.comic, comic) || other.comic == comic)&&(identical(other.eps, eps) || other.eps == eps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comic,eps);

@override
String toString() {
  return 'ComicAllInfoJson(comic: $comic, eps: $eps)';
}


}

/// @nodoc
abstract mixin class _$ComicAllInfoJsonCopyWith<$Res> implements $ComicAllInfoJsonCopyWith<$Res> {
  factory _$ComicAllInfoJsonCopyWith(_ComicAllInfoJson value, $Res Function(_ComicAllInfoJson) _then) = __$ComicAllInfoJsonCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "comic") Comic comic,@JsonKey(name: "eps") Eps eps
});


@override $ComicCopyWith<$Res> get comic;@override $EpsCopyWith<$Res> get eps;

}
/// @nodoc
class __$ComicAllInfoJsonCopyWithImpl<$Res>
    implements _$ComicAllInfoJsonCopyWith<$Res> {
  __$ComicAllInfoJsonCopyWithImpl(this._self, this._then);

  final _ComicAllInfoJson _self;
  final $Res Function(_ComicAllInfoJson) _then;

/// Create a copy of ComicAllInfoJson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? comic = null,Object? eps = null,}) {
  return _then(_ComicAllInfoJson(
comic: null == comic ? _self.comic : comic // ignore: cast_nullable_to_non_nullable
as Comic,eps: null == eps ? _self.eps : eps // ignore: cast_nullable_to_non_nullable
as Eps,
  ));
}

/// Create a copy of ComicAllInfoJson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicCopyWith<$Res> get comic {
  
  return $ComicCopyWith<$Res>(_self.comic, (value) {
    return _then(_self.copyWith(comic: value));
  });
}/// Create a copy of ComicAllInfoJson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EpsCopyWith<$Res> get eps {
  
  return $EpsCopyWith<$Res>(_self.eps, (value) {
    return _then(_self.copyWith(eps: value));
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

@JsonKey(name: "_id") String get id;@JsonKey(name: "gender") String get gender;@JsonKey(name: "name") String get name;@JsonKey(name: "verified") bool get verified;@JsonKey(name: "exp") int get exp;@JsonKey(name: "level") int get level;@JsonKey(name: "characters") List<String> get characters;@JsonKey(name: "role") String get role;@JsonKey(name: "avatar") Thumb get avatar;@JsonKey(name: "title") String get title;@JsonKey(name: "slogan") String get slogan;
/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatorCopyWith<Creator> get copyWith => _$CreatorCopyWithImpl<Creator>(this as Creator, _$identity);

  /// Serializes this Creator to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Creator&&(identical(other.id, id) || other.id == id)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.name, name) || other.name == name)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.exp, exp) || other.exp == exp)&&(identical(other.level, level) || other.level == level)&&const DeepCollectionEquality().equals(other.characters, characters)&&(identical(other.role, role) || other.role == role)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.title, title) || other.title == title)&&(identical(other.slogan, slogan) || other.slogan == slogan));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,gender,name,verified,exp,level,const DeepCollectionEquality().hash(characters),role,avatar,title,slogan);

@override
String toString() {
  return 'Creator(id: $id, gender: $gender, name: $name, verified: $verified, exp: $exp, level: $level, characters: $characters, role: $role, avatar: $avatar, title: $title, slogan: $slogan)';
}


}

/// @nodoc
abstract mixin class $CreatorCopyWith<$Res>  {
  factory $CreatorCopyWith(Creator value, $Res Function(Creator) _then) = _$CreatorCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "gender") String gender,@JsonKey(name: "name") String name,@JsonKey(name: "verified") bool verified,@JsonKey(name: "exp") int exp,@JsonKey(name: "level") int level,@JsonKey(name: "characters") List<String> characters,@JsonKey(name: "role") String role,@JsonKey(name: "avatar") Thumb avatar,@JsonKey(name: "title") String title,@JsonKey(name: "slogan") String slogan
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? gender = null,Object? name = null,Object? verified = null,Object? exp = null,Object? level = null,Object? characters = null,Object? role = null,Object? avatar = null,Object? title = null,Object? slogan = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,exp: null == exp ? _self.exp : exp // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,characters: null == characters ? _self.characters : characters // ignore: cast_nullable_to_non_nullable
as List<String>,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as Thumb,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slogan: null == slogan ? _self.slogan : slogan // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "gender")  String gender, @JsonKey(name: "name")  String name, @JsonKey(name: "verified")  bool verified, @JsonKey(name: "exp")  int exp, @JsonKey(name: "level")  int level, @JsonKey(name: "characters")  List<String> characters, @JsonKey(name: "role")  String role, @JsonKey(name: "avatar")  Thumb avatar, @JsonKey(name: "title")  String title, @JsonKey(name: "slogan")  String slogan)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Creator() when $default != null:
return $default(_that.id,_that.gender,_that.name,_that.verified,_that.exp,_that.level,_that.characters,_that.role,_that.avatar,_that.title,_that.slogan);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "gender")  String gender, @JsonKey(name: "name")  String name, @JsonKey(name: "verified")  bool verified, @JsonKey(name: "exp")  int exp, @JsonKey(name: "level")  int level, @JsonKey(name: "characters")  List<String> characters, @JsonKey(name: "role")  String role, @JsonKey(name: "avatar")  Thumb avatar, @JsonKey(name: "title")  String title, @JsonKey(name: "slogan")  String slogan)  $default,) {final _that = this;
switch (_that) {
case _Creator():
return $default(_that.id,_that.gender,_that.name,_that.verified,_that.exp,_that.level,_that.characters,_that.role,_that.avatar,_that.title,_that.slogan);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "gender")  String gender, @JsonKey(name: "name")  String name, @JsonKey(name: "verified")  bool verified, @JsonKey(name: "exp")  int exp, @JsonKey(name: "level")  int level, @JsonKey(name: "characters")  List<String> characters, @JsonKey(name: "role")  String role, @JsonKey(name: "avatar")  Thumb avatar, @JsonKey(name: "title")  String title, @JsonKey(name: "slogan")  String slogan)?  $default,) {final _that = this;
switch (_that) {
case _Creator() when $default != null:
return $default(_that.id,_that.gender,_that.name,_that.verified,_that.exp,_that.level,_that.characters,_that.role,_that.avatar,_that.title,_that.slogan);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Creator implements Creator {
  const _Creator({@JsonKey(name: "_id") required this.id, @JsonKey(name: "gender") required this.gender, @JsonKey(name: "name") required this.name, @JsonKey(name: "verified") required this.verified, @JsonKey(name: "exp") required this.exp, @JsonKey(name: "level") required this.level, @JsonKey(name: "characters") required final  List<String> characters, @JsonKey(name: "role") required this.role, @JsonKey(name: "avatar") required this.avatar, @JsonKey(name: "title") required this.title, @JsonKey(name: "slogan") required this.slogan}): _characters = characters;
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
@override@JsonKey(name: "avatar") final  Thumb avatar;
@override@JsonKey(name: "title") final  String title;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Creator&&(identical(other.id, id) || other.id == id)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.name, name) || other.name == name)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.exp, exp) || other.exp == exp)&&(identical(other.level, level) || other.level == level)&&const DeepCollectionEquality().equals(other._characters, _characters)&&(identical(other.role, role) || other.role == role)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.title, title) || other.title == title)&&(identical(other.slogan, slogan) || other.slogan == slogan));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,gender,name,verified,exp,level,const DeepCollectionEquality().hash(_characters),role,avatar,title,slogan);

@override
String toString() {
  return 'Creator(id: $id, gender: $gender, name: $name, verified: $verified, exp: $exp, level: $level, characters: $characters, role: $role, avatar: $avatar, title: $title, slogan: $slogan)';
}


}

/// @nodoc
abstract mixin class _$CreatorCopyWith<$Res> implements $CreatorCopyWith<$Res> {
  factory _$CreatorCopyWith(_Creator value, $Res Function(_Creator) _then) = __$CreatorCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "gender") String gender,@JsonKey(name: "name") String name,@JsonKey(name: "verified") bool verified,@JsonKey(name: "exp") int exp,@JsonKey(name: "level") int level,@JsonKey(name: "characters") List<String> characters,@JsonKey(name: "role") String role,@JsonKey(name: "avatar") Thumb avatar,@JsonKey(name: "title") String title,@JsonKey(name: "slogan") String slogan
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? gender = null,Object? name = null,Object? verified = null,Object? exp = null,Object? level = null,Object? characters = null,Object? role = null,Object? avatar = null,Object? title = null,Object? slogan = null,}) {
  return _then(_Creator(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,exp: null == exp ? _self.exp : exp // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,characters: null == characters ? _self._characters : characters // ignore: cast_nullable_to_non_nullable
as List<String>,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as Thumb,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slogan: null == slogan ? _self.slogan : slogan // ignore: cast_nullable_to_non_nullable
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


/// @nodoc
mixin _$Eps {

@JsonKey(name: "docs") List<EpsDoc> get docs;
/// Create a copy of Eps
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EpsCopyWith<Eps> get copyWith => _$EpsCopyWithImpl<Eps>(this as Eps, _$identity);

  /// Serializes this Eps to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Eps&&const DeepCollectionEquality().equals(other.docs, docs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(docs));

@override
String toString() {
  return 'Eps(docs: $docs)';
}


}

/// @nodoc
abstract mixin class $EpsCopyWith<$Res>  {
  factory $EpsCopyWith(Eps value, $Res Function(Eps) _then) = _$EpsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "docs") List<EpsDoc> docs
});




}
/// @nodoc
class _$EpsCopyWithImpl<$Res>
    implements $EpsCopyWith<$Res> {
  _$EpsCopyWithImpl(this._self, this._then);

  final Eps _self;
  final $Res Function(Eps) _then;

/// Create a copy of Eps
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? docs = null,}) {
  return _then(_self.copyWith(
docs: null == docs ? _self.docs : docs // ignore: cast_nullable_to_non_nullable
as List<EpsDoc>,
  ));
}

}


/// Adds pattern-matching-related methods to [Eps].
extension EpsPatterns on Eps {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Eps value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Eps() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Eps value)  $default,){
final _that = this;
switch (_that) {
case _Eps():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Eps value)?  $default,){
final _that = this;
switch (_that) {
case _Eps() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "docs")  List<EpsDoc> docs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Eps() when $default != null:
return $default(_that.docs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "docs")  List<EpsDoc> docs)  $default,) {final _that = this;
switch (_that) {
case _Eps():
return $default(_that.docs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "docs")  List<EpsDoc> docs)?  $default,) {final _that = this;
switch (_that) {
case _Eps() when $default != null:
return $default(_that.docs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Eps implements Eps {
  const _Eps({@JsonKey(name: "docs") required final  List<EpsDoc> docs}): _docs = docs;
  factory _Eps.fromJson(Map<String, dynamic> json) => _$EpsFromJson(json);

 final  List<EpsDoc> _docs;
@override@JsonKey(name: "docs") List<EpsDoc> get docs {
  if (_docs is EqualUnmodifiableListView) return _docs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_docs);
}


/// Create a copy of Eps
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EpsCopyWith<_Eps> get copyWith => __$EpsCopyWithImpl<_Eps>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EpsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Eps&&const DeepCollectionEquality().equals(other._docs, _docs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_docs));

@override
String toString() {
  return 'Eps(docs: $docs)';
}


}

/// @nodoc
abstract mixin class _$EpsCopyWith<$Res> implements $EpsCopyWith<$Res> {
  factory _$EpsCopyWith(_Eps value, $Res Function(_Eps) _then) = __$EpsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "docs") List<EpsDoc> docs
});




}
/// @nodoc
class __$EpsCopyWithImpl<$Res>
    implements _$EpsCopyWith<$Res> {
  __$EpsCopyWithImpl(this._self, this._then);

  final _Eps _self;
  final $Res Function(_Eps) _then;

/// Create a copy of Eps
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? docs = null,}) {
  return _then(_Eps(
docs: null == docs ? _self._docs : docs // ignore: cast_nullable_to_non_nullable
as List<EpsDoc>,
  ));
}


}


/// @nodoc
mixin _$EpsDoc {

@JsonKey(name: "_id") String get id;@JsonKey(name: "title") String get title;@JsonKey(name: "order") int get order;@JsonKey(name: "updated_at") DateTime get updatedAt;@JsonKey(name: "id") String get docId;@JsonKey(name: "pages") Pages get pages;
/// Create a copy of EpsDoc
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EpsDocCopyWith<EpsDoc> get copyWith => _$EpsDocCopyWithImpl<EpsDoc>(this as EpsDoc, _$identity);

  /// Serializes this EpsDoc to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EpsDoc&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.order, order) || other.order == order)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.docId, docId) || other.docId == docId)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,order,updatedAt,docId,pages);

@override
String toString() {
  return 'EpsDoc(id: $id, title: $title, order: $order, updatedAt: $updatedAt, docId: $docId, pages: $pages)';
}


}

/// @nodoc
abstract mixin class $EpsDocCopyWith<$Res>  {
  factory $EpsDocCopyWith(EpsDoc value, $Res Function(EpsDoc) _then) = _$EpsDocCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "title") String title,@JsonKey(name: "order") int order,@JsonKey(name: "updated_at") DateTime updatedAt,@JsonKey(name: "id") String docId,@JsonKey(name: "pages") Pages pages
});


$PagesCopyWith<$Res> get pages;

}
/// @nodoc
class _$EpsDocCopyWithImpl<$Res>
    implements $EpsDocCopyWith<$Res> {
  _$EpsDocCopyWithImpl(this._self, this._then);

  final EpsDoc _self;
  final $Res Function(EpsDoc) _then;

/// Create a copy of EpsDoc
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? order = null,Object? updatedAt = null,Object? docId = null,Object? pages = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,docId: null == docId ? _self.docId : docId // ignore: cast_nullable_to_non_nullable
as String,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as Pages,
  ));
}
/// Create a copy of EpsDoc
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PagesCopyWith<$Res> get pages {
  
  return $PagesCopyWith<$Res>(_self.pages, (value) {
    return _then(_self.copyWith(pages: value));
  });
}
}


/// Adds pattern-matching-related methods to [EpsDoc].
extension EpsDocPatterns on EpsDoc {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EpsDoc value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EpsDoc() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EpsDoc value)  $default,){
final _that = this;
switch (_that) {
case _EpsDoc():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EpsDoc value)?  $default,){
final _that = this;
switch (_that) {
case _EpsDoc() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "title")  String title, @JsonKey(name: "order")  int order, @JsonKey(name: "updated_at")  DateTime updatedAt, @JsonKey(name: "id")  String docId, @JsonKey(name: "pages")  Pages pages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EpsDoc() when $default != null:
return $default(_that.id,_that.title,_that.order,_that.updatedAt,_that.docId,_that.pages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "title")  String title, @JsonKey(name: "order")  int order, @JsonKey(name: "updated_at")  DateTime updatedAt, @JsonKey(name: "id")  String docId, @JsonKey(name: "pages")  Pages pages)  $default,) {final _that = this;
switch (_that) {
case _EpsDoc():
return $default(_that.id,_that.title,_that.order,_that.updatedAt,_that.docId,_that.pages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "title")  String title, @JsonKey(name: "order")  int order, @JsonKey(name: "updated_at")  DateTime updatedAt, @JsonKey(name: "id")  String docId, @JsonKey(name: "pages")  Pages pages)?  $default,) {final _that = this;
switch (_that) {
case _EpsDoc() when $default != null:
return $default(_that.id,_that.title,_that.order,_that.updatedAt,_that.docId,_that.pages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EpsDoc implements EpsDoc {
  const _EpsDoc({@JsonKey(name: "_id") required this.id, @JsonKey(name: "title") required this.title, @JsonKey(name: "order") required this.order, @JsonKey(name: "updated_at") required this.updatedAt, @JsonKey(name: "id") required this.docId, @JsonKey(name: "pages") required this.pages});
  factory _EpsDoc.fromJson(Map<String, dynamic> json) => _$EpsDocFromJson(json);

@override@JsonKey(name: "_id") final  String id;
@override@JsonKey(name: "title") final  String title;
@override@JsonKey(name: "order") final  int order;
@override@JsonKey(name: "updated_at") final  DateTime updatedAt;
@override@JsonKey(name: "id") final  String docId;
@override@JsonKey(name: "pages") final  Pages pages;

/// Create a copy of EpsDoc
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EpsDocCopyWith<_EpsDoc> get copyWith => __$EpsDocCopyWithImpl<_EpsDoc>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EpsDocToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EpsDoc&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.order, order) || other.order == order)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.docId, docId) || other.docId == docId)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,order,updatedAt,docId,pages);

@override
String toString() {
  return 'EpsDoc(id: $id, title: $title, order: $order, updatedAt: $updatedAt, docId: $docId, pages: $pages)';
}


}

/// @nodoc
abstract mixin class _$EpsDocCopyWith<$Res> implements $EpsDocCopyWith<$Res> {
  factory _$EpsDocCopyWith(_EpsDoc value, $Res Function(_EpsDoc) _then) = __$EpsDocCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "title") String title,@JsonKey(name: "order") int order,@JsonKey(name: "updated_at") DateTime updatedAt,@JsonKey(name: "id") String docId,@JsonKey(name: "pages") Pages pages
});


@override $PagesCopyWith<$Res> get pages;

}
/// @nodoc
class __$EpsDocCopyWithImpl<$Res>
    implements _$EpsDocCopyWith<$Res> {
  __$EpsDocCopyWithImpl(this._self, this._then);

  final _EpsDoc _self;
  final $Res Function(_EpsDoc) _then;

/// Create a copy of EpsDoc
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? order = null,Object? updatedAt = null,Object? docId = null,Object? pages = null,}) {
  return _then(_EpsDoc(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,docId: null == docId ? _self.docId : docId // ignore: cast_nullable_to_non_nullable
as String,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as Pages,
  ));
}

/// Create a copy of EpsDoc
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PagesCopyWith<$Res> get pages {
  
  return $PagesCopyWith<$Res>(_self.pages, (value) {
    return _then(_self.copyWith(pages: value));
  });
}
}


/// @nodoc
mixin _$Pages {

@JsonKey(name: "docs") List<PagesDoc> get docs;
/// Create a copy of Pages
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PagesCopyWith<Pages> get copyWith => _$PagesCopyWithImpl<Pages>(this as Pages, _$identity);

  /// Serializes this Pages to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Pages&&const DeepCollectionEquality().equals(other.docs, docs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(docs));

@override
String toString() {
  return 'Pages(docs: $docs)';
}


}

/// @nodoc
abstract mixin class $PagesCopyWith<$Res>  {
  factory $PagesCopyWith(Pages value, $Res Function(Pages) _then) = _$PagesCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "docs") List<PagesDoc> docs
});




}
/// @nodoc
class _$PagesCopyWithImpl<$Res>
    implements $PagesCopyWith<$Res> {
  _$PagesCopyWithImpl(this._self, this._then);

  final Pages _self;
  final $Res Function(Pages) _then;

/// Create a copy of Pages
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? docs = null,}) {
  return _then(_self.copyWith(
docs: null == docs ? _self.docs : docs // ignore: cast_nullable_to_non_nullable
as List<PagesDoc>,
  ));
}

}


/// Adds pattern-matching-related methods to [Pages].
extension PagesPatterns on Pages {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Pages value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Pages() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Pages value)  $default,){
final _that = this;
switch (_that) {
case _Pages():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Pages value)?  $default,){
final _that = this;
switch (_that) {
case _Pages() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "docs")  List<PagesDoc> docs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Pages() when $default != null:
return $default(_that.docs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "docs")  List<PagesDoc> docs)  $default,) {final _that = this;
switch (_that) {
case _Pages():
return $default(_that.docs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "docs")  List<PagesDoc> docs)?  $default,) {final _that = this;
switch (_that) {
case _Pages() when $default != null:
return $default(_that.docs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Pages implements Pages {
  const _Pages({@JsonKey(name: "docs") required final  List<PagesDoc> docs}): _docs = docs;
  factory _Pages.fromJson(Map<String, dynamic> json) => _$PagesFromJson(json);

 final  List<PagesDoc> _docs;
@override@JsonKey(name: "docs") List<PagesDoc> get docs {
  if (_docs is EqualUnmodifiableListView) return _docs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_docs);
}


/// Create a copy of Pages
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PagesCopyWith<_Pages> get copyWith => __$PagesCopyWithImpl<_Pages>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PagesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Pages&&const DeepCollectionEquality().equals(other._docs, _docs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_docs));

@override
String toString() {
  return 'Pages(docs: $docs)';
}


}

/// @nodoc
abstract mixin class _$PagesCopyWith<$Res> implements $PagesCopyWith<$Res> {
  factory _$PagesCopyWith(_Pages value, $Res Function(_Pages) _then) = __$PagesCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "docs") List<PagesDoc> docs
});




}
/// @nodoc
class __$PagesCopyWithImpl<$Res>
    implements _$PagesCopyWith<$Res> {
  __$PagesCopyWithImpl(this._self, this._then);

  final _Pages _self;
  final $Res Function(_Pages) _then;

/// Create a copy of Pages
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? docs = null,}) {
  return _then(_Pages(
docs: null == docs ? _self._docs : docs // ignore: cast_nullable_to_non_nullable
as List<PagesDoc>,
  ));
}


}


/// @nodoc
mixin _$PagesDoc {

@JsonKey(name: "_id") String get id;@JsonKey(name: "media") Thumb get media;@JsonKey(name: "id") String get docId;
/// Create a copy of PagesDoc
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PagesDocCopyWith<PagesDoc> get copyWith => _$PagesDocCopyWithImpl<PagesDoc>(this as PagesDoc, _$identity);

  /// Serializes this PagesDoc to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PagesDoc&&(identical(other.id, id) || other.id == id)&&(identical(other.media, media) || other.media == media)&&(identical(other.docId, docId) || other.docId == docId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,media,docId);

@override
String toString() {
  return 'PagesDoc(id: $id, media: $media, docId: $docId)';
}


}

/// @nodoc
abstract mixin class $PagesDocCopyWith<$Res>  {
  factory $PagesDocCopyWith(PagesDoc value, $Res Function(PagesDoc) _then) = _$PagesDocCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "media") Thumb media,@JsonKey(name: "id") String docId
});


$ThumbCopyWith<$Res> get media;

}
/// @nodoc
class _$PagesDocCopyWithImpl<$Res>
    implements $PagesDocCopyWith<$Res> {
  _$PagesDocCopyWithImpl(this._self, this._then);

  final PagesDoc _self;
  final $Res Function(PagesDoc) _then;

/// Create a copy of PagesDoc
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? media = null,Object? docId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as Thumb,docId: null == docId ? _self.docId : docId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of PagesDoc
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThumbCopyWith<$Res> get media {
  
  return $ThumbCopyWith<$Res>(_self.media, (value) {
    return _then(_self.copyWith(media: value));
  });
}
}


/// Adds pattern-matching-related methods to [PagesDoc].
extension PagesDocPatterns on PagesDoc {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PagesDoc value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PagesDoc() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PagesDoc value)  $default,){
final _that = this;
switch (_that) {
case _PagesDoc():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PagesDoc value)?  $default,){
final _that = this;
switch (_that) {
case _PagesDoc() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "media")  Thumb media, @JsonKey(name: "id")  String docId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PagesDoc() when $default != null:
return $default(_that.id,_that.media,_that.docId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "media")  Thumb media, @JsonKey(name: "id")  String docId)  $default,) {final _that = this;
switch (_that) {
case _PagesDoc():
return $default(_that.id,_that.media,_that.docId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "media")  Thumb media, @JsonKey(name: "id")  String docId)?  $default,) {final _that = this;
switch (_that) {
case _PagesDoc() when $default != null:
return $default(_that.id,_that.media,_that.docId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PagesDoc implements PagesDoc {
  const _PagesDoc({@JsonKey(name: "_id") required this.id, @JsonKey(name: "media") required this.media, @JsonKey(name: "id") required this.docId});
  factory _PagesDoc.fromJson(Map<String, dynamic> json) => _$PagesDocFromJson(json);

@override@JsonKey(name: "_id") final  String id;
@override@JsonKey(name: "media") final  Thumb media;
@override@JsonKey(name: "id") final  String docId;

/// Create a copy of PagesDoc
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PagesDocCopyWith<_PagesDoc> get copyWith => __$PagesDocCopyWithImpl<_PagesDoc>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PagesDocToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PagesDoc&&(identical(other.id, id) || other.id == id)&&(identical(other.media, media) || other.media == media)&&(identical(other.docId, docId) || other.docId == docId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,media,docId);

@override
String toString() {
  return 'PagesDoc(id: $id, media: $media, docId: $docId)';
}


}

/// @nodoc
abstract mixin class _$PagesDocCopyWith<$Res> implements $PagesDocCopyWith<$Res> {
  factory _$PagesDocCopyWith(_PagesDoc value, $Res Function(_PagesDoc) _then) = __$PagesDocCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "media") Thumb media,@JsonKey(name: "id") String docId
});


@override $ThumbCopyWith<$Res> get media;

}
/// @nodoc
class __$PagesDocCopyWithImpl<$Res>
    implements _$PagesDocCopyWith<$Res> {
  __$PagesDocCopyWithImpl(this._self, this._then);

  final _PagesDoc _self;
  final $Res Function(_PagesDoc) _then;

/// Create a copy of PagesDoc
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? media = null,Object? docId = null,}) {
  return _then(_PagesDoc(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as Thumb,docId: null == docId ? _self.docId : docId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of PagesDoc
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThumbCopyWith<$Res> get media {
  
  return $ThumbCopyWith<$Res>(_self.media, (value) {
    return _then(_self.copyWith(media: value));
  });
}
}

// dart format on
