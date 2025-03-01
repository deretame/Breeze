// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keywords_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$KeywordsJsonImpl _$$KeywordsJsonImplFromJson(Map<String, dynamic> json) =>
    _$KeywordsJsonImpl(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String,
      data: Data.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$KeywordsJsonImplToJson(_$KeywordsJsonImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
    };

_$DataImpl _$$DataImplFromJson(Map<String, dynamic> json) => _$DataImpl(
      keywords:
          (json['keywords'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$DataImplToJson(_$DataImpl instance) =>
    <String, dynamic>{
      'keywords': instance.keywords,
    };
