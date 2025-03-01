// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comments_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommentsJsonImpl _$$CommentsJsonImplFromJson(Map<String, dynamic> json) =>
    _$CommentsJsonImpl(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String,
      data: Data.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$CommentsJsonImplToJson(_$CommentsJsonImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
    };

_$DataImpl _$$DataImplFromJson(Map<String, dynamic> json) => _$DataImpl(
      comments: Comments.fromJson(json['comments'] as Map<String, dynamic>),
      topComments: (json['topComments'] as List<dynamic>)
          .map((e) => TopComment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$DataImplToJson(_$DataImpl instance) =>
    <String, dynamic>{
      'comments': instance.comments,
      'topComments': instance.topComments,
    };

_$CommentsImpl _$$CommentsImplFromJson(Map<String, dynamic> json) =>
    _$CommentsImpl(
      docs: (json['docs'] as List<dynamic>)
          .map((e) => Doc.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      page: json['page'] as String,
      pages: (json['pages'] as num).toInt(),
    );

Map<String, dynamic> _$$CommentsImplToJson(_$CommentsImpl instance) =>
    <String, dynamic>{
      'docs': instance.docs,
      'total': instance.total,
      'limit': instance.limit,
      'page': instance.page,
      'pages': instance.pages,
    };

_$DocImpl _$$DocImplFromJson(Map<String, dynamic> json) => _$DocImpl(
      id: json['_id'] as String,
      content: json['content'] as String,
      user: User.fromJson(json['_user'] as Map<String, dynamic>),
      comic: json['_comic'] as String,
      totalComments: (json['totalComments'] as num).toInt(),
      isTop: json['isTop'] as bool,
      hide: json['hide'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      docId: json['id'] as String,
      likesCount: (json['likesCount'] as num).toInt(),
      commentsCount: (json['commentsCount'] as num).toInt(),
      isLiked: json['isLiked'] as bool,
    );

Map<String, dynamic> _$$DocImplToJson(_$DocImpl instance) => <String, dynamic>{
      '_id': instance.id,
      'content': instance.content,
      '_user': instance.user,
      '_comic': instance.comic,
      'totalComments': instance.totalComments,
      'isTop': instance.isTop,
      'hide': instance.hide,
      'created_at': instance.createdAt.toIso8601String(),
      'id': instance.docId,
      'likesCount': instance.likesCount,
      'commentsCount': instance.commentsCount,
      'isLiked': instance.isLiked,
    };

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
      id: json['_id'] as String,
      gender: json['gender'] as String,
      name: json['name'] as String,
      title: json['title'] as String,
      verified: json['verified'] as bool,
      exp: (json['exp'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      characters: (json['characters'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      role: json['role'] as String,
      avatar: json['avatar'] == null
          ? null
          : Avatar.fromJson(json['avatar'] as Map<String, dynamic>),
      slogan: json['slogan'] as String?,
      character: json['character'] as String?,
    );

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'gender': instance.gender,
      'name': instance.name,
      'title': instance.title,
      'verified': instance.verified,
      'exp': instance.exp,
      'level': instance.level,
      'characters': instance.characters,
      'role': instance.role,
      'avatar': instance.avatar,
      'slogan': instance.slogan,
      'character': instance.character,
    };

_$AvatarImpl _$$AvatarImplFromJson(Map<String, dynamic> json) => _$AvatarImpl(
      originalName: json['originalName'] as String,
      path: json['path'] as String,
      fileServer: json['fileServer'] as String,
    );

Map<String, dynamic> _$$AvatarImplToJson(_$AvatarImpl instance) =>
    <String, dynamic>{
      'originalName': instance.originalName,
      'path': instance.path,
      'fileServer': instance.fileServer,
    };

_$TopCommentImpl _$$TopCommentImplFromJson(Map<String, dynamic> json) =>
    _$TopCommentImpl(
      id: json['_id'] as String,
      content: json['content'] as String,
      user: User.fromJson(json['_user'] as Map<String, dynamic>),
      comic: json['_comic'] as String,
      isTop: json['isTop'] as bool,
      hide: json['hide'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      totalComments: (json['totalComments'] as num).toInt(),
      likesCount: (json['likesCount'] as num).toInt(),
      commentsCount: (json['commentsCount'] as num).toInt(),
      isLiked: json['isLiked'] as bool,
    );

Map<String, dynamic> _$$TopCommentImplToJson(_$TopCommentImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'content': instance.content,
      '_user': instance.user,
      '_comic': instance.comic,
      'isTop': instance.isTop,
      'hide': instance.hide,
      'created_at': instance.createdAt.toIso8601String(),
      'totalComments': instance.totalComments,
      'likesCount': instance.likesCount,
      'commentsCount': instance.commentsCount,
      'isLiked': instance.isLiked,
    };
