// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jm_week_ranking_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JmWeekRankingJson _$JmWeekRankingJsonFromJson(Map<String, dynamic> json) =>
    _JmWeekRankingJson(
      list:
          (json['list'] as List<dynamic>)
              .map((e) => ListElement.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$JmWeekRankingJsonToJson(_JmWeekRankingJson instance) =>
    <String, dynamic>{'list': instance.list};

_ListElement _$ListElementFromJson(Map<String, dynamic> json) => _ListElement(
  id: json['id'] as String,
  author: json['author'] as String,
  description: json['description'],
  name: json['name'] as String,
  image: json['image'] as String,
  category: Category.fromJson(json['category'] as Map<String, dynamic>),
  categorySub: CategorySub.fromJson(
    json['category_sub'] as Map<String, dynamic>,
  ),
  liked: json['liked'] as bool,
  favorite: json['favorite'] as bool,
  updateAt: json['update_at'] as String,
);

Map<String, dynamic> _$ListElementToJson(_ListElement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author': instance.author,
      'description': instance.description,
      'name': instance.name,
      'image': instance.image,
      'category': instance.category,
      'category_sub': instance.categorySub,
      'liked': instance.liked,
      'favorite': instance.favorite,
      'update_at': instance.updateAt,
    };

_Category _$CategoryFromJson(Map<String, dynamic> json) =>
    _Category(id: json['id'] as String, title: json['title'] as String);

Map<String, dynamic> _$CategoryToJson(_Category instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
};

_CategorySub _$CategorySubFromJson(Map<String, dynamic> json) =>
    _CategorySub(id: json['id'] as String, title: json['title'] as String?);

Map<String, dynamic> _$CategorySubToJson(_CategorySub instance) =>
    <String, dynamic>{'id': instance.id, 'title': instance.title};
