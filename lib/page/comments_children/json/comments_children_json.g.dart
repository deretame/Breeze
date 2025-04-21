// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comments_children_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CommentsChildrenJson _$CommentsChildrenJsonFromJson(
  Map<String, dynamic> json,
) => _CommentsChildrenJson(
  code: (json['code'] as num).toInt(),
  message: json['message'] as String,
  data: Data.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CommentsChildrenJsonToJson(
  _CommentsChildrenJson instance,
) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'data': instance.data,
};

_Data _$DataFromJson(Map<String, dynamic> json) => _Data(
  comments: Comments.fromJson(json['comments'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DataToJson(_Data instance) => <String, dynamic>{
  'comments': instance.comments,
};

_Comments _$CommentsFromJson(Map<String, dynamic> json) => _Comments(
  docs:
      (json['docs'] as List<dynamic>)
          .map((e) => Doc.fromJson(e as Map<String, dynamic>))
          .toList(),
  total: (json['total'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
  page: json['page'] as String,
  pages: (json['pages'] as num).toInt(),
);

Map<String, dynamic> _$CommentsToJson(_Comments instance) => <String, dynamic>{
  'docs': instance.docs,
  'total': instance.total,
  'limit': instance.limit,
  'page': instance.page,
  'pages': instance.pages,
};

_Doc _$DocFromJson(Map<String, dynamic> json) => _Doc(
  id: json['_id'] as String,
  content: json['content'] as String,
  user: User.fromJson(json['_user'] as Map<String, dynamic>),
  parent: json['_parent'] as String,
  comic: json['_comic'] as String,
  totalComments: (json['totalComments'] as num).toInt(),
  isTop: json['isTop'] as bool,
  hide: json['hide'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  docId: json['id'] as String,
  likesCount: (json['likesCount'] as num).toInt(),
  isLiked: json['isLiked'] as bool,
);

Map<String, dynamic> _$DocToJson(_Doc instance) => <String, dynamic>{
  '_id': instance.id,
  'content': instance.content,
  '_user': instance.user,
  '_parent': instance.parent,
  '_comic': instance.comic,
  'totalComments': instance.totalComments,
  'isTop': instance.isTop,
  'hide': instance.hide,
  'created_at': instance.createdAt.toIso8601String(),
  'id': instance.docId,
  'likesCount': instance.likesCount,
  'isLiked': instance.isLiked,
};

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: json['_id'] as String,
  gender: json['gender'] as String,
  name: json['name'] as String,
  title: json['title'] as String,
  verified: json['verified'] as bool,
  exp: (json['exp'] as num).toInt(),
  level: (json['level'] as num).toInt(),
  characters: json['characters'] as List<dynamic>,
  role: json['role'] as String,
  avatar:
      json['avatar'] == null
          ? null
          : Avatar.fromJson(json['avatar'] as Map<String, dynamic>),
  slogan: json['slogan'] as String?,
  character: json['character'] as String?,
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
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

_Avatar _$AvatarFromJson(Map<String, dynamic> json) => _Avatar(
  originalName: json['originalName'] as String,
  path: json['path'] as String,
  fileServer: json['fileServer'] as String,
);

Map<String, dynamic> _$AvatarToJson(_Avatar instance) => <String, dynamic>{
  'originalName': instance.originalName,
  'path': instance.path,
  'fileServer': instance.fileServer,
};
