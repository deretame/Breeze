// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ep.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EpImpl _$$EpImplFromJson(Map<String, dynamic> json) => _$EpImpl(
      pages: Pages.fromJson(json['pages'] as Map<String, dynamic>),
      ep: EpClass.fromJson(json['ep'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$EpImplToJson(_$EpImpl instance) => <String, dynamic>{
      'pages': instance.pages,
      'ep': instance.ep,
    };

_$EpClassImpl _$$EpClassImplFromJson(Map<String, dynamic> json) =>
    _$EpClassImpl(
      id: json['_id'] as String,
      title: json['title'] as String,
    );

Map<String, dynamic> _$$EpClassImplToJson(_$EpClassImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'title': instance.title,
    };

_$PagesImpl _$$PagesImplFromJson(Map<String, dynamic> json) => _$PagesImpl(
      docs: (json['docs'] as List<dynamic>)
          .map((e) => Doc.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pages: (json['pages'] as num).toInt(),
    );

Map<String, dynamic> _$$PagesImplToJson(_$PagesImpl instance) =>
    <String, dynamic>{
      'docs': instance.docs,
      'total': instance.total,
      'limit': instance.limit,
      'page': instance.page,
      'pages': instance.pages,
    };

_$DocImpl _$$DocImplFromJson(Map<String, dynamic> json) => _$DocImpl(
      id: json['_id'] as String,
      media: Media.fromJson(json['media'] as Map<String, dynamic>),
      docId: json['id'] as String,
    );

Map<String, dynamic> _$$DocImplToJson(_$DocImpl instance) => <String, dynamic>{
      '_id': instance.id,
      'media': instance.media,
      'id': instance.docId,
    };

_$MediaImpl _$$MediaImplFromJson(Map<String, dynamic> json) => _$MediaImpl(
      originalName: json['originalName'] as String,
      path: json['path'] as String,
      fileServer: json['fileServer'] as String,
    );

Map<String, dynamic> _$$MediaImplToJson(_$MediaImpl instance) =>
    <String, dynamic>{
      'originalName': instance.originalName,
      'path': instance.path,
      'fileServer': instance.fileServer,
    };
