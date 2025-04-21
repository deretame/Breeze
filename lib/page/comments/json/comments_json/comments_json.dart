// To parse this JSON data, do
//
//     final commentsJson = commentsJsonFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'comments_json.freezed.dart';
part 'comments_json.g.dart';

CommentsJson commentsJsonFromJson(String str) =>
    CommentsJson.fromJson(json.decode(str));

String commentsJsonToJson(CommentsJson data) => json.encode(data.toJson());

@freezed
abstract class CommentsJson with _$CommentsJson {
  const factory CommentsJson({
    @JsonKey(name: "code") required int code,
    @JsonKey(name: "message") required String message,
    @JsonKey(name: "data") required Data data,
  }) = _CommentsJson;

  factory CommentsJson.fromJson(Map<String, dynamic> json) =>
      _$CommentsJsonFromJson(json);
}

@freezed
abstract class Data with _$Data {
  const factory Data({
    @JsonKey(name: "comments") required Comments comments,
    @JsonKey(name: "topComments") required List<TopComment> topComments,
  }) = _Data;

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
}

@freezed
abstract class Comments with _$Comments {
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
abstract class Doc with _$Doc {
  const factory Doc({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "content") required String content,
    @JsonKey(name: "_user") required User user,
    @JsonKey(name: "_comic") required String comic,
    @JsonKey(name: "totalComments") required int totalComments,
    @JsonKey(name: "isTop") required bool isTop,
    @JsonKey(name: "hide") required bool hide,
    @JsonKey(name: "created_at") required DateTime createdAt,
    @JsonKey(name: "id") required String docId,
    @JsonKey(name: "likesCount") required int likesCount,
    @JsonKey(name: "commentsCount") required int commentsCount,
    @JsonKey(name: "isLiked") required bool isLiked,
  }) = _Doc;

  factory Doc.fromJson(Map<String, dynamic> json) => _$DocFromJson(json);
}

@freezed
abstract class User with _$User {
  const factory User({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "gender") required String gender,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "verified") required bool verified,
    @JsonKey(name: "exp") required int exp,
    @JsonKey(name: "level") required int level,
    @JsonKey(name: "characters") required List<String> characters,
    @JsonKey(name: "role") required String role,
    @JsonKey(name: "avatar") Avatar? avatar,
    @JsonKey(name: "slogan") String? slogan,
    @JsonKey(name: "character") String? character,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
abstract class Avatar with _$Avatar {
  const factory Avatar({
    @JsonKey(name: "originalName") required String originalName,
    @JsonKey(name: "path") required String path,
    @JsonKey(name: "fileServer") required String fileServer,
  }) = _Avatar;

  factory Avatar.fromJson(Map<String, dynamic> json) => _$AvatarFromJson(json);
}

@freezed
abstract class TopComment with _$TopComment {
  const factory TopComment({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "content") required String content,
    @JsonKey(name: "_user") required User user,
    @JsonKey(name: "_comic") required String comic,
    @JsonKey(name: "isTop") required bool isTop,
    @JsonKey(name: "hide") required bool hide,
    @JsonKey(name: "created_at") required DateTime createdAt,
    @JsonKey(name: "totalComments") required int totalComments,
    @JsonKey(name: "likesCount") required int likesCount,
    @JsonKey(name: "commentsCount") required int commentsCount,
    @JsonKey(name: "isLiked") required bool isLiked,
  }) = _TopComment;

  factory TopComment.fromJson(Map<String, dynamic> json) =>
      _$TopCommentFromJson(json);
}
