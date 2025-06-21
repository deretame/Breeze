// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jm_suggestion_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JmSuggestionJson _$JmSuggestionJsonFromJson(Map<String, dynamic> json) =>
    _JmSuggestionJson(
      id: json['id'] as String,
      author: json['author'] as String,
      name: json['name'] as String,
      image: json['image'] as String,
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
      categorySub: CategorySub.fromJson(
        json['category_sub'] as Map<String, dynamic>,
      ),
      liked: json['liked'] as bool,
      isFavorite: json['is_favorite'] as bool,
      updateAt: (json['update_at'] as num).toInt(),
    );

Map<String, dynamic> _$JmSuggestionJsonToJson(_JmSuggestionJson instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author': instance.author,
      'name': instance.name,
      'image': instance.image,
      'category': instance.category,
      'category_sub': instance.categorySub,
      'liked': instance.liked,
      'is_favorite': instance.isFavorite,
      'update_at': instance.updateAt,
    };

_Category _$CategoryFromJson(Map<String, dynamic> json) =>
    _Category(id: json['id'] as String, title: json['title'] as String);

Map<String, dynamic> _$CategoryToJson(_Category instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
};

_CategorySub _$CategorySubFromJson(Map<String, dynamic> json) =>
    _CategorySub(id: json['id'] as String?, title: json['title'] as String?);

Map<String, dynamic> _$CategorySubToJson(_CategorySub instance) =>
    <String, dynamic>{'id': instance.id, 'title': instance.title};
