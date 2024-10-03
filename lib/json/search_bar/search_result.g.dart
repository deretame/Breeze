// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SearchResultImpl _$$SearchResultImplFromJson(Map<String, dynamic> json) =>
    _$SearchResultImpl(
      comics: Comics.fromJson(json['comics'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$SearchResultImplToJson(_$SearchResultImpl instance) =>
    <String, dynamic>{
      'comics': instance.comics,
    };

_$ComicsImpl _$$ComicsImplFromJson(Map<String, dynamic> json) => _$ComicsImpl(
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pages: (json['pages'] as num).toInt(),
      docs: (json['docs'] as List<dynamic>)
          .map((e) => Doc.fromJson(e as Map<String, dynamic>))
          .toList(),
      limit: (json['limit'] as num).toInt(),
    );

Map<String, dynamic> _$$ComicsImplToJson(_$ComicsImpl instance) =>
    <String, dynamic>{
      'total': instance.total,
      'page': instance.page,
      'pages': instance.pages,
      'docs': instance.docs,
      'limit': instance.limit,
    };

_$DocImpl _$$DocImplFromJson(Map<String, dynamic> json) => _$DocImpl(
      updatedAt: DateTime.parse(json['updated_at'] as String),
      thumb: Thumb.fromJson(json['thumb'] as Map<String, dynamic>),
      author: json['author'] as String,
      description: json['description'] as String,
      chineseTeam: json['chineseTeam'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      finished: json['finished'] as bool,
      categories: (json['categories'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      title: json['title'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      id: json['_id'] as String,
      likesCount: (json['likesCount'] as num).toInt(),
      totalViews: (json['totalViews'] as num?)?.toInt(),
      totalLikes: (json['totalLikes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$DocImplToJson(_$DocImpl instance) => <String, dynamic>{
      'updated_at': instance.updatedAt.toIso8601String(),
      'thumb': instance.thumb,
      'author': instance.author,
      'description': instance.description,
      'chineseTeam': instance.chineseTeam,
      'created_at': instance.createdAt.toIso8601String(),
      'finished': instance.finished,
      'categories': instance.categories,
      'title': instance.title,
      'tags': instance.tags,
      '_id': instance.id,
      'likesCount': instance.likesCount,
      'totalViews': instance.totalViews,
      'totalLikes': instance.totalLikes,
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
