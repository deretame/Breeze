// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jm_comic_info_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JmComicInfoJson {

@JsonKey(name: "id") int get id;@JsonKey(name: "name") String get name;@JsonKey(name: "images") List<dynamic> get images;@JsonKey(name: "addtime") String get addtime;@JsonKey(name: "description") String get description;@JsonKey(name: "total_views") String get totalViews;@JsonKey(name: "likes") String get likes;@JsonKey(name: "series") List<Series> get series;@JsonKey(name: "series_id") String get seriesId;@JsonKey(name: "comment_total") String get commentTotal;@JsonKey(name: "author") List<String> get author;@JsonKey(name: "tags") List<String> get tags;@JsonKey(name: "works") List<String> get works;@JsonKey(name: "actors") List<String> get actors;@JsonKey(name: "related_list") List<RelatedList> get relatedList;@JsonKey(name: "liked") bool get liked;@JsonKey(name: "is_favorite") bool get isFavorite;@JsonKey(name: "is_aids") bool get isAids;@JsonKey(name: "price") String get price;@JsonKey(name: "purchased") String get purchased;
/// Create a copy of JmComicInfoJson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JmComicInfoJsonCopyWith<JmComicInfoJson> get copyWith => _$JmComicInfoJsonCopyWithImpl<JmComicInfoJson>(this as JmComicInfoJson, _$identity);

  /// Serializes this JmComicInfoJson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JmComicInfoJson&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.images, images)&&(identical(other.addtime, addtime) || other.addtime == addtime)&&(identical(other.description, description) || other.description == description)&&(identical(other.totalViews, totalViews) || other.totalViews == totalViews)&&(identical(other.likes, likes) || other.likes == likes)&&const DeepCollectionEquality().equals(other.series, series)&&(identical(other.seriesId, seriesId) || other.seriesId == seriesId)&&(identical(other.commentTotal, commentTotal) || other.commentTotal == commentTotal)&&const DeepCollectionEquality().equals(other.author, author)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.works, works)&&const DeepCollectionEquality().equals(other.actors, actors)&&const DeepCollectionEquality().equals(other.relatedList, relatedList)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.isAids, isAids) || other.isAids == isAids)&&(identical(other.price, price) || other.price == price)&&(identical(other.purchased, purchased) || other.purchased == purchased));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,const DeepCollectionEquality().hash(images),addtime,description,totalViews,likes,const DeepCollectionEquality().hash(series),seriesId,commentTotal,const DeepCollectionEquality().hash(author),const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(works),const DeepCollectionEquality().hash(actors),const DeepCollectionEquality().hash(relatedList),liked,isFavorite,isAids,price,purchased]);

@override
String toString() {
  return 'JmComicInfoJson(id: $id, name: $name, images: $images, addtime: $addtime, description: $description, totalViews: $totalViews, likes: $likes, series: $series, seriesId: $seriesId, commentTotal: $commentTotal, author: $author, tags: $tags, works: $works, actors: $actors, relatedList: $relatedList, liked: $liked, isFavorite: $isFavorite, isAids: $isAids, price: $price, purchased: $purchased)';
}


}

/// @nodoc
abstract mixin class $JmComicInfoJsonCopyWith<$Res>  {
  factory $JmComicInfoJsonCopyWith(JmComicInfoJson value, $Res Function(JmComicInfoJson) _then) = _$JmComicInfoJsonCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "id") int id,@JsonKey(name: "name") String name,@JsonKey(name: "images") List<dynamic> images,@JsonKey(name: "addtime") String addtime,@JsonKey(name: "description") String description,@JsonKey(name: "total_views") String totalViews,@JsonKey(name: "likes") String likes,@JsonKey(name: "series") List<Series> series,@JsonKey(name: "series_id") String seriesId,@JsonKey(name: "comment_total") String commentTotal,@JsonKey(name: "author") List<String> author,@JsonKey(name: "tags") List<String> tags,@JsonKey(name: "works") List<String> works,@JsonKey(name: "actors") List<String> actors,@JsonKey(name: "related_list") List<RelatedList> relatedList,@JsonKey(name: "liked") bool liked,@JsonKey(name: "is_favorite") bool isFavorite,@JsonKey(name: "is_aids") bool isAids,@JsonKey(name: "price") String price,@JsonKey(name: "purchased") String purchased
});




}
/// @nodoc
class _$JmComicInfoJsonCopyWithImpl<$Res>
    implements $JmComicInfoJsonCopyWith<$Res> {
  _$JmComicInfoJsonCopyWithImpl(this._self, this._then);

  final JmComicInfoJson _self;
  final $Res Function(JmComicInfoJson) _then;

/// Create a copy of JmComicInfoJson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? images = null,Object? addtime = null,Object? description = null,Object? totalViews = null,Object? likes = null,Object? series = null,Object? seriesId = null,Object? commentTotal = null,Object? author = null,Object? tags = null,Object? works = null,Object? actors = null,Object? relatedList = null,Object? liked = null,Object? isFavorite = null,Object? isAids = null,Object? price = null,Object? purchased = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<dynamic>,addtime: null == addtime ? _self.addtime : addtime // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,totalViews: null == totalViews ? _self.totalViews : totalViews // ignore: cast_nullable_to_non_nullable
as String,likes: null == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as String,series: null == series ? _self.series : series // ignore: cast_nullable_to_non_nullable
as List<Series>,seriesId: null == seriesId ? _self.seriesId : seriesId // ignore: cast_nullable_to_non_nullable
as String,commentTotal: null == commentTotal ? _self.commentTotal : commentTotal // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,works: null == works ? _self.works : works // ignore: cast_nullable_to_non_nullable
as List<String>,actors: null == actors ? _self.actors : actors // ignore: cast_nullable_to_non_nullable
as List<String>,relatedList: null == relatedList ? _self.relatedList : relatedList // ignore: cast_nullable_to_non_nullable
as List<RelatedList>,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,isAids: null == isAids ? _self.isAids : isAids // ignore: cast_nullable_to_non_nullable
as bool,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,purchased: null == purchased ? _self.purchased : purchased // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _JmComicInfoJson implements JmComicInfoJson {
  const _JmComicInfoJson({@JsonKey(name: "id") required this.id, @JsonKey(name: "name") required this.name, @JsonKey(name: "images") required final  List<dynamic> images, @JsonKey(name: "addtime") required this.addtime, @JsonKey(name: "description") required this.description, @JsonKey(name: "total_views") required this.totalViews, @JsonKey(name: "likes") required this.likes, @JsonKey(name: "series") required final  List<Series> series, @JsonKey(name: "series_id") required this.seriesId, @JsonKey(name: "comment_total") required this.commentTotal, @JsonKey(name: "author") required final  List<String> author, @JsonKey(name: "tags") required final  List<String> tags, @JsonKey(name: "works") required final  List<String> works, @JsonKey(name: "actors") required final  List<String> actors, @JsonKey(name: "related_list") required final  List<RelatedList> relatedList, @JsonKey(name: "liked") required this.liked, @JsonKey(name: "is_favorite") required this.isFavorite, @JsonKey(name: "is_aids") required this.isAids, @JsonKey(name: "price") required this.price, @JsonKey(name: "purchased") required this.purchased}): _images = images,_series = series,_author = author,_tags = tags,_works = works,_actors = actors,_relatedList = relatedList;
  factory _JmComicInfoJson.fromJson(Map<String, dynamic> json) => _$JmComicInfoJsonFromJson(json);

@override@JsonKey(name: "id") final  int id;
@override@JsonKey(name: "name") final  String name;
 final  List<dynamic> _images;
@override@JsonKey(name: "images") List<dynamic> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

@override@JsonKey(name: "addtime") final  String addtime;
@override@JsonKey(name: "description") final  String description;
@override@JsonKey(name: "total_views") final  String totalViews;
@override@JsonKey(name: "likes") final  String likes;
 final  List<Series> _series;
@override@JsonKey(name: "series") List<Series> get series {
  if (_series is EqualUnmodifiableListView) return _series;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_series);
}

@override@JsonKey(name: "series_id") final  String seriesId;
@override@JsonKey(name: "comment_total") final  String commentTotal;
 final  List<String> _author;
@override@JsonKey(name: "author") List<String> get author {
  if (_author is EqualUnmodifiableListView) return _author;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_author);
}

 final  List<String> _tags;
@override@JsonKey(name: "tags") List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
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

 final  List<RelatedList> _relatedList;
@override@JsonKey(name: "related_list") List<RelatedList> get relatedList {
  if (_relatedList is EqualUnmodifiableListView) return _relatedList;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_relatedList);
}

@override@JsonKey(name: "liked") final  bool liked;
@override@JsonKey(name: "is_favorite") final  bool isFavorite;
@override@JsonKey(name: "is_aids") final  bool isAids;
@override@JsonKey(name: "price") final  String price;
@override@JsonKey(name: "purchased") final  String purchased;

/// Create a copy of JmComicInfoJson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JmComicInfoJsonCopyWith<_JmComicInfoJson> get copyWith => __$JmComicInfoJsonCopyWithImpl<_JmComicInfoJson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JmComicInfoJsonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JmComicInfoJson&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.addtime, addtime) || other.addtime == addtime)&&(identical(other.description, description) || other.description == description)&&(identical(other.totalViews, totalViews) || other.totalViews == totalViews)&&(identical(other.likes, likes) || other.likes == likes)&&const DeepCollectionEquality().equals(other._series, _series)&&(identical(other.seriesId, seriesId) || other.seriesId == seriesId)&&(identical(other.commentTotal, commentTotal) || other.commentTotal == commentTotal)&&const DeepCollectionEquality().equals(other._author, _author)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._works, _works)&&const DeepCollectionEquality().equals(other._actors, _actors)&&const DeepCollectionEquality().equals(other._relatedList, _relatedList)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.isAids, isAids) || other.isAids == isAids)&&(identical(other.price, price) || other.price == price)&&(identical(other.purchased, purchased) || other.purchased == purchased));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,const DeepCollectionEquality().hash(_images),addtime,description,totalViews,likes,const DeepCollectionEquality().hash(_series),seriesId,commentTotal,const DeepCollectionEquality().hash(_author),const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_works),const DeepCollectionEquality().hash(_actors),const DeepCollectionEquality().hash(_relatedList),liked,isFavorite,isAids,price,purchased]);

@override
String toString() {
  return 'JmComicInfoJson(id: $id, name: $name, images: $images, addtime: $addtime, description: $description, totalViews: $totalViews, likes: $likes, series: $series, seriesId: $seriesId, commentTotal: $commentTotal, author: $author, tags: $tags, works: $works, actors: $actors, relatedList: $relatedList, liked: $liked, isFavorite: $isFavorite, isAids: $isAids, price: $price, purchased: $purchased)';
}


}

/// @nodoc
abstract mixin class _$JmComicInfoJsonCopyWith<$Res> implements $JmComicInfoJsonCopyWith<$Res> {
  factory _$JmComicInfoJsonCopyWith(_JmComicInfoJson value, $Res Function(_JmComicInfoJson) _then) = __$JmComicInfoJsonCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "id") int id,@JsonKey(name: "name") String name,@JsonKey(name: "images") List<dynamic> images,@JsonKey(name: "addtime") String addtime,@JsonKey(name: "description") String description,@JsonKey(name: "total_views") String totalViews,@JsonKey(name: "likes") String likes,@JsonKey(name: "series") List<Series> series,@JsonKey(name: "series_id") String seriesId,@JsonKey(name: "comment_total") String commentTotal,@JsonKey(name: "author") List<String> author,@JsonKey(name: "tags") List<String> tags,@JsonKey(name: "works") List<String> works,@JsonKey(name: "actors") List<String> actors,@JsonKey(name: "related_list") List<RelatedList> relatedList,@JsonKey(name: "liked") bool liked,@JsonKey(name: "is_favorite") bool isFavorite,@JsonKey(name: "is_aids") bool isAids,@JsonKey(name: "price") String price,@JsonKey(name: "purchased") String purchased
});




}
/// @nodoc
class __$JmComicInfoJsonCopyWithImpl<$Res>
    implements _$JmComicInfoJsonCopyWith<$Res> {
  __$JmComicInfoJsonCopyWithImpl(this._self, this._then);

  final _JmComicInfoJson _self;
  final $Res Function(_JmComicInfoJson) _then;

/// Create a copy of JmComicInfoJson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? images = null,Object? addtime = null,Object? description = null,Object? totalViews = null,Object? likes = null,Object? series = null,Object? seriesId = null,Object? commentTotal = null,Object? author = null,Object? tags = null,Object? works = null,Object? actors = null,Object? relatedList = null,Object? liked = null,Object? isFavorite = null,Object? isAids = null,Object? price = null,Object? purchased = null,}) {
  return _then(_JmComicInfoJson(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<dynamic>,addtime: null == addtime ? _self.addtime : addtime // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,totalViews: null == totalViews ? _self.totalViews : totalViews // ignore: cast_nullable_to_non_nullable
as String,likes: null == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as String,series: null == series ? _self._series : series // ignore: cast_nullable_to_non_nullable
as List<Series>,seriesId: null == seriesId ? _self.seriesId : seriesId // ignore: cast_nullable_to_non_nullable
as String,commentTotal: null == commentTotal ? _self.commentTotal : commentTotal // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self._author : author // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,works: null == works ? _self._works : works // ignore: cast_nullable_to_non_nullable
as List<String>,actors: null == actors ? _self._actors : actors // ignore: cast_nullable_to_non_nullable
as List<String>,relatedList: null == relatedList ? _self._relatedList : relatedList // ignore: cast_nullable_to_non_nullable
as List<RelatedList>,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,isAids: null == isAids ? _self.isAids : isAids // ignore: cast_nullable_to_non_nullable
as bool,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,purchased: null == purchased ? _self.purchased : purchased // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$RelatedList {

@JsonKey(name: "id") String get id;@JsonKey(name: "author") String get author;@JsonKey(name: "name") String get name;@JsonKey(name: "image") String get image;
/// Create a copy of RelatedList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelatedListCopyWith<RelatedList> get copyWith => _$RelatedListCopyWithImpl<RelatedList>(this as RelatedList, _$identity);

  /// Serializes this RelatedList to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelatedList&&(identical(other.id, id) || other.id == id)&&(identical(other.author, author) || other.author == author)&&(identical(other.name, name) || other.name == name)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,author,name,image);

@override
String toString() {
  return 'RelatedList(id: $id, author: $author, name: $name, image: $image)';
}


}

/// @nodoc
abstract mixin class $RelatedListCopyWith<$Res>  {
  factory $RelatedListCopyWith(RelatedList value, $Res Function(RelatedList) _then) = _$RelatedListCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "author") String author,@JsonKey(name: "name") String name,@JsonKey(name: "image") String image
});




}
/// @nodoc
class _$RelatedListCopyWithImpl<$Res>
    implements $RelatedListCopyWith<$Res> {
  _$RelatedListCopyWithImpl(this._self, this._then);

  final RelatedList _self;
  final $Res Function(RelatedList) _then;

/// Create a copy of RelatedList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? author = null,Object? name = null,Object? image = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _RelatedList implements RelatedList {
  const _RelatedList({@JsonKey(name: "id") required this.id, @JsonKey(name: "author") required this.author, @JsonKey(name: "name") required this.name, @JsonKey(name: "image") required this.image});
  factory _RelatedList.fromJson(Map<String, dynamic> json) => _$RelatedListFromJson(json);

@override@JsonKey(name: "id") final  String id;
@override@JsonKey(name: "author") final  String author;
@override@JsonKey(name: "name") final  String name;
@override@JsonKey(name: "image") final  String image;

/// Create a copy of RelatedList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RelatedListCopyWith<_RelatedList> get copyWith => __$RelatedListCopyWithImpl<_RelatedList>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RelatedListToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RelatedList&&(identical(other.id, id) || other.id == id)&&(identical(other.author, author) || other.author == author)&&(identical(other.name, name) || other.name == name)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,author,name,image);

@override
String toString() {
  return 'RelatedList(id: $id, author: $author, name: $name, image: $image)';
}


}

/// @nodoc
abstract mixin class _$RelatedListCopyWith<$Res> implements $RelatedListCopyWith<$Res> {
  factory _$RelatedListCopyWith(_RelatedList value, $Res Function(_RelatedList) _then) = __$RelatedListCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "author") String author,@JsonKey(name: "name") String name,@JsonKey(name: "image") String image
});




}
/// @nodoc
class __$RelatedListCopyWithImpl<$Res>
    implements _$RelatedListCopyWith<$Res> {
  __$RelatedListCopyWithImpl(this._self, this._then);

  final _RelatedList _self;
  final $Res Function(_RelatedList) _then;

/// Create a copy of RelatedList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? author = null,Object? name = null,Object? image = null,}) {
  return _then(_RelatedList(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
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
