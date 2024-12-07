// To parse this JSON data, do
//
//     final commentsChildrenJson = commentsChildrenJsonFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'comments_children_json.freezed.dart';
part 'comments_children_json.g.dart';

CommentsChildrenJson commentsChildrenJsonFromJson(String str) =>
    CommentsChildrenJson.fromJson(json.decode(str));

String commentsChildrenJsonToJson(CommentsChildrenJson data) =>
    json.encode(data.toJson());

@freezed
class CommentsChildrenJson with _$CommentsChildrenJson {
  const factory CommentsChildrenJson({
    @JsonKey(name: "code") required int code,
    @JsonKey(name: "message") required String message,
    @JsonKey(name: "data") required Data data,
  }) = _CommentsChildrenJson;

  factory CommentsChildrenJson.fromJson(Map<String, dynamic> json) =>
      _$CommentsChildrenJsonFromJson(json);
}

@freezed
class Data with _$Data {
  const factory Data({
    @JsonKey(name: "comments") required Comments comments,
  }) = _Data;

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
}

@freezed
class Comments with _$Comments {
  const factory Comments({
    @JsonKey(name: "docs") required List<Doc> docs,
    @JsonKey(name: "total") required int total,
    @JsonKey(name: "limit") required int limit,
    @JsonKey(name: "page") required String page,
    @JsonKey(name: "pages") required int pages,
  }) = _Comments;

  factory Comments.fromJson(Map<String, dynamic> json) =>
      _$CommentsFromJson(json);
}

@freezed
class Doc with _$Doc {
  const factory Doc({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "content") required String content,
    @JsonKey(name: "_user") required User user,
    @JsonKey(name: "_parent") required String parent,
    @JsonKey(name: "_comic") required String comic,
    @JsonKey(name: "totalComments") required int totalComments,
    @JsonKey(name: "isTop") required bool isTop,
    @JsonKey(name: "hide") required bool hide,
    @JsonKey(name: "created_at") required DateTime createdAt,
    @JsonKey(name: "id") required String docId,
    @JsonKey(name: "likesCount") required int likesCount,
    @JsonKey(name: "isLiked") required bool isLiked,
  }) = _Doc;

  factory Doc.fromJson(Map<String, dynamic> json) => _$DocFromJson(json);
}

@freezed
class User with _$User {
  const factory User({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "gender") required String gender,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "verified") required bool verified,
    @JsonKey(name: "exp") required int exp,
    @JsonKey(name: "level") required int level,
    @JsonKey(name: "characters") required List<dynamic> characters,
    @JsonKey(name: "role") required String role,
    @JsonKey(name: "avatar") Avatar? avatar,
    @JsonKey(name: "slogan") String? slogan,
    @JsonKey(name: "character") String? character,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class Avatar with _$Avatar {
  const factory Avatar({
    @JsonKey(name: "originalName") required String originalName,
    @JsonKey(name: "path") required String path,
    @JsonKey(name: "fileServer") required String fileServer,
  }) = _Avatar;

  factory Avatar.fromJson(Map<String, dynamic> json) => _$AvatarFromJson(json);
}
