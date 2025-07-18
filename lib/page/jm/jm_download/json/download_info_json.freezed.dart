// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'download_info_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DownloadInfoJson {

@JsonKey(name: "id") int get id;@JsonKey(name: "name") String get name;@JsonKey(name: "images") List<dynamic> get images;@JsonKey(name: "addtime") String get addtime;@JsonKey(name: "description") String get description;@JsonKey(name: "total_views") String get totalViews;@JsonKey(name: "likes") String get likes;@JsonKey(name: "series") List<DownloadInfoJsonSeries> get series;@JsonKey(name: "series_id") String get seriesId;@JsonKey(name: "comment_total") String get commentTotal;@JsonKey(name: "author") List<String> get author;@JsonKey(name: "tags") List<String> get tags;@JsonKey(name: "works") List<String> get works;@JsonKey(name: "actors") List<String> get actors;@JsonKey(name: "related_list") List<RelatedList> get relatedList;@JsonKey(name: "liked") bool get liked;@JsonKey(name: "is_favorite") bool get isFavorite;@JsonKey(name: "is_aids") bool get isAids;@JsonKey(name: "price") String get price;@JsonKey(name: "purchased") String get purchased;
/// Create a copy of DownloadInfoJson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadInfoJsonCopyWith<DownloadInfoJson> get copyWith => _$DownloadInfoJsonCopyWithImpl<DownloadInfoJson>(this as DownloadInfoJson, _$identity);

  /// Serializes this DownloadInfoJson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadInfoJson&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.images, images)&&(identical(other.addtime, addtime) || other.addtime == addtime)&&(identical(other.description, description) || other.description == description)&&(identical(other.totalViews, totalViews) || other.totalViews == totalViews)&&(identical(other.likes, likes) || other.likes == likes)&&const DeepCollectionEquality().equals(other.series, series)&&(identical(other.seriesId, seriesId) || other.seriesId == seriesId)&&(identical(other.commentTotal, commentTotal) || other.commentTotal == commentTotal)&&const DeepCollectionEquality().equals(other.author, author)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.works, works)&&const DeepCollectionEquality().equals(other.actors, actors)&&const DeepCollectionEquality().equals(other.relatedList, relatedList)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.isAids, isAids) || other.isAids == isAids)&&(identical(other.price, price) || other.price == price)&&(identical(other.purchased, purchased) || other.purchased == purchased));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,const DeepCollectionEquality().hash(images),addtime,description,totalViews,likes,const DeepCollectionEquality().hash(series),seriesId,commentTotal,const DeepCollectionEquality().hash(author),const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(works),const DeepCollectionEquality().hash(actors),const DeepCollectionEquality().hash(relatedList),liked,isFavorite,isAids,price,purchased]);

@override
String toString() {
  return 'DownloadInfoJson(id: $id, name: $name, images: $images, addtime: $addtime, description: $description, totalViews: $totalViews, likes: $likes, series: $series, seriesId: $seriesId, commentTotal: $commentTotal, author: $author, tags: $tags, works: $works, actors: $actors, relatedList: $relatedList, liked: $liked, isFavorite: $isFavorite, isAids: $isAids, price: $price, purchased: $purchased)';
}


}

/// @nodoc
abstract mixin class $DownloadInfoJsonCopyWith<$Res>  {
  factory $DownloadInfoJsonCopyWith(DownloadInfoJson value, $Res Function(DownloadInfoJson) _then) = _$DownloadInfoJsonCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "id") int id,@JsonKey(name: "name") String name,@JsonKey(name: "images") List<dynamic> images,@JsonKey(name: "addtime") String addtime,@JsonKey(name: "description") String description,@JsonKey(name: "total_views") String totalViews,@JsonKey(name: "likes") String likes,@JsonKey(name: "series") List<DownloadInfoJsonSeries> series,@JsonKey(name: "series_id") String seriesId,@JsonKey(name: "comment_total") String commentTotal,@JsonKey(name: "author") List<String> author,@JsonKey(name: "tags") List<String> tags,@JsonKey(name: "works") List<String> works,@JsonKey(name: "actors") List<String> actors,@JsonKey(name: "related_list") List<RelatedList> relatedList,@JsonKey(name: "liked") bool liked,@JsonKey(name: "is_favorite") bool isFavorite,@JsonKey(name: "is_aids") bool isAids,@JsonKey(name: "price") String price,@JsonKey(name: "purchased") String purchased
});




}
/// @nodoc
class _$DownloadInfoJsonCopyWithImpl<$Res>
    implements $DownloadInfoJsonCopyWith<$Res> {
  _$DownloadInfoJsonCopyWithImpl(this._self, this._then);

  final DownloadInfoJson _self;
  final $Res Function(DownloadInfoJson) _then;

/// Create a copy of DownloadInfoJson
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
as List<DownloadInfoJsonSeries>,seriesId: null == seriesId ? _self.seriesId : seriesId // ignore: cast_nullable_to_non_nullable
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


/// Adds pattern-matching-related methods to [DownloadInfoJson].
extension DownloadInfoJsonPatterns on DownloadInfoJson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadInfoJson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadInfoJson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadInfoJson value)  $default,){
final _that = this;
switch (_that) {
case _DownloadInfoJson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadInfoJson value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadInfoJson() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  int id, @JsonKey(name: "name")  String name, @JsonKey(name: "images")  List<dynamic> images, @JsonKey(name: "addtime")  String addtime, @JsonKey(name: "description")  String description, @JsonKey(name: "total_views")  String totalViews, @JsonKey(name: "likes")  String likes, @JsonKey(name: "series")  List<DownloadInfoJsonSeries> series, @JsonKey(name: "series_id")  String seriesId, @JsonKey(name: "comment_total")  String commentTotal, @JsonKey(name: "author")  List<String> author, @JsonKey(name: "tags")  List<String> tags, @JsonKey(name: "works")  List<String> works, @JsonKey(name: "actors")  List<String> actors, @JsonKey(name: "related_list")  List<RelatedList> relatedList, @JsonKey(name: "liked")  bool liked, @JsonKey(name: "is_favorite")  bool isFavorite, @JsonKey(name: "is_aids")  bool isAids, @JsonKey(name: "price")  String price, @JsonKey(name: "purchased")  String purchased)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadInfoJson() when $default != null:
return $default(_that.id,_that.name,_that.images,_that.addtime,_that.description,_that.totalViews,_that.likes,_that.series,_that.seriesId,_that.commentTotal,_that.author,_that.tags,_that.works,_that.actors,_that.relatedList,_that.liked,_that.isFavorite,_that.isAids,_that.price,_that.purchased);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  int id, @JsonKey(name: "name")  String name, @JsonKey(name: "images")  List<dynamic> images, @JsonKey(name: "addtime")  String addtime, @JsonKey(name: "description")  String description, @JsonKey(name: "total_views")  String totalViews, @JsonKey(name: "likes")  String likes, @JsonKey(name: "series")  List<DownloadInfoJsonSeries> series, @JsonKey(name: "series_id")  String seriesId, @JsonKey(name: "comment_total")  String commentTotal, @JsonKey(name: "author")  List<String> author, @JsonKey(name: "tags")  List<String> tags, @JsonKey(name: "works")  List<String> works, @JsonKey(name: "actors")  List<String> actors, @JsonKey(name: "related_list")  List<RelatedList> relatedList, @JsonKey(name: "liked")  bool liked, @JsonKey(name: "is_favorite")  bool isFavorite, @JsonKey(name: "is_aids")  bool isAids, @JsonKey(name: "price")  String price, @JsonKey(name: "purchased")  String purchased)  $default,) {final _that = this;
switch (_that) {
case _DownloadInfoJson():
return $default(_that.id,_that.name,_that.images,_that.addtime,_that.description,_that.totalViews,_that.likes,_that.series,_that.seriesId,_that.commentTotal,_that.author,_that.tags,_that.works,_that.actors,_that.relatedList,_that.liked,_that.isFavorite,_that.isAids,_that.price,_that.purchased);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "id")  int id, @JsonKey(name: "name")  String name, @JsonKey(name: "images")  List<dynamic> images, @JsonKey(name: "addtime")  String addtime, @JsonKey(name: "description")  String description, @JsonKey(name: "total_views")  String totalViews, @JsonKey(name: "likes")  String likes, @JsonKey(name: "series")  List<DownloadInfoJsonSeries> series, @JsonKey(name: "series_id")  String seriesId, @JsonKey(name: "comment_total")  String commentTotal, @JsonKey(name: "author")  List<String> author, @JsonKey(name: "tags")  List<String> tags, @JsonKey(name: "works")  List<String> works, @JsonKey(name: "actors")  List<String> actors, @JsonKey(name: "related_list")  List<RelatedList> relatedList, @JsonKey(name: "liked")  bool liked, @JsonKey(name: "is_favorite")  bool isFavorite, @JsonKey(name: "is_aids")  bool isAids, @JsonKey(name: "price")  String price, @JsonKey(name: "purchased")  String purchased)?  $default,) {final _that = this;
switch (_that) {
case _DownloadInfoJson() when $default != null:
return $default(_that.id,_that.name,_that.images,_that.addtime,_that.description,_that.totalViews,_that.likes,_that.series,_that.seriesId,_that.commentTotal,_that.author,_that.tags,_that.works,_that.actors,_that.relatedList,_that.liked,_that.isFavorite,_that.isAids,_that.price,_that.purchased);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DownloadInfoJson implements DownloadInfoJson {
  const _DownloadInfoJson({@JsonKey(name: "id") required this.id, @JsonKey(name: "name") required this.name, @JsonKey(name: "images") required final  List<dynamic> images, @JsonKey(name: "addtime") required this.addtime, @JsonKey(name: "description") required this.description, @JsonKey(name: "total_views") required this.totalViews, @JsonKey(name: "likes") required this.likes, @JsonKey(name: "series") required final  List<DownloadInfoJsonSeries> series, @JsonKey(name: "series_id") required this.seriesId, @JsonKey(name: "comment_total") required this.commentTotal, @JsonKey(name: "author") required final  List<String> author, @JsonKey(name: "tags") required final  List<String> tags, @JsonKey(name: "works") required final  List<String> works, @JsonKey(name: "actors") required final  List<String> actors, @JsonKey(name: "related_list") required final  List<RelatedList> relatedList, @JsonKey(name: "liked") required this.liked, @JsonKey(name: "is_favorite") required this.isFavorite, @JsonKey(name: "is_aids") required this.isAids, @JsonKey(name: "price") required this.price, @JsonKey(name: "purchased") required this.purchased}): _images = images,_series = series,_author = author,_tags = tags,_works = works,_actors = actors,_relatedList = relatedList;
  factory _DownloadInfoJson.fromJson(Map<String, dynamic> json) => _$DownloadInfoJsonFromJson(json);

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
 final  List<DownloadInfoJsonSeries> _series;
@override@JsonKey(name: "series") List<DownloadInfoJsonSeries> get series {
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

/// Create a copy of DownloadInfoJson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadInfoJsonCopyWith<_DownloadInfoJson> get copyWith => __$DownloadInfoJsonCopyWithImpl<_DownloadInfoJson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DownloadInfoJsonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadInfoJson&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.addtime, addtime) || other.addtime == addtime)&&(identical(other.description, description) || other.description == description)&&(identical(other.totalViews, totalViews) || other.totalViews == totalViews)&&(identical(other.likes, likes) || other.likes == likes)&&const DeepCollectionEquality().equals(other._series, _series)&&(identical(other.seriesId, seriesId) || other.seriesId == seriesId)&&(identical(other.commentTotal, commentTotal) || other.commentTotal == commentTotal)&&const DeepCollectionEquality().equals(other._author, _author)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._works, _works)&&const DeepCollectionEquality().equals(other._actors, _actors)&&const DeepCollectionEquality().equals(other._relatedList, _relatedList)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.isAids, isAids) || other.isAids == isAids)&&(identical(other.price, price) || other.price == price)&&(identical(other.purchased, purchased) || other.purchased == purchased));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,const DeepCollectionEquality().hash(_images),addtime,description,totalViews,likes,const DeepCollectionEquality().hash(_series),seriesId,commentTotal,const DeepCollectionEquality().hash(_author),const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_works),const DeepCollectionEquality().hash(_actors),const DeepCollectionEquality().hash(_relatedList),liked,isFavorite,isAids,price,purchased]);

@override
String toString() {
  return 'DownloadInfoJson(id: $id, name: $name, images: $images, addtime: $addtime, description: $description, totalViews: $totalViews, likes: $likes, series: $series, seriesId: $seriesId, commentTotal: $commentTotal, author: $author, tags: $tags, works: $works, actors: $actors, relatedList: $relatedList, liked: $liked, isFavorite: $isFavorite, isAids: $isAids, price: $price, purchased: $purchased)';
}


}

/// @nodoc
abstract mixin class _$DownloadInfoJsonCopyWith<$Res> implements $DownloadInfoJsonCopyWith<$Res> {
  factory _$DownloadInfoJsonCopyWith(_DownloadInfoJson value, $Res Function(_DownloadInfoJson) _then) = __$DownloadInfoJsonCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "id") int id,@JsonKey(name: "name") String name,@JsonKey(name: "images") List<dynamic> images,@JsonKey(name: "addtime") String addtime,@JsonKey(name: "description") String description,@JsonKey(name: "total_views") String totalViews,@JsonKey(name: "likes") String likes,@JsonKey(name: "series") List<DownloadInfoJsonSeries> series,@JsonKey(name: "series_id") String seriesId,@JsonKey(name: "comment_total") String commentTotal,@JsonKey(name: "author") List<String> author,@JsonKey(name: "tags") List<String> tags,@JsonKey(name: "works") List<String> works,@JsonKey(name: "actors") List<String> actors,@JsonKey(name: "related_list") List<RelatedList> relatedList,@JsonKey(name: "liked") bool liked,@JsonKey(name: "is_favorite") bool isFavorite,@JsonKey(name: "is_aids") bool isAids,@JsonKey(name: "price") String price,@JsonKey(name: "purchased") String purchased
});




}
/// @nodoc
class __$DownloadInfoJsonCopyWithImpl<$Res>
    implements _$DownloadInfoJsonCopyWith<$Res> {
  __$DownloadInfoJsonCopyWithImpl(this._self, this._then);

  final _DownloadInfoJson _self;
  final $Res Function(_DownloadInfoJson) _then;

/// Create a copy of DownloadInfoJson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? images = null,Object? addtime = null,Object? description = null,Object? totalViews = null,Object? likes = null,Object? series = null,Object? seriesId = null,Object? commentTotal = null,Object? author = null,Object? tags = null,Object? works = null,Object? actors = null,Object? relatedList = null,Object? liked = null,Object? isFavorite = null,Object? isAids = null,Object? price = null,Object? purchased = null,}) {
  return _then(_DownloadInfoJson(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<dynamic>,addtime: null == addtime ? _self.addtime : addtime // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,totalViews: null == totalViews ? _self.totalViews : totalViews // ignore: cast_nullable_to_non_nullable
as String,likes: null == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as String,series: null == series ? _self._series : series // ignore: cast_nullable_to_non_nullable
as List<DownloadInfoJsonSeries>,seriesId: null == seriesId ? _self.seriesId : seriesId // ignore: cast_nullable_to_non_nullable
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


/// Adds pattern-matching-related methods to [RelatedList].
extension RelatedListPatterns on RelatedList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RelatedList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RelatedList() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RelatedList value)  $default,){
final _that = this;
switch (_that) {
case _RelatedList():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RelatedList value)?  $default,){
final _that = this;
switch (_that) {
case _RelatedList() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "author")  String author, @JsonKey(name: "name")  String name, @JsonKey(name: "image")  String image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RelatedList() when $default != null:
return $default(_that.id,_that.author,_that.name,_that.image);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "author")  String author, @JsonKey(name: "name")  String name, @JsonKey(name: "image")  String image)  $default,) {final _that = this;
switch (_that) {
case _RelatedList():
return $default(_that.id,_that.author,_that.name,_that.image);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "id")  String id, @JsonKey(name: "author")  String author, @JsonKey(name: "name")  String name, @JsonKey(name: "image")  String image)?  $default,) {final _that = this;
switch (_that) {
case _RelatedList() when $default != null:
return $default(_that.id,_that.author,_that.name,_that.image);case _:
  return null;

}
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
mixin _$DownloadInfoJsonSeries {

@JsonKey(name: "id") String get id;@JsonKey(name: "name") String get name;@JsonKey(name: "sort") String get sort;@JsonKey(name: "info") Info get info;
/// Create a copy of DownloadInfoJsonSeries
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadInfoJsonSeriesCopyWith<DownloadInfoJsonSeries> get copyWith => _$DownloadInfoJsonSeriesCopyWithImpl<DownloadInfoJsonSeries>(this as DownloadInfoJsonSeries, _$identity);

  /// Serializes this DownloadInfoJsonSeries to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadInfoJsonSeries&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sort, sort) || other.sort == sort)&&(identical(other.info, info) || other.info == info));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,sort,info);

@override
String toString() {
  return 'DownloadInfoJsonSeries(id: $id, name: $name, sort: $sort, info: $info)';
}


}

/// @nodoc
abstract mixin class $DownloadInfoJsonSeriesCopyWith<$Res>  {
  factory $DownloadInfoJsonSeriesCopyWith(DownloadInfoJsonSeries value, $Res Function(DownloadInfoJsonSeries) _then) = _$DownloadInfoJsonSeriesCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "name") String name,@JsonKey(name: "sort") String sort,@JsonKey(name: "info") Info info
});


$InfoCopyWith<$Res> get info;

}
/// @nodoc
class _$DownloadInfoJsonSeriesCopyWithImpl<$Res>
    implements $DownloadInfoJsonSeriesCopyWith<$Res> {
  _$DownloadInfoJsonSeriesCopyWithImpl(this._self, this._then);

  final DownloadInfoJsonSeries _self;
  final $Res Function(DownloadInfoJsonSeries) _then;

/// Create a copy of DownloadInfoJsonSeries
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? sort = null,Object? info = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as String,info: null == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as Info,
  ));
}
/// Create a copy of DownloadInfoJsonSeries
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InfoCopyWith<$Res> get info {
  
  return $InfoCopyWith<$Res>(_self.info, (value) {
    return _then(_self.copyWith(info: value));
  });
}
}


/// Adds pattern-matching-related methods to [DownloadInfoJsonSeries].
extension DownloadInfoJsonSeriesPatterns on DownloadInfoJsonSeries {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadInfoJsonSeries value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadInfoJsonSeries() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadInfoJsonSeries value)  $default,){
final _that = this;
switch (_that) {
case _DownloadInfoJsonSeries():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadInfoJsonSeries value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadInfoJsonSeries() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "name")  String name, @JsonKey(name: "sort")  String sort, @JsonKey(name: "info")  Info info)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadInfoJsonSeries() when $default != null:
return $default(_that.id,_that.name,_that.sort,_that.info);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "name")  String name, @JsonKey(name: "sort")  String sort, @JsonKey(name: "info")  Info info)  $default,) {final _that = this;
switch (_that) {
case _DownloadInfoJsonSeries():
return $default(_that.id,_that.name,_that.sort,_that.info);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "id")  String id, @JsonKey(name: "name")  String name, @JsonKey(name: "sort")  String sort, @JsonKey(name: "info")  Info info)?  $default,) {final _that = this;
switch (_that) {
case _DownloadInfoJsonSeries() when $default != null:
return $default(_that.id,_that.name,_that.sort,_that.info);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DownloadInfoJsonSeries implements DownloadInfoJsonSeries {
  const _DownloadInfoJsonSeries({@JsonKey(name: "id") required this.id, @JsonKey(name: "name") required this.name, @JsonKey(name: "sort") required this.sort, @JsonKey(name: "info") required this.info});
  factory _DownloadInfoJsonSeries.fromJson(Map<String, dynamic> json) => _$DownloadInfoJsonSeriesFromJson(json);

@override@JsonKey(name: "id") final  String id;
@override@JsonKey(name: "name") final  String name;
@override@JsonKey(name: "sort") final  String sort;
@override@JsonKey(name: "info") final  Info info;

/// Create a copy of DownloadInfoJsonSeries
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadInfoJsonSeriesCopyWith<_DownloadInfoJsonSeries> get copyWith => __$DownloadInfoJsonSeriesCopyWithImpl<_DownloadInfoJsonSeries>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DownloadInfoJsonSeriesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadInfoJsonSeries&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sort, sort) || other.sort == sort)&&(identical(other.info, info) || other.info == info));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,sort,info);

@override
String toString() {
  return 'DownloadInfoJsonSeries(id: $id, name: $name, sort: $sort, info: $info)';
}


}

/// @nodoc
abstract mixin class _$DownloadInfoJsonSeriesCopyWith<$Res> implements $DownloadInfoJsonSeriesCopyWith<$Res> {
  factory _$DownloadInfoJsonSeriesCopyWith(_DownloadInfoJsonSeries value, $Res Function(_DownloadInfoJsonSeries) _then) = __$DownloadInfoJsonSeriesCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "name") String name,@JsonKey(name: "sort") String sort,@JsonKey(name: "info") Info info
});


@override $InfoCopyWith<$Res> get info;

}
/// @nodoc
class __$DownloadInfoJsonSeriesCopyWithImpl<$Res>
    implements _$DownloadInfoJsonSeriesCopyWith<$Res> {
  __$DownloadInfoJsonSeriesCopyWithImpl(this._self, this._then);

  final _DownloadInfoJsonSeries _self;
  final $Res Function(_DownloadInfoJsonSeries) _then;

/// Create a copy of DownloadInfoJsonSeries
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? sort = null,Object? info = null,}) {
  return _then(_DownloadInfoJsonSeries(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as String,info: null == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as Info,
  ));
}

/// Create a copy of DownloadInfoJsonSeries
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InfoCopyWith<$Res> get info {
  
  return $InfoCopyWith<$Res>(_self.info, (value) {
    return _then(_self.copyWith(info: value));
  });
}
}


/// @nodoc
mixin _$Info {

@JsonKey(name: "id") int get id;@JsonKey(name: "series") List<InfoSeries> get series;@JsonKey(name: "tags") String get tags;@JsonKey(name: "name") String get name;@JsonKey(name: "images") List<String> get images;@JsonKey(name: "addtime") String get addtime;@JsonKey(name: "series_id") String get seriesId;@JsonKey(name: "is_favorite") bool get isFavorite;@JsonKey(name: "liked") bool get liked;
/// Create a copy of Info
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InfoCopyWith<Info> get copyWith => _$InfoCopyWithImpl<Info>(this as Info, _$identity);

  /// Serializes this Info to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Info&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.series, series)&&(identical(other.tags, tags) || other.tags == tags)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.images, images)&&(identical(other.addtime, addtime) || other.addtime == addtime)&&(identical(other.seriesId, seriesId) || other.seriesId == seriesId)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.liked, liked) || other.liked == liked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(series),tags,name,const DeepCollectionEquality().hash(images),addtime,seriesId,isFavorite,liked);

@override
String toString() {
  return 'Info(id: $id, series: $series, tags: $tags, name: $name, images: $images, addtime: $addtime, seriesId: $seriesId, isFavorite: $isFavorite, liked: $liked)';
}


}

/// @nodoc
abstract mixin class $InfoCopyWith<$Res>  {
  factory $InfoCopyWith(Info value, $Res Function(Info) _then) = _$InfoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "id") int id,@JsonKey(name: "series") List<InfoSeries> series,@JsonKey(name: "tags") String tags,@JsonKey(name: "name") String name,@JsonKey(name: "images") List<String> images,@JsonKey(name: "addtime") String addtime,@JsonKey(name: "series_id") String seriesId,@JsonKey(name: "is_favorite") bool isFavorite,@JsonKey(name: "liked") bool liked
});




}
/// @nodoc
class _$InfoCopyWithImpl<$Res>
    implements $InfoCopyWith<$Res> {
  _$InfoCopyWithImpl(this._self, this._then);

  final Info _self;
  final $Res Function(Info) _then;

/// Create a copy of Info
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? series = null,Object? tags = null,Object? name = null,Object? images = null,Object? addtime = null,Object? seriesId = null,Object? isFavorite = null,Object? liked = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,series: null == series ? _self.series : series // ignore: cast_nullable_to_non_nullable
as List<InfoSeries>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<String>,addtime: null == addtime ? _self.addtime : addtime // ignore: cast_nullable_to_non_nullable
as String,seriesId: null == seriesId ? _self.seriesId : seriesId // ignore: cast_nullable_to_non_nullable
as String,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Info].
extension InfoPatterns on Info {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Info value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Info() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Info value)  $default,){
final _that = this;
switch (_that) {
case _Info():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Info value)?  $default,){
final _that = this;
switch (_that) {
case _Info() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  int id, @JsonKey(name: "series")  List<InfoSeries> series, @JsonKey(name: "tags")  String tags, @JsonKey(name: "name")  String name, @JsonKey(name: "images")  List<String> images, @JsonKey(name: "addtime")  String addtime, @JsonKey(name: "series_id")  String seriesId, @JsonKey(name: "is_favorite")  bool isFavorite, @JsonKey(name: "liked")  bool liked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Info() when $default != null:
return $default(_that.id,_that.series,_that.tags,_that.name,_that.images,_that.addtime,_that.seriesId,_that.isFavorite,_that.liked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  int id, @JsonKey(name: "series")  List<InfoSeries> series, @JsonKey(name: "tags")  String tags, @JsonKey(name: "name")  String name, @JsonKey(name: "images")  List<String> images, @JsonKey(name: "addtime")  String addtime, @JsonKey(name: "series_id")  String seriesId, @JsonKey(name: "is_favorite")  bool isFavorite, @JsonKey(name: "liked")  bool liked)  $default,) {final _that = this;
switch (_that) {
case _Info():
return $default(_that.id,_that.series,_that.tags,_that.name,_that.images,_that.addtime,_that.seriesId,_that.isFavorite,_that.liked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "id")  int id, @JsonKey(name: "series")  List<InfoSeries> series, @JsonKey(name: "tags")  String tags, @JsonKey(name: "name")  String name, @JsonKey(name: "images")  List<String> images, @JsonKey(name: "addtime")  String addtime, @JsonKey(name: "series_id")  String seriesId, @JsonKey(name: "is_favorite")  bool isFavorite, @JsonKey(name: "liked")  bool liked)?  $default,) {final _that = this;
switch (_that) {
case _Info() when $default != null:
return $default(_that.id,_that.series,_that.tags,_that.name,_that.images,_that.addtime,_that.seriesId,_that.isFavorite,_that.liked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Info implements Info {
  const _Info({@JsonKey(name: "id") required this.id, @JsonKey(name: "series") required final  List<InfoSeries> series, @JsonKey(name: "tags") required this.tags, @JsonKey(name: "name") required this.name, @JsonKey(name: "images") required final  List<String> images, @JsonKey(name: "addtime") required this.addtime, @JsonKey(name: "series_id") required this.seriesId, @JsonKey(name: "is_favorite") required this.isFavorite, @JsonKey(name: "liked") required this.liked}): _series = series,_images = images;
  factory _Info.fromJson(Map<String, dynamic> json) => _$InfoFromJson(json);

@override@JsonKey(name: "id") final  int id;
 final  List<InfoSeries> _series;
@override@JsonKey(name: "series") List<InfoSeries> get series {
  if (_series is EqualUnmodifiableListView) return _series;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_series);
}

@override@JsonKey(name: "tags") final  String tags;
@override@JsonKey(name: "name") final  String name;
 final  List<String> _images;
@override@JsonKey(name: "images") List<String> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

@override@JsonKey(name: "addtime") final  String addtime;
@override@JsonKey(name: "series_id") final  String seriesId;
@override@JsonKey(name: "is_favorite") final  bool isFavorite;
@override@JsonKey(name: "liked") final  bool liked;

/// Create a copy of Info
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InfoCopyWith<_Info> get copyWith => __$InfoCopyWithImpl<_Info>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Info&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._series, _series)&&(identical(other.tags, tags) || other.tags == tags)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.addtime, addtime) || other.addtime == addtime)&&(identical(other.seriesId, seriesId) || other.seriesId == seriesId)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.liked, liked) || other.liked == liked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_series),tags,name,const DeepCollectionEquality().hash(_images),addtime,seriesId,isFavorite,liked);

@override
String toString() {
  return 'Info(id: $id, series: $series, tags: $tags, name: $name, images: $images, addtime: $addtime, seriesId: $seriesId, isFavorite: $isFavorite, liked: $liked)';
}


}

/// @nodoc
abstract mixin class _$InfoCopyWith<$Res> implements $InfoCopyWith<$Res> {
  factory _$InfoCopyWith(_Info value, $Res Function(_Info) _then) = __$InfoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "id") int id,@JsonKey(name: "series") List<InfoSeries> series,@JsonKey(name: "tags") String tags,@JsonKey(name: "name") String name,@JsonKey(name: "images") List<String> images,@JsonKey(name: "addtime") String addtime,@JsonKey(name: "series_id") String seriesId,@JsonKey(name: "is_favorite") bool isFavorite,@JsonKey(name: "liked") bool liked
});




}
/// @nodoc
class __$InfoCopyWithImpl<$Res>
    implements _$InfoCopyWith<$Res> {
  __$InfoCopyWithImpl(this._self, this._then);

  final _Info _self;
  final $Res Function(_Info) _then;

/// Create a copy of Info
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? series = null,Object? tags = null,Object? name = null,Object? images = null,Object? addtime = null,Object? seriesId = null,Object? isFavorite = null,Object? liked = null,}) {
  return _then(_Info(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,series: null == series ? _self._series : series // ignore: cast_nullable_to_non_nullable
as List<InfoSeries>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<String>,addtime: null == addtime ? _self.addtime : addtime // ignore: cast_nullable_to_non_nullable
as String,seriesId: null == seriesId ? _self.seriesId : seriesId // ignore: cast_nullable_to_non_nullable
as String,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$InfoSeries {

@JsonKey(name: "id") String get id;@JsonKey(name: "name") String get name;@JsonKey(name: "sort") String get sort;
/// Create a copy of InfoSeries
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InfoSeriesCopyWith<InfoSeries> get copyWith => _$InfoSeriesCopyWithImpl<InfoSeries>(this as InfoSeries, _$identity);

  /// Serializes this InfoSeries to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InfoSeries&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sort, sort) || other.sort == sort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,sort);

@override
String toString() {
  return 'InfoSeries(id: $id, name: $name, sort: $sort)';
}


}

/// @nodoc
abstract mixin class $InfoSeriesCopyWith<$Res>  {
  factory $InfoSeriesCopyWith(InfoSeries value, $Res Function(InfoSeries) _then) = _$InfoSeriesCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "name") String name,@JsonKey(name: "sort") String sort
});




}
/// @nodoc
class _$InfoSeriesCopyWithImpl<$Res>
    implements $InfoSeriesCopyWith<$Res> {
  _$InfoSeriesCopyWithImpl(this._self, this._then);

  final InfoSeries _self;
  final $Res Function(InfoSeries) _then;

/// Create a copy of InfoSeries
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


/// Adds pattern-matching-related methods to [InfoSeries].
extension InfoSeriesPatterns on InfoSeries {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InfoSeries value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InfoSeries() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InfoSeries value)  $default,){
final _that = this;
switch (_that) {
case _InfoSeries():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InfoSeries value)?  $default,){
final _that = this;
switch (_that) {
case _InfoSeries() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "name")  String name, @JsonKey(name: "sort")  String sort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InfoSeries() when $default != null:
return $default(_that.id,_that.name,_that.sort);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "name")  String name, @JsonKey(name: "sort")  String sort)  $default,) {final _that = this;
switch (_that) {
case _InfoSeries():
return $default(_that.id,_that.name,_that.sort);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "id")  String id, @JsonKey(name: "name")  String name, @JsonKey(name: "sort")  String sort)?  $default,) {final _that = this;
switch (_that) {
case _InfoSeries() when $default != null:
return $default(_that.id,_that.name,_that.sort);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InfoSeries implements InfoSeries {
  const _InfoSeries({@JsonKey(name: "id") required this.id, @JsonKey(name: "name") required this.name, @JsonKey(name: "sort") required this.sort});
  factory _InfoSeries.fromJson(Map<String, dynamic> json) => _$InfoSeriesFromJson(json);

@override@JsonKey(name: "id") final  String id;
@override@JsonKey(name: "name") final  String name;
@override@JsonKey(name: "sort") final  String sort;

/// Create a copy of InfoSeries
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InfoSeriesCopyWith<_InfoSeries> get copyWith => __$InfoSeriesCopyWithImpl<_InfoSeries>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InfoSeriesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InfoSeries&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sort, sort) || other.sort == sort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,sort);

@override
String toString() {
  return 'InfoSeries(id: $id, name: $name, sort: $sort)';
}


}

/// @nodoc
abstract mixin class _$InfoSeriesCopyWith<$Res> implements $InfoSeriesCopyWith<$Res> {
  factory _$InfoSeriesCopyWith(_InfoSeries value, $Res Function(_InfoSeries) _then) = __$InfoSeriesCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "name") String name,@JsonKey(name: "sort") String sort
});




}
/// @nodoc
class __$InfoSeriesCopyWithImpl<$Res>
    implements _$InfoSeriesCopyWith<$Res> {
  __$InfoSeriesCopyWithImpl(this._self, this._then);

  final _InfoSeries _self;
  final $Res Function(_InfoSeries) _then;

/// Create a copy of InfoSeries
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? sort = null,}) {
  return _then(_InfoSeries(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
