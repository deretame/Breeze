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
  totalViews: json['totalViews'] as String,
  likes: json['likes'] as String,
  series:
      (json['series'] as List<dynamic>)
          .map(
            (e) => DownloadInfoJsonSeries.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
  seriesId: json['seriesId'] as String,
  commentTotal: json['commentTotal'] as String,
  author: (json['author'] as List<dynamic>).map((e) => e as String).toList(),
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  works: (json['works'] as List<dynamic>).map((e) => e as String).toList(),
  actors: (json['actors'] as List<dynamic>).map((e) => e as String).toList(),
  liked: json['liked'] as bool,
  isFavorite: json['isFavorite'] as bool,
  isAids: json['isAids'] as bool,
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
      'totalViews': instance.totalViews,
      'likes': instance.likes,
      'series': instance.series,
      'seriesId': instance.seriesId,
      'commentTotal': instance.commentTotal,
      'author': instance.author,
      'tags': instance.tags,
      'works': instance.works,
      'actors': instance.actors,
      'liked': instance.liked,
      'isFavorite': instance.isFavorite,
      'isAids': instance.isAids,
      'price': instance.price,
      'purchased': instance.purchased,
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
  epId: json['epId'] as String,
  epName: json['epName'] as String,
  series:
      (json['series'] as List<dynamic>)
          .map((e) => InfoSeries.fromJson(e as Map<String, dynamic>))
          .toList(),
  docs:
      (json['docs'] as List<dynamic>)
          .map((e) => Doc.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$InfoToJson(_Info instance) => <String, dynamic>{
  'epId': instance.epId,
  'epName': instance.epName,
  'series': instance.series,
  'docs': instance.docs,
};

_Doc _$DocFromJson(Map<String, dynamic> json) => _Doc(
  originalName: json['originalName'] as String,
  path: json['path'] as String,
  fileServer: json['fileServer'] as String,
  id: json['id'] as String,
);

Map<String, dynamic> _$DocToJson(_Doc instance) => <String, dynamic>{
  'originalName': instance.originalName,
  'path': instance.path,
  'fileServer': instance.fileServer,
  'id': instance.id,
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
