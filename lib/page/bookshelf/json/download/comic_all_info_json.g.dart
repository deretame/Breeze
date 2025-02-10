// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comic_all_info_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ComicAllInfoJsonImpl _$$ComicAllInfoJsonImplFromJson(
        Map<String, dynamic> json) =>
    _$ComicAllInfoJsonImpl(
      comic: Comic.fromJson(json['comic'] as Map<String, dynamic>),
      eps: Eps.fromJson(json['eps'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ComicAllInfoJsonImplToJson(
        _$ComicAllInfoJsonImpl instance) =>
    <String, dynamic>{
      'comic': instance.comic,
      'eps': instance.eps,
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
      characters: (json['characters'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      role: json['role'] as String,
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
      'characters': instance.characters,
      'role': instance.role,
      'avatar': instance.avatar,
      'title': instance.title,
      'slogan': instance.slogan,
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

_$EpsImpl _$$EpsImplFromJson(Map<String, dynamic> json) => _$EpsImpl(
      docs: (json['docs'] as List<dynamic>)
          .map((e) => EpsDoc.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$EpsImplToJson(_$EpsImpl instance) => <String, dynamic>{
      'docs': instance.docs,
    };

_$EpsDocImpl _$$EpsDocImplFromJson(Map<String, dynamic> json) => _$EpsDocImpl(
      id: json['_id'] as String,
      title: json['title'] as String,
      order: (json['order'] as num).toInt(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      docId: json['id'] as String,
      pages: Pages.fromJson(json['pages'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$EpsDocImplToJson(_$EpsDocImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'title': instance.title,
      'order': instance.order,
      'updated_at': instance.updatedAt.toIso8601String(),
      'id': instance.docId,
      'pages': instance.pages,
    };

_$PagesImpl _$$PagesImplFromJson(Map<String, dynamic> json) => _$PagesImpl(
      docs: (json['docs'] as List<dynamic>)
          .map((e) => PagesDoc.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$PagesImplToJson(_$PagesImpl instance) =>
    <String, dynamic>{
      'docs': instance.docs,
    };

_$PagesDocImpl _$$PagesDocImplFromJson(Map<String, dynamic> json) =>
    _$PagesDocImpl(
      id: json['_id'] as String,
      media: Thumb.fromJson(json['media'] as Map<String, dynamic>),
      docId: json['id'] as String,
    );

Map<String, dynamic> _$$PagesDocImplToJson(_$PagesDocImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'media': instance.media,
      'id': instance.docId,
    };
