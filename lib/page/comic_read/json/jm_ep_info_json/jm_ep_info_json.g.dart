// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jm_ep_info_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JmEpInfoJson _$JmEpInfoJsonFromJson(Map<String, dynamic> json) =>
    _JmEpInfoJson(
      id: (json['id'] as num).toInt(),
      series: (json['series'] as List<dynamic>)
          .map((e) => Series.fromJson(e as Map<String, dynamic>))
          .toList(),
      tags: json['tags'] as String,
      name: json['name'] as String,
      images: (json['images'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      addtime: json['addtime'] as String,
      seriesId: json['series_id'] as String,
      isFavorite: json['is_favorite'] as bool,
      liked: json['liked'] as bool,
    );

Map<String, dynamic> _$JmEpInfoJsonToJson(_JmEpInfoJson instance) =>
    <String, dynamic>{
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

_Series _$SeriesFromJson(Map<String, dynamic> json) => _Series(
  id: json['id'] as String,
  name: json['name'] as String,
  sort: json['sort'] as String,
);

Map<String, dynamic> _$SeriesToJson(_Series instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'sort': instance.sort,
};
