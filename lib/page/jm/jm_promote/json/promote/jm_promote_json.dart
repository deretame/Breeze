// To parse this JSON data, do
//
//     final jmPromoteJson = jmPromoteJsonFromJson(jsonString);

import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'jm_promote_json.freezed.dart';
part 'jm_promote_json.g.dart';

List<JmPromoteJson> jmPromoteJsonFromJson(String str) =>
    List<JmPromoteJson>.from(
      json.decode(str).map((x) => JmPromoteJson.fromJson(x)),
    );

String jmPromoteJsonToJson(List<JmPromoteJson> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

@freezed
abstract class JmPromoteJson with _$JmPromoteJson {
  const factory JmPromoteJson({
    @JsonKey(name: "id") required dynamic id,
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "slug") required String slug,
    @JsonKey(name: "type") required String type,
    @JsonKey(name: "filter_val") required dynamic filterVal,
    @JsonKey(name: "content") required List<Content> content,
  }) = _JmPromoteJson;

  factory JmPromoteJson.fromJson(Map<String, dynamic> json) =>
      _$JmPromoteJsonFromJson(json);
}

@freezed
abstract class Content with _$Content {
  const factory Content({
    @JsonKey(name: "id") required String id,
    @JsonKey(name: "author") required String author,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "image") required String image,
    @JsonKey(name: "category") Category? category,
    @JsonKey(name: "category_sub") CategorySub? categorySub,
    @JsonKey(name: "liked") bool? liked,
    @JsonKey(name: "is_favorite") bool? isFavorite,
    @JsonKey(name: "update_at") required int updateAt,
  }) = _Content;

  factory Content.fromJson(Map<String, dynamic> json) =>
      _$ContentFromJson(json);
}

@freezed
abstract class Category with _$Category {
  const factory Category({
    @JsonKey(name: "id") required String id,
    @JsonKey(name: "title") required String title,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}

@freezed
abstract class CategorySub with _$CategorySub {
  const factory CategorySub({
    @JsonKey(name: "id") required String? id,
    @JsonKey(name: "title") required String? title,
  }) = _CategorySub;

  factory CategorySub.fromJson(Map<String, dynamic> json) =>
      _$CategorySubFromJson(json);
}
