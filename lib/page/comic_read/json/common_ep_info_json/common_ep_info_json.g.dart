// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'common_ep_info_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CommonEpInfoJson _$CommonEpInfoJsonFromJson(Map<String, dynamic> json) =>
    _CommonEpInfoJson(
      epId: json['epId'] as String,
      epName: json['epName'] as String,
      series: (json['series'] as List<dynamic>)
          .map((e) => Series.fromJson(e as Map<String, dynamic>))
          .toList(),
      docs: (json['docs'] as List<dynamic>)
          .map((e) => Doc.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CommonEpInfoJsonToJson(_CommonEpInfoJson instance) =>
    <String, dynamic>{
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
