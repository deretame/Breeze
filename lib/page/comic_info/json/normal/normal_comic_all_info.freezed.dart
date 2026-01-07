// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'normal_comic_all_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NormalComicAllInfo {

@JsonKey(name: "comicInfo") ComicInfo get comicInfo;@JsonKey(name: "eps") List<Ep> get eps;@JsonKey(name: "recommend") List<Recommend> get recommend;
/// Create a copy of NormalComicAllInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NormalComicAllInfoCopyWith<NormalComicAllInfo> get copyWith => _$NormalComicAllInfoCopyWithImpl<NormalComicAllInfo>(this as NormalComicAllInfo, _$identity);

  /// Serializes this NormalComicAllInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NormalComicAllInfo&&(identical(other.comicInfo, comicInfo) || other.comicInfo == comicInfo)&&const DeepCollectionEquality().equals(other.eps, eps)&&const DeepCollectionEquality().equals(other.recommend, recommend));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comicInfo,const DeepCollectionEquality().hash(eps),const DeepCollectionEquality().hash(recommend));

@override
String toString() {
  return 'NormalComicAllInfo(comicInfo: $comicInfo, eps: $eps, recommend: $recommend)';
}


}

/// @nodoc
abstract mixin class $NormalComicAllInfoCopyWith<$Res>  {
  factory $NormalComicAllInfoCopyWith(NormalComicAllInfo value, $Res Function(NormalComicAllInfo) _then) = _$NormalComicAllInfoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "comicInfo") ComicInfo comicInfo,@JsonKey(name: "eps") List<Ep> eps,@JsonKey(name: "recommend") List<Recommend> recommend
});


$ComicInfoCopyWith<$Res> get comicInfo;

}
/// @nodoc
class _$NormalComicAllInfoCopyWithImpl<$Res>
    implements $NormalComicAllInfoCopyWith<$Res> {
  _$NormalComicAllInfoCopyWithImpl(this._self, this._then);

  final NormalComicAllInfo _self;
  final $Res Function(NormalComicAllInfo) _then;

/// Create a copy of NormalComicAllInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? comicInfo = null,Object? eps = null,Object? recommend = null,}) {
  return _then(_self.copyWith(
comicInfo: null == comicInfo ? _self.comicInfo : comicInfo // ignore: cast_nullable_to_non_nullable
as ComicInfo,eps: null == eps ? _self.eps : eps // ignore: cast_nullable_to_non_nullable
as List<Ep>,recommend: null == recommend ? _self.recommend : recommend // ignore: cast_nullable_to_non_nullable
as List<Recommend>,
  ));
}
/// Create a copy of NormalComicAllInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicInfoCopyWith<$Res> get comicInfo {
  
  return $ComicInfoCopyWith<$Res>(_self.comicInfo, (value) {
    return _then(_self.copyWith(comicInfo: value));
  });
}
}


/// Adds pattern-matching-related methods to [NormalComicAllInfo].
extension NormalComicAllInfoPatterns on NormalComicAllInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NormalComicAllInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NormalComicAllInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NormalComicAllInfo value)  $default,){
final _that = this;
switch (_that) {
case _NormalComicAllInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NormalComicAllInfo value)?  $default,){
final _that = this;
switch (_that) {
case _NormalComicAllInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "comicInfo")  ComicInfo comicInfo, @JsonKey(name: "eps")  List<Ep> eps, @JsonKey(name: "recommend")  List<Recommend> recommend)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NormalComicAllInfo() when $default != null:
return $default(_that.comicInfo,_that.eps,_that.recommend);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "comicInfo")  ComicInfo comicInfo, @JsonKey(name: "eps")  List<Ep> eps, @JsonKey(name: "recommend")  List<Recommend> recommend)  $default,) {final _that = this;
switch (_that) {
case _NormalComicAllInfo():
return $default(_that.comicInfo,_that.eps,_that.recommend);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "comicInfo")  ComicInfo comicInfo, @JsonKey(name: "eps")  List<Ep> eps, @JsonKey(name: "recommend")  List<Recommend> recommend)?  $default,) {final _that = this;
switch (_that) {
case _NormalComicAllInfo() when $default != null:
return $default(_that.comicInfo,_that.eps,_that.recommend);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NormalComicAllInfo implements NormalComicAllInfo {
  const _NormalComicAllInfo({@JsonKey(name: "comicInfo") required this.comicInfo, @JsonKey(name: "eps") required final  List<Ep> eps, @JsonKey(name: "recommend") required final  List<Recommend> recommend}): _eps = eps,_recommend = recommend;
  factory _NormalComicAllInfo.fromJson(Map<String, dynamic> json) => _$NormalComicAllInfoFromJson(json);

@override@JsonKey(name: "comicInfo") final  ComicInfo comicInfo;
 final  List<Ep> _eps;
@override@JsonKey(name: "eps") List<Ep> get eps {
  if (_eps is EqualUnmodifiableListView) return _eps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_eps);
}

 final  List<Recommend> _recommend;
@override@JsonKey(name: "recommend") List<Recommend> get recommend {
  if (_recommend is EqualUnmodifiableListView) return _recommend;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recommend);
}


/// Create a copy of NormalComicAllInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NormalComicAllInfoCopyWith<_NormalComicAllInfo> get copyWith => __$NormalComicAllInfoCopyWithImpl<_NormalComicAllInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NormalComicAllInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NormalComicAllInfo&&(identical(other.comicInfo, comicInfo) || other.comicInfo == comicInfo)&&const DeepCollectionEquality().equals(other._eps, _eps)&&const DeepCollectionEquality().equals(other._recommend, _recommend));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comicInfo,const DeepCollectionEquality().hash(_eps),const DeepCollectionEquality().hash(_recommend));

@override
String toString() {
  return 'NormalComicAllInfo(comicInfo: $comicInfo, eps: $eps, recommend: $recommend)';
}


}

/// @nodoc
abstract mixin class _$NormalComicAllInfoCopyWith<$Res> implements $NormalComicAllInfoCopyWith<$Res> {
  factory _$NormalComicAllInfoCopyWith(_NormalComicAllInfo value, $Res Function(_NormalComicAllInfo) _then) = __$NormalComicAllInfoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "comicInfo") ComicInfo comicInfo,@JsonKey(name: "eps") List<Ep> eps,@JsonKey(name: "recommend") List<Recommend> recommend
});


@override $ComicInfoCopyWith<$Res> get comicInfo;

}
/// @nodoc
class __$NormalComicAllInfoCopyWithImpl<$Res>
    implements _$NormalComicAllInfoCopyWith<$Res> {
  __$NormalComicAllInfoCopyWithImpl(this._self, this._then);

  final _NormalComicAllInfo _self;
  final $Res Function(_NormalComicAllInfo) _then;

/// Create a copy of NormalComicAllInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? comicInfo = null,Object? eps = null,Object? recommend = null,}) {
  return _then(_NormalComicAllInfo(
comicInfo: null == comicInfo ? _self.comicInfo : comicInfo // ignore: cast_nullable_to_non_nullable
as ComicInfo,eps: null == eps ? _self._eps : eps // ignore: cast_nullable_to_non_nullable
as List<Ep>,recommend: null == recommend ? _self._recommend : recommend // ignore: cast_nullable_to_non_nullable
as List<Recommend>,
  ));
}

/// Create a copy of NormalComicAllInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicInfoCopyWith<$Res> get comicInfo {
  
  return $ComicInfoCopyWith<$Res>(_self.comicInfo, (value) {
    return _then(_self.copyWith(comicInfo: value));
  });
}
}


/// @nodoc
mixin _$ComicInfo {

@JsonKey(name: "id") String get id;@JsonKey(name: "creator") Creator get creator;@JsonKey(name: "title") String get title;@JsonKey(name: "description") String get description;@JsonKey(name: "cover") Cover get cover;@JsonKey(name: "categories") List<String> get categories;@JsonKey(name: "tags") List<String> get tags;@JsonKey(name: "author") List<String> get author;@JsonKey(name: "works") List<String> get works;@JsonKey(name: "actors") List<String> get actors;@JsonKey(name: "chineseTeam") List<String> get chineseTeam;@JsonKey(name: "pagesCount") int get pagesCount;@JsonKey(name: "epsCount") int get epsCount;@JsonKey(name: "updated_at") DateTime get updatedAt;@JsonKey(name: "allowComment") bool get allowComment;@JsonKey(name: "totalViews") int get totalViews;@JsonKey(name: "totalLikes") int get totalLikes;@JsonKey(name: "totalComments") int get totalComments;@JsonKey(name: "isFavourite") bool get isFavourite;@JsonKey(name: "isLiked") bool get isLiked;
/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicInfoCopyWith<ComicInfo> get copyWith => _$ComicInfoCopyWithImpl<ComicInfo>(this as ComicInfo, _$identity);

  /// Serializes this ComicInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.creator, creator) || other.creator == creator)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.cover, cover) || other.cover == cover)&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.author, author)&&const DeepCollectionEquality().equals(other.works, works)&&const DeepCollectionEquality().equals(other.actors, actors)&&const DeepCollectionEquality().equals(other.chineseTeam, chineseTeam)&&(identical(other.pagesCount, pagesCount) || other.pagesCount == pagesCount)&&(identical(other.epsCount, epsCount) || other.epsCount == epsCount)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.allowComment, allowComment) || other.allowComment == allowComment)&&(identical(other.totalViews, totalViews) || other.totalViews == totalViews)&&(identical(other.totalLikes, totalLikes) || other.totalLikes == totalLikes)&&(identical(other.totalComments, totalComments) || other.totalComments == totalComments)&&(identical(other.isFavourite, isFavourite) || other.isFavourite == isFavourite)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,creator,title,description,cover,const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(author),const DeepCollectionEquality().hash(works),const DeepCollectionEquality().hash(actors),const DeepCollectionEquality().hash(chineseTeam),pagesCount,epsCount,updatedAt,allowComment,totalViews,totalLikes,totalComments,isFavourite,isLiked]);

@override
String toString() {
  return 'ComicInfo(id: $id, creator: $creator, title: $title, description: $description, cover: $cover, categories: $categories, tags: $tags, author: $author, works: $works, actors: $actors, chineseTeam: $chineseTeam, pagesCount: $pagesCount, epsCount: $epsCount, updatedAt: $updatedAt, allowComment: $allowComment, totalViews: $totalViews, totalLikes: $totalLikes, totalComments: $totalComments, isFavourite: $isFavourite, isLiked: $isLiked)';
}


}

/// @nodoc
abstract mixin class $ComicInfoCopyWith<$Res>  {
  factory $ComicInfoCopyWith(ComicInfo value, $Res Function(ComicInfo) _then) = _$ComicInfoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "creator") Creator creator,@JsonKey(name: "title") String title,@JsonKey(name: "description") String description,@JsonKey(name: "cover") Cover cover,@JsonKey(name: "categories") List<String> categories,@JsonKey(name: "tags") List<String> tags,@JsonKey(name: "author") List<String> author,@JsonKey(name: "works") List<String> works,@JsonKey(name: "actors") List<String> actors,@JsonKey(name: "chineseTeam") List<String> chineseTeam,@JsonKey(name: "pagesCount") int pagesCount,@JsonKey(name: "epsCount") int epsCount,@JsonKey(name: "updated_at") DateTime updatedAt,@JsonKey(name: "allowComment") bool allowComment,@JsonKey(name: "totalViews") int totalViews,@JsonKey(name: "totalLikes") int totalLikes,@JsonKey(name: "totalComments") int totalComments,@JsonKey(name: "isFavourite") bool isFavourite,@JsonKey(name: "isLiked") bool isLiked
});


$CreatorCopyWith<$Res> get creator;$CoverCopyWith<$Res> get cover;

}
/// @nodoc
class _$ComicInfoCopyWithImpl<$Res>
    implements $ComicInfoCopyWith<$Res> {
  _$ComicInfoCopyWithImpl(this._self, this._then);

  final ComicInfo _self;
  final $Res Function(ComicInfo) _then;

/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? creator = null,Object? title = null,Object? description = null,Object? cover = null,Object? categories = null,Object? tags = null,Object? author = null,Object? works = null,Object? actors = null,Object? chineseTeam = null,Object? pagesCount = null,Object? epsCount = null,Object? updatedAt = null,Object? allowComment = null,Object? totalViews = null,Object? totalLikes = null,Object? totalComments = null,Object? isFavourite = null,Object? isLiked = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,creator: null == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as Creator,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as Cover,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as List<String>,works: null == works ? _self.works : works // ignore: cast_nullable_to_non_nullable
as List<String>,actors: null == actors ? _self.actors : actors // ignore: cast_nullable_to_non_nullable
as List<String>,chineseTeam: null == chineseTeam ? _self.chineseTeam : chineseTeam // ignore: cast_nullable_to_non_nullable
as List<String>,pagesCount: null == pagesCount ? _self.pagesCount : pagesCount // ignore: cast_nullable_to_non_nullable
as int,epsCount: null == epsCount ? _self.epsCount : epsCount // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,allowComment: null == allowComment ? _self.allowComment : allowComment // ignore: cast_nullable_to_non_nullable
as bool,totalViews: null == totalViews ? _self.totalViews : totalViews // ignore: cast_nullable_to_non_nullable
as int,totalLikes: null == totalLikes ? _self.totalLikes : totalLikes // ignore: cast_nullable_to_non_nullable
as int,totalComments: null == totalComments ? _self.totalComments : totalComments // ignore: cast_nullable_to_non_nullable
as int,isFavourite: null == isFavourite ? _self.isFavourite : isFavourite // ignore: cast_nullable_to_non_nullable
as bool,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CreatorCopyWith<$Res> get creator {
  
  return $CreatorCopyWith<$Res>(_self.creator, (value) {
    return _then(_self.copyWith(creator: value));
  });
}/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoverCopyWith<$Res> get cover {
  
  return $CoverCopyWith<$Res>(_self.cover, (value) {
    return _then(_self.copyWith(cover: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "creator")  Creator creator, @JsonKey(name: "title")  String title, @JsonKey(name: "description")  String description, @JsonKey(name: "cover")  Cover cover, @JsonKey(name: "categories")  List<String> categories, @JsonKey(name: "tags")  List<String> tags, @JsonKey(name: "author")  List<String> author, @JsonKey(name: "works")  List<String> works, @JsonKey(name: "actors")  List<String> actors, @JsonKey(name: "chineseTeam")  List<String> chineseTeam, @JsonKey(name: "pagesCount")  int pagesCount, @JsonKey(name: "epsCount")  int epsCount, @JsonKey(name: "updated_at")  DateTime updatedAt, @JsonKey(name: "allowComment")  bool allowComment, @JsonKey(name: "totalViews")  int totalViews, @JsonKey(name: "totalLikes")  int totalLikes, @JsonKey(name: "totalComments")  int totalComments, @JsonKey(name: "isFavourite")  bool isFavourite, @JsonKey(name: "isLiked")  bool isLiked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicInfo() when $default != null:
return $default(_that.id,_that.creator,_that.title,_that.description,_that.cover,_that.categories,_that.tags,_that.author,_that.works,_that.actors,_that.chineseTeam,_that.pagesCount,_that.epsCount,_that.updatedAt,_that.allowComment,_that.totalViews,_that.totalLikes,_that.totalComments,_that.isFavourite,_that.isLiked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "creator")  Creator creator, @JsonKey(name: "title")  String title, @JsonKey(name: "description")  String description, @JsonKey(name: "cover")  Cover cover, @JsonKey(name: "categories")  List<String> categories, @JsonKey(name: "tags")  List<String> tags, @JsonKey(name: "author")  List<String> author, @JsonKey(name: "works")  List<String> works, @JsonKey(name: "actors")  List<String> actors, @JsonKey(name: "chineseTeam")  List<String> chineseTeam, @JsonKey(name: "pagesCount")  int pagesCount, @JsonKey(name: "epsCount")  int epsCount, @JsonKey(name: "updated_at")  DateTime updatedAt, @JsonKey(name: "allowComment")  bool allowComment, @JsonKey(name: "totalViews")  int totalViews, @JsonKey(name: "totalLikes")  int totalLikes, @JsonKey(name: "totalComments")  int totalComments, @JsonKey(name: "isFavourite")  bool isFavourite, @JsonKey(name: "isLiked")  bool isLiked)  $default,) {final _that = this;
switch (_that) {
case _ComicInfo():
return $default(_that.id,_that.creator,_that.title,_that.description,_that.cover,_that.categories,_that.tags,_that.author,_that.works,_that.actors,_that.chineseTeam,_that.pagesCount,_that.epsCount,_that.updatedAt,_that.allowComment,_that.totalViews,_that.totalLikes,_that.totalComments,_that.isFavourite,_that.isLiked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "id")  String id, @JsonKey(name: "creator")  Creator creator, @JsonKey(name: "title")  String title, @JsonKey(name: "description")  String description, @JsonKey(name: "cover")  Cover cover, @JsonKey(name: "categories")  List<String> categories, @JsonKey(name: "tags")  List<String> tags, @JsonKey(name: "author")  List<String> author, @JsonKey(name: "works")  List<String> works, @JsonKey(name: "actors")  List<String> actors, @JsonKey(name: "chineseTeam")  List<String> chineseTeam, @JsonKey(name: "pagesCount")  int pagesCount, @JsonKey(name: "epsCount")  int epsCount, @JsonKey(name: "updated_at")  DateTime updatedAt, @JsonKey(name: "allowComment")  bool allowComment, @JsonKey(name: "totalViews")  int totalViews, @JsonKey(name: "totalLikes")  int totalLikes, @JsonKey(name: "totalComments")  int totalComments, @JsonKey(name: "isFavourite")  bool isFavourite, @JsonKey(name: "isLiked")  bool isLiked)?  $default,) {final _that = this;
switch (_that) {
case _ComicInfo() when $default != null:
return $default(_that.id,_that.creator,_that.title,_that.description,_that.cover,_that.categories,_that.tags,_that.author,_that.works,_that.actors,_that.chineseTeam,_that.pagesCount,_that.epsCount,_that.updatedAt,_that.allowComment,_that.totalViews,_that.totalLikes,_that.totalComments,_that.isFavourite,_that.isLiked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComicInfo implements ComicInfo {
  const _ComicInfo({@JsonKey(name: "id") required this.id, @JsonKey(name: "creator") required this.creator, @JsonKey(name: "title") required this.title, @JsonKey(name: "description") required this.description, @JsonKey(name: "cover") required this.cover, @JsonKey(name: "categories") required final  List<String> categories, @JsonKey(name: "tags") required final  List<String> tags, @JsonKey(name: "author") required final  List<String> author, @JsonKey(name: "works") required final  List<String> works, @JsonKey(name: "actors") required final  List<String> actors, @JsonKey(name: "chineseTeam") required final  List<String> chineseTeam, @JsonKey(name: "pagesCount") required this.pagesCount, @JsonKey(name: "epsCount") required this.epsCount, @JsonKey(name: "updated_at") required this.updatedAt, @JsonKey(name: "allowComment") required this.allowComment, @JsonKey(name: "totalViews") required this.totalViews, @JsonKey(name: "totalLikes") required this.totalLikes, @JsonKey(name: "totalComments") required this.totalComments, @JsonKey(name: "isFavourite") required this.isFavourite, @JsonKey(name: "isLiked") required this.isLiked}): _categories = categories,_tags = tags,_author = author,_works = works,_actors = actors,_chineseTeam = chineseTeam;
  factory _ComicInfo.fromJson(Map<String, dynamic> json) => _$ComicInfoFromJson(json);

@override@JsonKey(name: "id") final  String id;
@override@JsonKey(name: "creator") final  Creator creator;
@override@JsonKey(name: "title") final  String title;
@override@JsonKey(name: "description") final  String description;
@override@JsonKey(name: "cover") final  Cover cover;
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

 final  List<String> _author;
@override@JsonKey(name: "author") List<String> get author {
  if (_author is EqualUnmodifiableListView) return _author;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_author);
}

 final  List<String> _works;
@override@JsonKey(name: "works") List<String> get works {
  if (_works is EqualUnmodifiableListView) return _works;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_works);
}

 final  List<String> _actors;
@override@JsonKey(name: "actors") List<String> get actors {
  if (_actors is EqualUnmodifiableListView) return _actors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_actors);
}

 final  List<String> _chineseTeam;
@override@JsonKey(name: "chineseTeam") List<String> get chineseTeam {
  if (_chineseTeam is EqualUnmodifiableListView) return _chineseTeam;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_chineseTeam);
}

@override@JsonKey(name: "pagesCount") final  int pagesCount;
@override@JsonKey(name: "epsCount") final  int epsCount;
@override@JsonKey(name: "updated_at") final  DateTime updatedAt;
@override@JsonKey(name: "allowComment") final  bool allowComment;
@override@JsonKey(name: "totalViews") final  int totalViews;
@override@JsonKey(name: "totalLikes") final  int totalLikes;
@override@JsonKey(name: "totalComments") final  int totalComments;
@override@JsonKey(name: "isFavourite") final  bool isFavourite;
@override@JsonKey(name: "isLiked") final  bool isLiked;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.creator, creator) || other.creator == creator)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.cover, cover) || other.cover == cover)&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._author, _author)&&const DeepCollectionEquality().equals(other._works, _works)&&const DeepCollectionEquality().equals(other._actors, _actors)&&const DeepCollectionEquality().equals(other._chineseTeam, _chineseTeam)&&(identical(other.pagesCount, pagesCount) || other.pagesCount == pagesCount)&&(identical(other.epsCount, epsCount) || other.epsCount == epsCount)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.allowComment, allowComment) || other.allowComment == allowComment)&&(identical(other.totalViews, totalViews) || other.totalViews == totalViews)&&(identical(other.totalLikes, totalLikes) || other.totalLikes == totalLikes)&&(identical(other.totalComments, totalComments) || other.totalComments == totalComments)&&(identical(other.isFavourite, isFavourite) || other.isFavourite == isFavourite)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,creator,title,description,cover,const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_author),const DeepCollectionEquality().hash(_works),const DeepCollectionEquality().hash(_actors),const DeepCollectionEquality().hash(_chineseTeam),pagesCount,epsCount,updatedAt,allowComment,totalViews,totalLikes,totalComments,isFavourite,isLiked]);

@override
String toString() {
  return 'ComicInfo(id: $id, creator: $creator, title: $title, description: $description, cover: $cover, categories: $categories, tags: $tags, author: $author, works: $works, actors: $actors, chineseTeam: $chineseTeam, pagesCount: $pagesCount, epsCount: $epsCount, updatedAt: $updatedAt, allowComment: $allowComment, totalViews: $totalViews, totalLikes: $totalLikes, totalComments: $totalComments, isFavourite: $isFavourite, isLiked: $isLiked)';
}


}

/// @nodoc
abstract mixin class _$ComicInfoCopyWith<$Res> implements $ComicInfoCopyWith<$Res> {
  factory _$ComicInfoCopyWith(_ComicInfo value, $Res Function(_ComicInfo) _then) = __$ComicInfoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "creator") Creator creator,@JsonKey(name: "title") String title,@JsonKey(name: "description") String description,@JsonKey(name: "cover") Cover cover,@JsonKey(name: "categories") List<String> categories,@JsonKey(name: "tags") List<String> tags,@JsonKey(name: "author") List<String> author,@JsonKey(name: "works") List<String> works,@JsonKey(name: "actors") List<String> actors,@JsonKey(name: "chineseTeam") List<String> chineseTeam,@JsonKey(name: "pagesCount") int pagesCount,@JsonKey(name: "epsCount") int epsCount,@JsonKey(name: "updated_at") DateTime updatedAt,@JsonKey(name: "allowComment") bool allowComment,@JsonKey(name: "totalViews") int totalViews,@JsonKey(name: "totalLikes") int totalLikes,@JsonKey(name: "totalComments") int totalComments,@JsonKey(name: "isFavourite") bool isFavourite,@JsonKey(name: "isLiked") bool isLiked
});


@override $CreatorCopyWith<$Res> get creator;@override $CoverCopyWith<$Res> get cover;

}
/// @nodoc
class __$ComicInfoCopyWithImpl<$Res>
    implements _$ComicInfoCopyWith<$Res> {
  __$ComicInfoCopyWithImpl(this._self, this._then);

  final _ComicInfo _self;
  final $Res Function(_ComicInfo) _then;

/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? creator = null,Object? title = null,Object? description = null,Object? cover = null,Object? categories = null,Object? tags = null,Object? author = null,Object? works = null,Object? actors = null,Object? chineseTeam = null,Object? pagesCount = null,Object? epsCount = null,Object? updatedAt = null,Object? allowComment = null,Object? totalViews = null,Object? totalLikes = null,Object? totalComments = null,Object? isFavourite = null,Object? isLiked = null,}) {
  return _then(_ComicInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,creator: null == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as Creator,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as Cover,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,author: null == author ? _self._author : author // ignore: cast_nullable_to_non_nullable
as List<String>,works: null == works ? _self._works : works // ignore: cast_nullable_to_non_nullable
as List<String>,actors: null == actors ? _self._actors : actors // ignore: cast_nullable_to_non_nullable
as List<String>,chineseTeam: null == chineseTeam ? _self._chineseTeam : chineseTeam // ignore: cast_nullable_to_non_nullable
as List<String>,pagesCount: null == pagesCount ? _self.pagesCount : pagesCount // ignore: cast_nullable_to_non_nullable
as int,epsCount: null == epsCount ? _self.epsCount : epsCount // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,allowComment: null == allowComment ? _self.allowComment : allowComment // ignore: cast_nullable_to_non_nullable
as bool,totalViews: null == totalViews ? _self.totalViews : totalViews // ignore: cast_nullable_to_non_nullable
as int,totalLikes: null == totalLikes ? _self.totalLikes : totalLikes // ignore: cast_nullable_to_non_nullable
as int,totalComments: null == totalComments ? _self.totalComments : totalComments // ignore: cast_nullable_to_non_nullable
as int,isFavourite: null == isFavourite ? _self.isFavourite : isFavourite // ignore: cast_nullable_to_non_nullable
as bool,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CreatorCopyWith<$Res> get creator {
  
  return $CreatorCopyWith<$Res>(_self.creator, (value) {
    return _then(_self.copyWith(creator: value));
  });
}/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoverCopyWith<$Res> get cover {
  
  return $CoverCopyWith<$Res>(_self.cover, (value) {
    return _then(_self.copyWith(cover: value));
  });
}
}


/// @nodoc
mixin _$Cover {

@JsonKey(name: "url") String get url;@JsonKey(name: "path") String get path;@JsonKey(name: "name") String get name;
/// Create a copy of Cover
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoverCopyWith<Cover> get copyWith => _$CoverCopyWithImpl<Cover>(this as Cover, _$identity);

  /// Serializes this Cover to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Cover&&(identical(other.url, url) || other.url == url)&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,path,name);

@override
String toString() {
  return 'Cover(url: $url, path: $path, name: $name)';
}


}

/// @nodoc
abstract mixin class $CoverCopyWith<$Res>  {
  factory $CoverCopyWith(Cover value, $Res Function(Cover) _then) = _$CoverCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "url") String url,@JsonKey(name: "path") String path,@JsonKey(name: "name") String name
});




}
/// @nodoc
class _$CoverCopyWithImpl<$Res>
    implements $CoverCopyWith<$Res> {
  _$CoverCopyWithImpl(this._self, this._then);

  final Cover _self;
  final $Res Function(Cover) _then;

/// Create a copy of Cover
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? path = null,Object? name = null,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Cover].
extension CoverPatterns on Cover {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Cover value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Cover() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Cover value)  $default,){
final _that = this;
switch (_that) {
case _Cover():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Cover value)?  $default,){
final _that = this;
switch (_that) {
case _Cover() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "url")  String url, @JsonKey(name: "path")  String path, @JsonKey(name: "name")  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Cover() when $default != null:
return $default(_that.url,_that.path,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "url")  String url, @JsonKey(name: "path")  String path, @JsonKey(name: "name")  String name)  $default,) {final _that = this;
switch (_that) {
case _Cover():
return $default(_that.url,_that.path,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "url")  String url, @JsonKey(name: "path")  String path, @JsonKey(name: "name")  String name)?  $default,) {final _that = this;
switch (_that) {
case _Cover() when $default != null:
return $default(_that.url,_that.path,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Cover implements Cover {
  const _Cover({@JsonKey(name: "url") required this.url, @JsonKey(name: "path") required this.path, @JsonKey(name: "name") required this.name});
  factory _Cover.fromJson(Map<String, dynamic> json) => _$CoverFromJson(json);

@override@JsonKey(name: "url") final  String url;
@override@JsonKey(name: "path") final  String path;
@override@JsonKey(name: "name") final  String name;

/// Create a copy of Cover
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoverCopyWith<_Cover> get copyWith => __$CoverCopyWithImpl<_Cover>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CoverToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Cover&&(identical(other.url, url) || other.url == url)&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,path,name);

@override
String toString() {
  return 'Cover(url: $url, path: $path, name: $name)';
}


}

/// @nodoc
abstract mixin class _$CoverCopyWith<$Res> implements $CoverCopyWith<$Res> {
  factory _$CoverCopyWith(_Cover value, $Res Function(_Cover) _then) = __$CoverCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "url") String url,@JsonKey(name: "path") String path,@JsonKey(name: "name") String name
});




}
/// @nodoc
class __$CoverCopyWithImpl<$Res>
    implements _$CoverCopyWith<$Res> {
  __$CoverCopyWithImpl(this._self, this._then);

  final _Cover _self;
  final $Res Function(_Cover) _then;

/// Create a copy of Cover
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? path = null,Object? name = null,}) {
  return _then(_Cover(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Creator {

@JsonKey(name: "id") String get id;@JsonKey(name: "name") String get name;@JsonKey(name: "avatar") Cover get avatar;
/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatorCopyWith<Creator> get copyWith => _$CreatorCopyWithImpl<Creator>(this as Creator, _$identity);

  /// Serializes this Creator to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Creator&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatar, avatar) || other.avatar == avatar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,avatar);

@override
String toString() {
  return 'Creator(id: $id, name: $name, avatar: $avatar)';
}


}

/// @nodoc
abstract mixin class $CreatorCopyWith<$Res>  {
  factory $CreatorCopyWith(Creator value, $Res Function(Creator) _then) = _$CreatorCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "name") String name,@JsonKey(name: "avatar") Cover avatar
});


$CoverCopyWith<$Res> get avatar;

}
/// @nodoc
class _$CreatorCopyWithImpl<$Res>
    implements $CreatorCopyWith<$Res> {
  _$CreatorCopyWithImpl(this._self, this._then);

  final Creator _self;
  final $Res Function(Creator) _then;

/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? avatar = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as Cover,
  ));
}
/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoverCopyWith<$Res> get avatar {
  
  return $CoverCopyWith<$Res>(_self.avatar, (value) {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "name")  String name, @JsonKey(name: "avatar")  Cover avatar)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Creator() when $default != null:
return $default(_that.id,_that.name,_that.avatar);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "name")  String name, @JsonKey(name: "avatar")  Cover avatar)  $default,) {final _that = this;
switch (_that) {
case _Creator():
return $default(_that.id,_that.name,_that.avatar);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "id")  String id, @JsonKey(name: "name")  String name, @JsonKey(name: "avatar")  Cover avatar)?  $default,) {final _that = this;
switch (_that) {
case _Creator() when $default != null:
return $default(_that.id,_that.name,_that.avatar);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Creator implements Creator {
  const _Creator({@JsonKey(name: "id") required this.id, @JsonKey(name: "name") required this.name, @JsonKey(name: "avatar") required this.avatar});
  factory _Creator.fromJson(Map<String, dynamic> json) => _$CreatorFromJson(json);

@override@JsonKey(name: "id") final  String id;
@override@JsonKey(name: "name") final  String name;
@override@JsonKey(name: "avatar") final  Cover avatar;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Creator&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatar, avatar) || other.avatar == avatar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,avatar);

@override
String toString() {
  return 'Creator(id: $id, name: $name, avatar: $avatar)';
}


}

/// @nodoc
abstract mixin class _$CreatorCopyWith<$Res> implements $CreatorCopyWith<$Res> {
  factory _$CreatorCopyWith(_Creator value, $Res Function(_Creator) _then) = __$CreatorCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "name") String name,@JsonKey(name: "avatar") Cover avatar
});


@override $CoverCopyWith<$Res> get avatar;

}
/// @nodoc
class __$CreatorCopyWithImpl<$Res>
    implements _$CreatorCopyWith<$Res> {
  __$CreatorCopyWithImpl(this._self, this._then);

  final _Creator _self;
  final $Res Function(_Creator) _then;

/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? avatar = null,}) {
  return _then(_Creator(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as Cover,
  ));
}

/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoverCopyWith<$Res> get avatar {
  
  return $CoverCopyWith<$Res>(_self.avatar, (value) {
    return _then(_self.copyWith(avatar: value));
  });
}
}


/// @nodoc
mixin _$Ep {

@JsonKey(name: "id") String get id;@JsonKey(name: "name") String get name;@JsonKey(name: "order") int get order;
/// Create a copy of Ep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EpCopyWith<Ep> get copyWith => _$EpCopyWithImpl<Ep>(this as Ep, _$identity);

  /// Serializes this Ep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ep&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,order);

@override
String toString() {
  return 'Ep(id: $id, name: $name, order: $order)';
}


}

/// @nodoc
abstract mixin class $EpCopyWith<$Res>  {
  factory $EpCopyWith(Ep value, $Res Function(Ep) _then) = _$EpCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "name") String name,@JsonKey(name: "order") int order
});




}
/// @nodoc
class _$EpCopyWithImpl<$Res>
    implements $EpCopyWith<$Res> {
  _$EpCopyWithImpl(this._self, this._then);

  final Ep _self;
  final $Res Function(Ep) _then;

/// Create a copy of Ep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? order = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Ep].
extension EpPatterns on Ep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Ep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Ep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Ep value)  $default,){
final _that = this;
switch (_that) {
case _Ep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Ep value)?  $default,){
final _that = this;
switch (_that) {
case _Ep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "name")  String name, @JsonKey(name: "order")  int order)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Ep() when $default != null:
return $default(_that.id,_that.name,_that.order);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "name")  String name, @JsonKey(name: "order")  int order)  $default,) {final _that = this;
switch (_that) {
case _Ep():
return $default(_that.id,_that.name,_that.order);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "id")  String id, @JsonKey(name: "name")  String name, @JsonKey(name: "order")  int order)?  $default,) {final _that = this;
switch (_that) {
case _Ep() when $default != null:
return $default(_that.id,_that.name,_that.order);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Ep implements Ep {
  const _Ep({@JsonKey(name: "id") required this.id, @JsonKey(name: "name") required this.name, @JsonKey(name: "order") required this.order});
  factory _Ep.fromJson(Map<String, dynamic> json) => _$EpFromJson(json);

@override@JsonKey(name: "id") final  String id;
@override@JsonKey(name: "name") final  String name;
@override@JsonKey(name: "order") final  int order;

/// Create a copy of Ep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EpCopyWith<_Ep> get copyWith => __$EpCopyWithImpl<_Ep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EpToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ep&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,order);

@override
String toString() {
  return 'Ep(id: $id, name: $name, order: $order)';
}


}

/// @nodoc
abstract mixin class _$EpCopyWith<$Res> implements $EpCopyWith<$Res> {
  factory _$EpCopyWith(_Ep value, $Res Function(_Ep) _then) = __$EpCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "name") String name,@JsonKey(name: "order") int order
});




}
/// @nodoc
class __$EpCopyWithImpl<$Res>
    implements _$EpCopyWith<$Res> {
  __$EpCopyWithImpl(this._self, this._then);

  final _Ep _self;
  final $Res Function(_Ep) _then;

/// Create a copy of Ep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? order = null,}) {
  return _then(_Ep(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Recommend {

@JsonKey(name: "id") String get id;@JsonKey(name: "title") String get title;@JsonKey(name: "cover") Cover get cover;
/// Create a copy of Recommend
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecommendCopyWith<Recommend> get copyWith => _$RecommendCopyWithImpl<Recommend>(this as Recommend, _$identity);

  /// Serializes this Recommend to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Recommend&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.cover, cover) || other.cover == cover));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,cover);

@override
String toString() {
  return 'Recommend(id: $id, title: $title, cover: $cover)';
}


}

/// @nodoc
abstract mixin class $RecommendCopyWith<$Res>  {
  factory $RecommendCopyWith(Recommend value, $Res Function(Recommend) _then) = _$RecommendCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "title") String title,@JsonKey(name: "cover") Cover cover
});


$CoverCopyWith<$Res> get cover;

}
/// @nodoc
class _$RecommendCopyWithImpl<$Res>
    implements $RecommendCopyWith<$Res> {
  _$RecommendCopyWithImpl(this._self, this._then);

  final Recommend _self;
  final $Res Function(Recommend) _then;

/// Create a copy of Recommend
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? cover = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as Cover,
  ));
}
/// Create a copy of Recommend
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoverCopyWith<$Res> get cover {
  
  return $CoverCopyWith<$Res>(_self.cover, (value) {
    return _then(_self.copyWith(cover: value));
  });
}
}


/// Adds pattern-matching-related methods to [Recommend].
extension RecommendPatterns on Recommend {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Recommend value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Recommend() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Recommend value)  $default,){
final _that = this;
switch (_that) {
case _Recommend():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Recommend value)?  $default,){
final _that = this;
switch (_that) {
case _Recommend() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "title")  String title, @JsonKey(name: "cover")  Cover cover)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Recommend() when $default != null:
return $default(_that.id,_that.title,_that.cover);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "title")  String title, @JsonKey(name: "cover")  Cover cover)  $default,) {final _that = this;
switch (_that) {
case _Recommend():
return $default(_that.id,_that.title,_that.cover);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "id")  String id, @JsonKey(name: "title")  String title, @JsonKey(name: "cover")  Cover cover)?  $default,) {final _that = this;
switch (_that) {
case _Recommend() when $default != null:
return $default(_that.id,_that.title,_that.cover);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Recommend implements Recommend {
  const _Recommend({@JsonKey(name: "id") required this.id, @JsonKey(name: "title") required this.title, @JsonKey(name: "cover") required this.cover});
  factory _Recommend.fromJson(Map<String, dynamic> json) => _$RecommendFromJson(json);

@override@JsonKey(name: "id") final  String id;
@override@JsonKey(name: "title") final  String title;
@override@JsonKey(name: "cover") final  Cover cover;

/// Create a copy of Recommend
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecommendCopyWith<_Recommend> get copyWith => __$RecommendCopyWithImpl<_Recommend>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecommendToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Recommend&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.cover, cover) || other.cover == cover));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,cover);

@override
String toString() {
  return 'Recommend(id: $id, title: $title, cover: $cover)';
}


}

/// @nodoc
abstract mixin class _$RecommendCopyWith<$Res> implements $RecommendCopyWith<$Res> {
  factory _$RecommendCopyWith(_Recommend value, $Res Function(_Recommend) _then) = __$RecommendCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "title") String title,@JsonKey(name: "cover") Cover cover
});


@override $CoverCopyWith<$Res> get cover;

}
/// @nodoc
class __$RecommendCopyWithImpl<$Res>
    implements _$RecommendCopyWith<$Res> {
  __$RecommendCopyWithImpl(this._self, this._then);

  final _Recommend _self;
  final $Res Function(_Recommend) _then;

/// Create a copy of Recommend
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? cover = null,}) {
  return _then(_Recommend(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as Cover,
  ));
}

/// Create a copy of Recommend
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoverCopyWith<$Res> get cover {
  
  return $CoverCopyWith<$Res>(_self.cover, (value) {
    return _then(_self.copyWith(cover: value));
  });
}
}

// dart format on
