// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keywords_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KeywordsJson _$KeywordsJsonFromJson(Map<String, dynamic> json) =>
    _KeywordsJson(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String,
      data: Data.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$KeywordsJsonToJson(_KeywordsJson instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
    };

_Data _$DataFromJson(Map<String, dynamic> json) => _Data(
  keywords: (json['keywords'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$DataToJson(_Data instance) => <String, dynamic>{
  'keywords': instance.keywords,
};
