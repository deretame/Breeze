// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
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

 int get id; String get name; List<dynamic> get images; String get addtime; String get description; String get totalViews; String get likes; List<DownloadInfoJsonSeries> get series; String get seriesId; String get commentTotal; List<String> get author; List<String> get tags; List<String> get works; List<String> get actors; bool get liked; bool get isFavorite; bool get isAids; String get price; String get purchased;
/// Create a copy of DownloadInfoJson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadInfoJsonCopyWith<DownloadInfoJson> get copyWith => _$DownloadInfoJsonCopyWithImpl<DownloadInfoJson>(this as DownloadInfoJson, _$identity);

  /// Serializes this DownloadInfoJson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadInfoJson&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.images, images)&&(identical(other.addtime, addtime) || other.addtime == addtime)&&(identical(other.description, description) || other.description == description)&&(identical(other.totalViews, totalViews) || other.totalViews == totalViews)&&(identical(other.likes, likes) || other.likes == likes)&&const DeepCollectionEquality().equals(other.series, series)&&(identical(other.seriesId, seriesId) || other.seriesId == seriesId)&&(identical(other.commentTotal, commentTotal) || other.commentTotal == commentTotal)&&const DeepCollectionEquality().equals(other.author, author)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.works, works)&&const DeepCollectionEquality().equals(other.actors, actors)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.isAids, isAids) || other.isAids == isAids)&&(identical(other.price, price) || other.price == price)&&(identical(other.purchased, purchased) || other.purchased == purchased));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,const DeepCollectionEquality().hash(images),addtime,description,totalViews,likes,const DeepCollectionEquality().hash(series),seriesId,commentTotal,const DeepCollectionEquality().hash(author),const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(works),const DeepCollectionEquality().hash(actors),liked,isFavorite,isAids,price,purchased]);

@override
String toString() {
  return 'DownloadInfoJson(id: $id, name: $name, images: $images, addtime: $addtime, description: $description, totalViews: $totalViews, likes: $likes, series: $series, seriesId: $seriesId, commentTotal: $commentTotal, author: $author, tags: $tags, works: $works, actors: $actors, liked: $liked, isFavorite: $isFavorite, isAids: $isAids, price: $price, purchased: $purchased)';
}


}

/// @nodoc
abstract mixin class $DownloadInfoJsonCopyWith<$Res>  {
  factory $DownloadInfoJsonCopyWith(DownloadInfoJson value, $Res Function(DownloadInfoJson) _then) = _$DownloadInfoJsonCopyWithImpl;
@useResult
$Res call({
 int id, String name, List<dynamic> images, String addtime, String description, String totalViews, String likes, List<DownloadInfoJsonSeries> series, String seriesId, String commentTotal, List<String> author, List<String> tags, List<String> works, List<String> actors, bool liked, bool isFavorite, bool isAids, String price, String purchased
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? images = null,Object? addtime = null,Object? description = null,Object? totalViews = null,Object? likes = null,Object? series = null,Object? seriesId = null,Object? commentTotal = null,Object? author = null,Object? tags = null,Object? works = null,Object? actors = null,Object? liked = null,Object? isFavorite = null,Object? isAids = null,Object? price = null,Object? purchased = null,}) {
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
as List<String>,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
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

class _DownloadInfoJson implements DownloadInfoJson {
  const _DownloadInfoJson({required this.id, required this.name, required final  List<dynamic> images, required this.addtime, required this.description, required this.totalViews, required this.likes, required final  List<DownloadInfoJsonSeries> series, required this.seriesId, required this.commentTotal, required final  List<String> author, required final  List<String> tags, required final  List<String> works, required final  List<String> actors, required this.liked, required this.isFavorite, required this.isAids, required this.price, required this.purchased}): _images = images,_series = series,_author = author,_tags = tags,_works = works,_actors = actors;
  factory _DownloadInfoJson.fromJson(Map<String, dynamic> json) => _$DownloadInfoJsonFromJson(json);

@override final  int id;
@override final  String name;
 final  List<dynamic> _images;
@override List<dynamic> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

@override final  String addtime;
@override final  String description;
@override final  String totalViews;
@override final  String likes;
 final  List<DownloadInfoJsonSeries> _series;
@override List<DownloadInfoJsonSeries> get series {
  if (_series is EqualUnmodifiableListView) return _series;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_series);
}

@override final  String seriesId;
@override final  String commentTotal;
 final  List<String> _author;
@override List<String> get author {
  if (_author is EqualUnmodifiableListView) return _author;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_author);
}

 final  List<String> _tags;
@override List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  List<String> _works;
@override List<String> get works {
  if (_works is EqualUnmodifiableListView) return _works;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_works);
}

 final  List<String> _actors;
@override List<String> get actors {
  if (_actors is EqualUnmodifiableListView) return _actors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_actors);
}

@override final  bool liked;
@override final  bool isFavorite;
@override final  bool isAids;
@override final  String price;
@override final  String purchased;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadInfoJson&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.addtime, addtime) || other.addtime == addtime)&&(identical(other.description, description) || other.description == description)&&(identical(other.totalViews, totalViews) || other.totalViews == totalViews)&&(identical(other.likes, likes) || other.likes == likes)&&const DeepCollectionEquality().equals(other._series, _series)&&(identical(other.seriesId, seriesId) || other.seriesId == seriesId)&&(identical(other.commentTotal, commentTotal) || other.commentTotal == commentTotal)&&const DeepCollectionEquality().equals(other._author, _author)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._works, _works)&&const DeepCollectionEquality().equals(other._actors, _actors)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.isAids, isAids) || other.isAids == isAids)&&(identical(other.price, price) || other.price == price)&&(identical(other.purchased, purchased) || other.purchased == purchased));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,const DeepCollectionEquality().hash(_images),addtime,description,totalViews,likes,const DeepCollectionEquality().hash(_series),seriesId,commentTotal,const DeepCollectionEquality().hash(_author),const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_works),const DeepCollectionEquality().hash(_actors),liked,isFavorite,isAids,price,purchased]);

@override
String toString() {
  return 'DownloadInfoJson(id: $id, name: $name, images: $images, addtime: $addtime, description: $description, totalViews: $totalViews, likes: $likes, series: $series, seriesId: $seriesId, commentTotal: $commentTotal, author: $author, tags: $tags, works: $works, actors: $actors, liked: $liked, isFavorite: $isFavorite, isAids: $isAids, price: $price, purchased: $purchased)';
}


}

/// @nodoc
abstract mixin class _$DownloadInfoJsonCopyWith<$Res> implements $DownloadInfoJsonCopyWith<$Res> {
  factory _$DownloadInfoJsonCopyWith(_DownloadInfoJson value, $Res Function(_DownloadInfoJson) _then) = __$DownloadInfoJsonCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, List<dynamic> images, String addtime, String description, String totalViews, String likes, List<DownloadInfoJsonSeries> series, String seriesId, String commentTotal, List<String> author, List<String> tags, List<String> works, List<String> actors, bool liked, bool isFavorite, bool isAids, String price, String purchased
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? images = null,Object? addtime = null,Object? description = null,Object? totalViews = null,Object? likes = null,Object? series = null,Object? seriesId = null,Object? commentTotal = null,Object? author = null,Object? tags = null,Object? works = null,Object? actors = null,Object? liked = null,Object? isFavorite = null,Object? isAids = null,Object? price = null,Object? purchased = null,}) {
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
as List<String>,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,isAids: null == isAids ? _self.isAids : isAids // ignore: cast_nullable_to_non_nullable
as bool,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,purchased: null == purchased ? _self.purchased : purchased // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DownloadInfoJsonSeries {

 String get id; String get name; String get sort; Info get info;
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
 String id, String name, String sort, Info info
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


/// @nodoc
@JsonSerializable()

class _DownloadInfoJsonSeries implements DownloadInfoJsonSeries {
  const _DownloadInfoJsonSeries({required this.id, required this.name, required this.sort, required this.info});
  factory _DownloadInfoJsonSeries.fromJson(Map<String, dynamic> json) => _$DownloadInfoJsonSeriesFromJson(json);

@override final  String id;
@override final  String name;
@override final  String sort;
@override final  Info info;

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
 String id, String name, String sort, Info info
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

 String get epId; String get epName; List<InfoSeries> get series; List<Doc> get docs;
/// Create a copy of Info
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InfoCopyWith<Info> get copyWith => _$InfoCopyWithImpl<Info>(this as Info, _$identity);

  /// Serializes this Info to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Info&&(identical(other.epId, epId) || other.epId == epId)&&(identical(other.epName, epName) || other.epName == epName)&&const DeepCollectionEquality().equals(other.series, series)&&const DeepCollectionEquality().equals(other.docs, docs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,epId,epName,const DeepCollectionEquality().hash(series),const DeepCollectionEquality().hash(docs));

@override
String toString() {
  return 'Info(epId: $epId, epName: $epName, series: $series, docs: $docs)';
}


}

/// @nodoc
abstract mixin class $InfoCopyWith<$Res>  {
  factory $InfoCopyWith(Info value, $Res Function(Info) _then) = _$InfoCopyWithImpl;
@useResult
$Res call({
 String epId, String epName, List<InfoSeries> series, List<Doc> docs
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
@pragma('vm:prefer-inline') @override $Res call({Object? epId = null,Object? epName = null,Object? series = null,Object? docs = null,}) {
  return _then(_self.copyWith(
epId: null == epId ? _self.epId : epId // ignore: cast_nullable_to_non_nullable
as String,epName: null == epName ? _self.epName : epName // ignore: cast_nullable_to_non_nullable
as String,series: null == series ? _self.series : series // ignore: cast_nullable_to_non_nullable
as List<InfoSeries>,docs: null == docs ? _self.docs : docs // ignore: cast_nullable_to_non_nullable
as List<Doc>,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Info implements Info {
  const _Info({required this.epId, required this.epName, required final  List<InfoSeries> series, required final  List<Doc> docs}): _series = series,_docs = docs;
  factory _Info.fromJson(Map<String, dynamic> json) => _$InfoFromJson(json);

@override final  String epId;
@override final  String epName;
 final  List<InfoSeries> _series;
@override List<InfoSeries> get series {
  if (_series is EqualUnmodifiableListView) return _series;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_series);
}

 final  List<Doc> _docs;
@override List<Doc> get docs {
  if (_docs is EqualUnmodifiableListView) return _docs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_docs);
}


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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Info&&(identical(other.epId, epId) || other.epId == epId)&&(identical(other.epName, epName) || other.epName == epName)&&const DeepCollectionEquality().equals(other._series, _series)&&const DeepCollectionEquality().equals(other._docs, _docs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,epId,epName,const DeepCollectionEquality().hash(_series),const DeepCollectionEquality().hash(_docs));

@override
String toString() {
  return 'Info(epId: $epId, epName: $epName, series: $series, docs: $docs)';
}


}

/// @nodoc
abstract mixin class _$InfoCopyWith<$Res> implements $InfoCopyWith<$Res> {
  factory _$InfoCopyWith(_Info value, $Res Function(_Info) _then) = __$InfoCopyWithImpl;
@override @useResult
$Res call({
 String epId, String epName, List<InfoSeries> series, List<Doc> docs
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
@override @pragma('vm:prefer-inline') $Res call({Object? epId = null,Object? epName = null,Object? series = null,Object? docs = null,}) {
  return _then(_Info(
epId: null == epId ? _self.epId : epId // ignore: cast_nullable_to_non_nullable
as String,epName: null == epName ? _self.epName : epName // ignore: cast_nullable_to_non_nullable
as String,series: null == series ? _self._series : series // ignore: cast_nullable_to_non_nullable
as List<InfoSeries>,docs: null == docs ? _self._docs : docs // ignore: cast_nullable_to_non_nullable
as List<Doc>,
  ));
}


}


/// @nodoc
mixin _$Doc {

 String get originalName; String get path; String get fileServer; String get id;
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
 String originalName, String path, String fileServer, String id
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
  const _Doc({required this.originalName, required this.path, required this.fileServer, required this.id});
  factory _Doc.fromJson(Map<String, dynamic> json) => _$DocFromJson(json);

@override final  String originalName;
@override final  String path;
@override final  String fileServer;
@override final  String id;

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
 String originalName, String path, String fileServer, String id
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
mixin _$InfoSeries {

 String get id; String get name; String get sort;
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
 String id, String name, String sort
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


/// @nodoc
@JsonSerializable()

class _InfoSeries implements InfoSeries {
  const _InfoSeries({required this.id, required this.name, required this.sort});
  factory _InfoSeries.fromJson(Map<String, dynamic> json) => _$InfoSeriesFromJson(json);

@override final  String id;
@override final  String name;
@override final  String sort;

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
 String id, String name, String sort
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
