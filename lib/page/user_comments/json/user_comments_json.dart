// To parse this JSON data, do
//
//     final userCommentsJson = userCommentsJsonFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_comments_json.freezed.dart';
part 'user_comments_json.g.dart';

UserCommentsJson userCommentsJsonFromJson(String str) =>
    UserCommentsJson.fromJson(json.decode(str));

String userCommentsJsonToJson(UserCommentsJson data) =>
    json.encode(data.toJson());

@freezed
class UserCommentsJson with _$UserCommentsJson {
  const factory UserCommentsJson({
    @JsonKey(name: "code") required int code,
    @JsonKey(name: "message") required String message,
    @JsonKey(name: "data") required Data data,
  }) = _UserCommentsJson;

  factory UserCommentsJson.fromJson(Map<String, dynamic> json) =>
      _$UserCommentsJsonFromJson(json);
}

@freezed
class Data with _$Data {
  const factory Data({@JsonKey(name: "comments") required Comments comments}) =
      _Data;

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
    @JsonKey(name: "_comic") required Comic comic,
    @JsonKey(name: "totalComments") required int totalComments,
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
class Comic with _$Comic {
  const factory Comic({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "title") required String title,
  }) = _Comic;

  factory Comic.fromJson(Map<String, dynamic> json) => _$ComicFromJson(json);
}
