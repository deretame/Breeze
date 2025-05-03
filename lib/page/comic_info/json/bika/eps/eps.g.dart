// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eps.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Eps _$EpsFromJson(Map<String, dynamic> json) => _Eps(
  code: (json['code'] as num).toInt(),
  message: json['message'] as String,
  data: Data.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$EpsToJson(_Eps instance) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'data': instance.data,
};

_Data _$DataFromJson(Map<String, dynamic> json) =>
    _Data(eps: EpsClass.fromJson(json['eps'] as Map<String, dynamic>));

Map<String, dynamic> _$DataToJson(_Data instance) => <String, dynamic>{
  'eps': instance.eps,
};

_EpsClass _$EpsClassFromJson(Map<String, dynamic> json) => _EpsClass(
  docs:
      (json['docs'] as List<dynamic>)
          .map((e) => Doc.fromJson(e as Map<String, dynamic>))
          .toList(),
  total: (json['total'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  pages: (json['pages'] as num).toInt(),
);

Map<String, dynamic> _$EpsClassToJson(_EpsClass instance) => <String, dynamic>{
  'docs': instance.docs,
  'total': instance.total,
  'limit': instance.limit,
  'page': instance.page,
  'pages': instance.pages,
};

_Doc _$DocFromJson(Map<String, dynamic> json) => _Doc(
  id: json['_id'] as String,
  title: json['title'] as String,
  order: (json['order'] as num).toInt(),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  docId: json['id'] as String,
);

Map<String, dynamic> _$DocToJson(_Doc instance) => <String, dynamic>{
  '_id': instance.id,
  'title': instance.title,
  'order': instance.order,
  'updated_at': instance.updatedAt.toIso8601String(),
  'id': instance.docId,
};
