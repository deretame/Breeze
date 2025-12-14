// To parse this JSON data, do
//
//     final jmCloudFavoriteJson = jmCloudFavoriteJsonFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'jm_cloud_favorite_json.freezed.dart';
part 'jm_cloud_favorite_json.g.dart';

JmCloudFavoriteJson jmCloudFavoriteJsonFromJson(String str) =>
    JmCloudFavoriteJson.fromJson(json.decode(str));

String jmCloudFavoriteJsonToJson(JmCloudFavoriteJson data) =>
    json.encode(data.toJson());

@freezed
abstract class JmCloudFavoriteJson with _$JmCloudFavoriteJson {
  const factory JmCloudFavoriteJson({
    @JsonKey(name: "list") required List<ListElement> list,
    @JsonKey(name: "folder_list") required List<FolderList> folderList,
    @JsonKey(name: "total") required String total,
    @JsonKey(name: "count") required int count,
  }) = _JmCloudFavoriteJson;

  factory JmCloudFavoriteJson.fromJson(Map<String, dynamic> json) =>
      _$JmCloudFavoriteJsonFromJson(json);
}

@freezed
abstract class FolderList with _$FolderList {
  const factory FolderList({
    @JsonKey(name: "FID") required String fid,
    @JsonKey(name: "UID") required String uid,
    @JsonKey(name: "name") required String name,
  }) = _FolderList;

  factory FolderList.fromJson(Map<String, dynamic> json) =>
      _$FolderListFromJson(json);
}

@freezed
abstract class ListElement with _$ListElement {
  const factory ListElement({
    @JsonKey(name: "id") required String id,
    @JsonKey(name: "author") required String author,
    @JsonKey(name: "description") required String description,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "latest_ep") required String? latestEp,
    @JsonKey(name: "latest_ep_aid") required String? latestEpAid,
    @JsonKey(name: "image") required String image,
    @JsonKey(name: "category") required Category category,
    @JsonKey(name: "category_sub") required CategorySub categorySub,
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
