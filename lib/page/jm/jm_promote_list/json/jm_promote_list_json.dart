// To parse this JSON data, do
//
//     final jmPromoteListJson = jmPromoteListJsonFromJson(jsonString);

import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'jm_promote_list_json.freezed.dart';
part 'jm_promote_list_json.g.dart';

JmPromoteListJson jmPromoteListJsonFromJson(String str) =>
    JmPromoteListJson.fromJson(json.decode(str));

String jmPromoteListJsonToJson(JmPromoteListJson data) =>
    json.encode(data.toJson());

@freezed
abstract class JmPromoteListJson with _$JmPromoteListJson {
  const factory JmPromoteListJson({
    @JsonKey(name: "total") required String total,
    @JsonKey(name: "list") required List<ListElement> list,
  }) = _JmPromoteListJson;

  factory JmPromoteListJson.fromJson(Map<String, dynamic> json) =>
      _$JmPromoteListJsonFromJson(json);
}

@freezed
abstract class ListElement with _$ListElement {
  const factory ListElement({
    @JsonKey(name: "id") required String id,
    @JsonKey(name: "author") required String author,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "image") required String image,
    @JsonKey(name: "category") required Category category,
    @JsonKey(name: "category_sub") required CategorySub categorySub,
    @JsonKey(name: "liked") required bool liked,
    @JsonKey(name: "is_favorite") required bool isFavorite,
    @JsonKey(name: "update_at") required int updateAt,
  }) = _ListElement;

  factory ListElement.fromJson(Map<String, dynamic> json) =>
      _$ListElementFromJson(json);
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
