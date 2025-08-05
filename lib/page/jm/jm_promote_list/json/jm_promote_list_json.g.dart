// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jm_promote_list_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JmPromoteListJson _$JmPromoteListJsonFromJson(Map<String, dynamic> json) =>
    _JmPromoteListJson(
      total: json['total'] as String,
      list:
          (json['list'] as List<dynamic>)
              .map((e) => ListElement.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$JmPromoteListJsonToJson(_JmPromoteListJson instance) =>
    <String, dynamic>{'total': instance.total, 'list': instance.list};

_ListElement _$ListElementFromJson(Map<String, dynamic> json) => _ListElement(
  id: json['id'] as String,
  author: json['author'] as String,
  name: json['name'] as String,
  category: Category.fromJson(json['category'] as Map<String, dynamic>),
  categorySub: CategorySub.fromJson(
    json['category_sub'] as Map<String, dynamic>,
  ),
  liked: json['liked'] as bool,
  isFavorite: json['is_favorite'] as bool,
  updateAt: (json['update_at'] as num).toInt(),
);

Map<String, dynamic> _$ListElementToJson(_ListElement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author': instance.author,
      'name': instance.name,
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
