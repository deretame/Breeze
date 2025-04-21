// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comic_all_info_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ComicAllInfoJson _$ComicAllInfoJsonFromJson(Map<String, dynamic> json) =>
    _ComicAllInfoJson(
      comic: Comic.fromJson(json['comic'] as Map<String, dynamic>),
      eps: Eps.fromJson(json['eps'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ComicAllInfoJsonToJson(_ComicAllInfoJson instance) =>
    <String, dynamic>{'comic': instance.comic, 'eps': instance.eps};

_Comic _$ComicFromJson(Map<String, dynamic> json) => _Comic(
  id: json['_id'] as String,
  creator: Creator.fromJson(json['_creator'] as Map<String, dynamic>),
  title: json['title'] as String,
  description: json['description'] as String,
  thumb: Thumb.fromJson(json['thumb'] as Map<String, dynamic>),
  author: json['author'] as String,
  chineseTeam: json['chineseTeam'] as String,
  categories:
      (json['categories'] as List<dynamic>).map((e) => e as String).toList(),
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

Map<String, dynamic> _$ComicToJson(_Comic instance) => <String, dynamic>{
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

_Creator _$CreatorFromJson(Map<String, dynamic> json) => _Creator(
  id: json['_id'] as String,
  gender: json['gender'] as String,
  name: json['name'] as String,
  verified: json['verified'] as bool,
  exp: (json['exp'] as num).toInt(),
  level: (json['level'] as num).toInt(),
  characters:
      (json['characters'] as List<dynamic>).map((e) => e as String).toList(),
  role: json['role'] as String,
  avatar: Thumb.fromJson(json['avatar'] as Map<String, dynamic>),
  title: json['title'] as String,
  slogan: json['slogan'] as String,
);

Map<String, dynamic> _$CreatorToJson(_Creator instance) => <String, dynamic>{
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

_Thumb _$ThumbFromJson(Map<String, dynamic> json) => _Thumb(
  originalName: json['originalName'] as String,
  path: json['path'] as String,
  fileServer: json['fileServer'] as String,
);

Map<String, dynamic> _$ThumbToJson(_Thumb instance) => <String, dynamic>{
  'originalName': instance.originalName,
  'path': instance.path,
  'fileServer': instance.fileServer,
};

_Eps _$EpsFromJson(Map<String, dynamic> json) => _Eps(
  docs:
      (json['docs'] as List<dynamic>)
          .map((e) => EpsDoc.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$EpsToJson(_Eps instance) => <String, dynamic>{
  'docs': instance.docs,
};

_EpsDoc _$EpsDocFromJson(Map<String, dynamic> json) => _EpsDoc(
  id: json['_id'] as String,
  title: json['title'] as String,
  order: (json['order'] as num).toInt(),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  docId: json['id'] as String,
  pages: Pages.fromJson(json['pages'] as Map<String, dynamic>),
);

Map<String, dynamic> _$EpsDocToJson(_EpsDoc instance) => <String, dynamic>{
  '_id': instance.id,
  'title': instance.title,
  'order': instance.order,
  'updated_at': instance.updatedAt.toIso8601String(),
  'id': instance.docId,
  'pages': instance.pages,
};

_Pages _$PagesFromJson(Map<String, dynamic> json) => _Pages(
  docs:
      (json['docs'] as List<dynamic>)
          .map((e) => PagesDoc.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$PagesToJson(_Pages instance) => <String, dynamic>{
  'docs': instance.docs,
};

_PagesDoc _$PagesDocFromJson(Map<String, dynamic> json) => _PagesDoc(
  id: json['_id'] as String,
  media: Thumb.fromJson(json['media'] as Map<String, dynamic>),
  docId: json['id'] as String,
);

Map<String, dynamic> _$PagesDocToJson(_PagesDoc instance) => <String, dynamic>{
  '_id': instance.id,
  'media': instance.media,
  'id': instance.docId,
};
