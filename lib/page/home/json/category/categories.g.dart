// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categories.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Categories _$CategoriesFromJson(Map<String, dynamic> json) => _Categories(
  code: (json['code'] as num).toInt(),
  message: json['message'] as String,
  data: Data.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CategoriesToJson(_Categories instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
    };

_Data _$DataFromJson(Map<String, dynamic> json) => _Data(
  categories:
      (json['categories'] as List<dynamic>)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$DataToJson(_Data instance) => <String, dynamic>{
  'categories': instance.categories,
};

_Category _$CategoryFromJson(Map<String, dynamic> json) => _Category(
  title: json['title'] as String,
  thumb: Thumb.fromJson(json['thumb'] as Map<String, dynamic>),
  isWeb: json['isWeb'] as bool?,
  active: json['active'] as bool?,
  link: json['link'] as String?,
  id: json['_id'] as String?,
  description: json['description'] as String?,
);

Map<String, dynamic> _$CategoryToJson(_Category instance) => <String, dynamic>{
  'title': instance.title,
  'thumb': instance.thumb,
  'isWeb': instance.isWeb,
  'active': instance.active,
  'link': instance.link,
  '_id': instance.id,
  'description': instance.description,
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
