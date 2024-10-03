// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person_favourite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PersonFavouriteImpl _$$PersonFavouriteImplFromJson(
        Map<String, dynamic> json) =>
    _$PersonFavouriteImpl(
      comics: Comics.fromJson(json['comics'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$PersonFavouriteImplToJson(
        _$PersonFavouriteImpl instance) =>
    <String, dynamic>{
      'comics': instance.comics,
    };

_$ComicsImpl _$$ComicsImplFromJson(Map<String, dynamic> json) => _$ComicsImpl(
      pages: (json['pages'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      docs: (json['docs'] as List<dynamic>)
          .map((e) => Doc.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
    );

Map<String, dynamic> _$$ComicsImplToJson(_$ComicsImpl instance) =>
    <String, dynamic>{
      'pages': instance.pages,
      'total': instance.total,
      'docs': instance.docs,
      'page': instance.page,
      'limit': instance.limit,
    };

_$DocImpl _$$DocImplFromJson(Map<String, dynamic> json) => _$DocImpl(
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
      likesCount: (json['likesCount'] as num).toInt(),
    );

Map<String, dynamic> _$$DocImplToJson(_$DocImpl instance) => <String, dynamic>{
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
