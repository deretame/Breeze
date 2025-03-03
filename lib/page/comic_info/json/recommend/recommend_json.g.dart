// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommend_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecommendJsonImpl _$$RecommendJsonImplFromJson(Map<String, dynamic> json) =>
    _$RecommendJsonImpl(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String,
      data: Data.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$RecommendJsonImplToJson(_$RecommendJsonImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
    };

_$DataImpl _$$DataImplFromJson(Map<String, dynamic> json) => _$DataImpl(
  comics:
      (json['comics'] as List<dynamic>)
          .map((e) => Comic.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$$DataImplToJson(_$DataImpl instance) =>
    <String, dynamic>{'comics': instance.comics};

_$ComicImpl _$$ComicImplFromJson(Map<String, dynamic> json) => _$ComicImpl(
  id: json['_id'] as String,
  title: json['title'] as String,
  thumb: Thumb.fromJson(json['thumb'] as Map<String, dynamic>),
  author: json['author'] as String,
  categories:
      (json['categories'] as List<dynamic>).map((e) => e as String).toList(),
  finished: json['finished'] as bool,
  epsCount: (json['epsCount'] as num).toInt(),
  pagesCount: (json['pagesCount'] as num).toInt(),
  likesCount: (json['likesCount'] as num).toInt(),
);

Map<String, dynamic> _$$ComicImplToJson(_$ComicImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'title': instance.title,
      'thumb': instance.thumb,
      'author': instance.author,
      'categories': instance.categories,
      'finished': instance.finished,
      'epsCount': instance.epsCount,
      'pagesCount': instance.pagesCount,
      'likesCount': instance.likesCount,
    };

_$ThumbImpl _$$ThumbImplFromJson(Map<String, dynamic> json) => _$ThumbImpl(
  originalName: json['originalName'] as String,
  path: json['path'] as String,
  fileServer: json['fileServer'] as String,
);

Map<String, dynamic> _$$ThumbImplToJson(_$ThumbImpl instance) =>
    <String, dynamic>{
      'originalName': instance.originalName,
      'path': instance.path,
      'fileServer': instance.fileServer,
    };
