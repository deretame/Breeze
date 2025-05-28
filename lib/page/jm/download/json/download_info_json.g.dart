// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_info_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DownloadInfoJson _$DownloadInfoJsonFromJson(
  Map<String, dynamic> json,
) => _DownloadInfoJson(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  images: json['images'] as List<dynamic>,
  addtime: json['addtime'] as String,
  description: json['description'] as String,
  totalViews: json['total_views'] as String,
  likes: json['likes'] as String,
  series:
      (json['series'] as List<dynamic>)
          .map(
            (e) => DownloadInfoJsonSeries.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
  seriesId: json['series_id'] as String,
  commentTotal: json['comment_total'] as String,
  author: (json['author'] as List<dynamic>).map((e) => e as String).toList(),
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  works: (json['works'] as List<dynamic>).map((e) => e as String).toList(),
  actors: (json['actors'] as List<dynamic>).map((e) => e as String).toList(),
  relatedList:
      (json['related_list'] as List<dynamic>)
          .map((e) => RelatedList.fromJson(e as Map<String, dynamic>))
          .toList(),
  liked: json['liked'] as bool,
  isFavorite: json['is_favorite'] as bool,
  isAids: json['is_aids'] as bool,
  price: json['price'] as String,
  purchased: json['purchased'] as String,
);

Map<String, dynamic> _$DownloadInfoJsonToJson(_DownloadInfoJson instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'images': instance.images,
      'addtime': instance.addtime,
      'description': instance.description,
      'total_views': instance.totalViews,
      'likes': instance.likes,
      'series': instance.series,
      'series_id': instance.seriesId,
      'comment_total': instance.commentTotal,
      'author': instance.author,
      'tags': instance.tags,
      'works': instance.works,
      'actors': instance.actors,
      'related_list': instance.relatedList,
      'liked': instance.liked,
      'is_favorite': instance.isFavorite,
      'is_aids': instance.isAids,
      'price': instance.price,
      'purchased': instance.purchased,
    };

_RelatedList _$RelatedListFromJson(Map<String, dynamic> json) => _RelatedList(
  id: json['id'] as String,
  author: json['author'] as String,
  name: json['name'] as String,
  image: json['image'] as String,
);

Map<String, dynamic> _$RelatedListToJson(_RelatedList instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author': instance.author,
      'name': instance.name,
      'image': instance.image,
    };

_DownloadInfoJsonSeries _$DownloadInfoJsonSeriesFromJson(
  Map<String, dynamic> json,
) => _DownloadInfoJsonSeries(
  id: json['id'] as String,
  name: json['name'] as String,
  sort: json['sort'] as String,
  info: Info.fromJson(json['info'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DownloadInfoJsonSeriesToJson(
  _DownloadInfoJsonSeries instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'sort': instance.sort,
  'info': instance.info,
};

_Info _$InfoFromJson(Map<String, dynamic> json) => _Info(
  id: (json['id'] as num).toInt(),
  series:
      (json['series'] as List<dynamic>)
          .map((e) => InfoSeries.fromJson(e as Map<String, dynamic>))
          .toList(),
  tags: json['tags'] as String,
  name: json['name'] as String,
  images: (json['images'] as List<dynamic>).map((e) => e as String).toList(),
  addtime: json['addtime'] as String,
  seriesId: json['series_id'] as String,
  isFavorite: json['is_favorite'] as bool,
  liked: json['liked'] as bool,
);

Map<String, dynamic> _$InfoToJson(_Info instance) => <String, dynamic>{
  'id': instance.id,
  'series': instance.series,
  'tags': instance.tags,
  'name': instance.name,
  'images': instance.images,
  'addtime': instance.addtime,
  'series_id': instance.seriesId,
  'is_favorite': instance.isFavorite,
  'liked': instance.liked,
};

_InfoSeries _$InfoSeriesFromJson(Map<String, dynamic> json) => _InfoSeries(
  id: json['id'] as String,
  name: json['name'] as String,
  sort: json['sort'] as String,
);

Map<String, dynamic> _$InfoSeriesToJson(_InfoSeries instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sort': instance.sort,
    };
