// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommend.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecommendImpl _$$RecommendImplFromJson(Map<String, dynamic> json) =>
    _$RecommendImpl(
      comics: (json['comics'] as List<dynamic>)
          .map((e) => Comic.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$RecommendImplToJson(_$RecommendImpl instance) =>
    <String, dynamic>{
      'comics': instance.comics,
    };

_$ComicImpl _$$ComicImplFromJson(Map<String, dynamic> json) => _$ComicImpl(
      id: json['_id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      pagesCount: (json['pagesCount'] as num).toInt(),
      epsCount: (json['epsCount'] as num).toInt(),
      finished: json['finished'] as bool,
      categories: (json['categories'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      thumb: Thumb.fromJson(json['thumb'] as Map<String, dynamic>),
      likesCount: (json['likesCount'] as num).toInt(),
    );

Map<String, dynamic> _$$ComicImplToJson(_$ComicImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'title': instance.title,
      'author': instance.author,
      'pagesCount': instance.pagesCount,
      'epsCount': instance.epsCount,
      'finished': instance.finished,
      'categories': instance.categories,
      'thumb': instance.thumb,
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
