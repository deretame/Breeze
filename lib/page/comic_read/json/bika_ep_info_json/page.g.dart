// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Page _$PageFromJson(Map<String, dynamic> json) => _Page(
  code: (json['code'] as num).toInt(),
  message: json['message'] as String,
  data: Data.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PageToJson(_Page instance) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'data': instance.data,
};

_Data _$DataFromJson(Map<String, dynamic> json) => _Data(
  pages: Pages.fromJson(json['pages'] as Map<String, dynamic>),
  ep: Ep.fromJson(json['ep'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DataToJson(_Data instance) => <String, dynamic>{
  'pages': instance.pages,
  'ep': instance.ep,
};

_Ep _$EpFromJson(Map<String, dynamic> json) =>
    _Ep(id: json['_id'] as String, title: json['title'] as String);

Map<String, dynamic> _$EpToJson(_Ep instance) => <String, dynamic>{
  '_id': instance.id,
  'title': instance.title,
};

_Pages _$PagesFromJson(Map<String, dynamic> json) => _Pages(
  docs:
      (json['docs'] as List<dynamic>)
          .map((e) => Doc.fromJson(e as Map<String, dynamic>))
          .toList(),
  total: (json['total'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  pages: (json['pages'] as num).toInt(),
);

Map<String, dynamic> _$PagesToJson(_Pages instance) => <String, dynamic>{
  'docs': instance.docs,
  'total': instance.total,
  'limit': instance.limit,
  'page': instance.page,
  'pages': instance.pages,
};

_Doc _$DocFromJson(Map<String, dynamic> json) => _Doc(
  id: json['_id'] as String,
  media: Media.fromJson(json['media'] as Map<String, dynamic>),
  docId: json['id'] as String,
);

Map<String, dynamic> _$DocToJson(_Doc instance) => <String, dynamic>{
  '_id': instance.id,
  'media': instance.media,
  'id': instance.docId,
};

_Media _$MediaFromJson(Map<String, dynamic> json) => _Media(
  originalName: json['originalName'] as String,
  path: json['path'] as String,
  fileServer: json['fileServer'] as String,
);

Map<String, dynamic> _$MediaToJson(_Media instance) => <String, dynamic>{
  'originalName': instance.originalName,
  'path': instance.path,
  'fileServer': instance.fileServer,
};
