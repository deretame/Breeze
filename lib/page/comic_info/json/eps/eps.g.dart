// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eps.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EpsImpl _$$EpsImplFromJson(Map<String, dynamic> json) => _$EpsImpl(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String,
      data: Data.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$EpsImplToJson(_$EpsImpl instance) => <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
    };

_$DataImpl _$$DataImplFromJson(Map<String, dynamic> json) => _$DataImpl(
      eps: EpsClass.fromJson(json['eps'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$DataImplToJson(_$DataImpl instance) =>
    <String, dynamic>{
      'eps': instance.eps,
    };

_$EpsClassImpl _$$EpsClassImplFromJson(Map<String, dynamic> json) =>
    _$EpsClassImpl(
      docs: (json['docs'] as List<dynamic>)
          .map((e) => Doc.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pages: (json['pages'] as num).toInt(),
    );

Map<String, dynamic> _$$EpsClassImplToJson(_$EpsClassImpl instance) =>
    <String, dynamic>{
      'docs': instance.docs,
      'total': instance.total,
      'limit': instance.limit,
      'page': instance.page,
      'pages': instance.pages,
    };

_$DocImpl _$$DocImplFromJson(Map<String, dynamic> json) => _$DocImpl(
      id: json['_id'] as String,
      title: json['title'] as String,
      order: (json['order'] as num).toInt(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      docId: json['id'] as String,
    );

Map<String, dynamic> _$$DocImplToJson(_$DocImpl instance) => <String, dynamic>{
      '_id': instance.id,
      'title': instance.title,
      'order': instance.order,
      'updated_at': instance.updatedAt.toIso8601String(),
      'id': instance.docId,
    };
