// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comic_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ComicInfoImpl _$$ComicInfoImplFromJson(Map<String, dynamic> json) =>
    _$ComicInfoImpl(
      comic: Comic.fromJson(json['comic'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ComicInfoImplToJson(_$ComicInfoImpl instance) =>
    <String, dynamic>{
      'comic': instance.comic,
    };

_$ComicImpl _$$ComicImplFromJson(Map<String, dynamic> json) => _$ComicImpl(
      id: json['_id'] as String,
      creator: Creator.fromJson(json['_creator'] as Map<String, dynamic>),
      title: json['title'] as String,
      description: json['description'] as String,
      thumb: Thumb.fromJson(json['thumb'] as Map<String, dynamic>),
      author: json['author'] as String,
      chineseTeam: json['chineseTeam'] as String,
      categories: (json['categories'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      pagesCount: (json['pagesCount'] as num).toInt(),
      epsCount: (json['epsCount'] as num).toInt(),
      finished: json['finished'] as bool,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      allowDownload: json['allowDownload'] as bool,
      allowComment: json['allowComment'] as bool,
      totalLikes: (json['totalLikes'] as num).toInt(),
      totalViews: (json['totalViews'] as num).toInt(),
      totalComments: (json['totalComments'] as num).toInt(),
      viewsCount: (json['viewsCount'] as num).toInt(),
      likesCount: (json['likesCount'] as num).toInt(),
      commentsCount: (json['commentsCount'] as num).toInt(),
      isFavourite: json['isFavourite'] as bool,
      isLiked: json['isLiked'] as bool,
    );

Map<String, dynamic> _$$ComicImplToJson(_$ComicImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      '_creator': instance.creator,
      'title': instance.title,
      'description': instance.description,
      'thumb': instance.thumb,
      'author': instance.author,
      'chineseTeam': instance.chineseTeam,
      'categories': instance.categories,
      'tags': instance.tags,
      'pagesCount': instance.pagesCount,
      'epsCount': instance.epsCount,
      'finished': instance.finished,
      'updated_at': instance.updatedAt.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'allowDownload': instance.allowDownload,
      'allowComment': instance.allowComment,
      'totalLikes': instance.totalLikes,
      'totalViews': instance.totalViews,
      'totalComments': instance.totalComments,
      'viewsCount': instance.viewsCount,
      'likesCount': instance.likesCount,
      'commentsCount': instance.commentsCount,
      'isFavourite': instance.isFavourite,
      'isLiked': instance.isLiked,
    };

_$CreatorImpl _$$CreatorImplFromJson(Map<String, dynamic> json) =>
    _$CreatorImpl(
      id: json['_id'] as String,
      gender: json['gender'] as String,
      name: json['name'] as String,
      verified: json['verified'] as bool,
      exp: (json['exp'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      role: json['role'] as String,
      characters: (json['characters'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      avatar: Thumb.fromJson(json['avatar'] as Map<String, dynamic>),
      title: json['title'] as String,
      slogan: json['slogan'] as String,
    );

Map<String, dynamic> _$$CreatorImplToJson(_$CreatorImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'gender': instance.gender,
      'name': instance.name,
      'verified': instance.verified,
      'exp': instance.exp,
      'level': instance.level,
      'role': instance.role,
      'characters': instance.characters,
      'avatar': instance.avatar,
      'title': instance.title,
      'slogan': instance.slogan,
    };

_$ThumbImpl _$$ThumbImplFromJson(Map<String, dynamic> json) => _$ThumbImpl(
      fileServer: json['fileServer'] as String,
      path: json['path'] as String,
      originalName: json['originalName'] as String,
    );

Map<String, dynamic> _$$ThumbImplToJson(_$ThumbImpl instance) =>
    <String, dynamic>{
      'fileServer': instance.fileServer,
      'path': instance.path,
      'originalName': instance.originalName,
    };
