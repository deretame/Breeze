// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SearchCategoryImpl _$$SearchCategoryImplFromJson(Map<String, dynamic> json) =>
    _$SearchCategoryImpl(
      categories: (json['categories'] as List<dynamic>)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$SearchCategoryImplToJson(
        _$SearchCategoryImpl instance) =>
    <String, dynamic>{
      'categories': instance.categories,
    };

_$CategoryImpl _$$CategoryImplFromJson(Map<String, dynamic> json) =>
    _$CategoryImpl(
      title: json['title'] as String,
      thumb: Thumb.fromJson(json['thumb'] as Map<String, dynamic>),
      isWeb: json['isWeb'] as bool?,
      active: json['active'] as bool?,
      link: json['link'] as String?,
      id: json['_id'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$CategoryImplToJson(_$CategoryImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'thumb': instance.thumb,
      'isWeb': instance.isWeb,
      'active': instance.active,
      'link': instance.link,
      '_id': instance.id,
      'description': instance.description,
    };

_$ThumbImpl _$$ThumbImplFromJson(Map<String, dynamic> json) => _$ThumbImpl(
      originalName: json['originalName'] as String,
      path: json['path'] as String,
      fileServer: json['fileServer'] as String,
    );

Map<String, dynamic> _$$ThumbImplToJson(_$ThumbImpl instance) =>
    <String, dynamic>{
      'originalName': instance.originalName,
      'path': instance.path,
      'fileServer': instance.fileServer,
    };
