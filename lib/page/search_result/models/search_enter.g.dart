// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_enter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SearchEnter _$SearchEnterFromJson(Map<String, dynamic> json) => _SearchEnter(
  url: json['url'] as String,
  from: json['from'] as String,
  keyword: json['keyword'] as String,
  type: json['type'] as String,
  state: json['state'] as String,
  sort: json['sort'] as String,
  categories: (json['categories'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  pageCount: (json['pageCount'] as num).toInt(),
  refresh: json['refresh'] as String,
);

Map<String, dynamic> _$SearchEnterToJson(_SearchEnter instance) =>
    <String, dynamic>{
      'url': instance.url,
      'from': instance.from,
      'keyword': instance.keyword,
      'type': instance.type,
      'state': instance.state,
      'sort': instance.sort,
      'categories': instance.categories,
      'pageCount': instance.pageCount,
      'refresh': instance.refresh,
    };
