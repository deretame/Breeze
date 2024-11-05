// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hot_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HotListImpl _$$HotListImplFromJson(Map<String, dynamic> json) =>
    _$HotListImpl(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String,
      data: Data.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$HotListImplToJson(_$HotListImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
    };

_$DataImpl _$$DataImplFromJson(Map<String, dynamic> json) => _$DataImpl(
      comics: (json['comics'] as List<dynamic>)
          .map((e) => Comic.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$DataImplToJson(_$DataImpl instance) =>
    <String, dynamic>{
      'comics': instance.comics,
    };

_$ComicImpl _$$ComicImplFromJson(Map<String, dynamic> json) => _$ComicImpl(
      id: json['_id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      totalViews: (json['totalViews'] as num).toInt(),
      totalLikes: (json['totalLikes'] as num).toInt(),
      pagesCount: (json['pagesCount'] as num).toInt(),
      epsCount: (json['epsCount'] as num).toInt(),
      finished: json['finished'] as bool,
      categories: (json['categories'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      thumb: Thumb.fromJson(json['thumb'] as Map<String, dynamic>),
      viewsCount: (json['viewsCount'] as num).toInt(),
      leaderboardCount: (json['leaderboardCount'] as num).toInt(),
    );

Map<String, dynamic> _$$ComicImplToJson(_$ComicImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'title': instance.title,
      'author': instance.author,
      'totalViews': instance.totalViews,
      'totalLikes': instance.totalLikes,
      'pagesCount': instance.pagesCount,
      'epsCount': instance.epsCount,
      'finished': instance.finished,
      'categories': instance.categories,
      'thumb': instance.thumb,
      'viewsCount': instance.viewsCount,
      'leaderboardCount': instance.leaderboardCount,
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
