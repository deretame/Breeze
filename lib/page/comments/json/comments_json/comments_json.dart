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
class CommentsJson with _$CommentsJson {
  const factory CommentsJson({
    @JsonKey(name: "code") required int code,
    @JsonKey(name: "message") required String message,
    @JsonKey(name: "data") required Data data,
  }) = _CommentsJson;

  factory CommentsJson.fromJson(Map<String, dynamic> json) =>
      _$CommentsJsonFromJson(json);
}

@freezed
class Data with _$Data {
  const factory Data({
    @JsonKey(name: "comments") required Comments comments,
    @JsonKey(name: "topComments") required List<TopComment> topComments,
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
    @JsonKey(name: "_comic") required Comic comic,
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

enum Comic {
  @JsonValue("618234ab8a17d94ea7a0b3a0")
  THE_618234_AB8_A17_D94_EA7_A0_B3_A0
}

final comicValues = EnumValues(
    {"618234ab8a17d94ea7a0b3a0": Comic.THE_618234_AB8_A17_D94_EA7_A0_B3_A0});

@freezed
class User with _$User {
  const factory User({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "gender") required Gender gender,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "title") required Title title,
    @JsonKey(name: "verified") required bool verified,
    @JsonKey(name: "exp") required int exp,
    @JsonKey(name: "level") required int level,
    @JsonKey(name: "characters") required List<dynamic> characters,
    @JsonKey(name: "role") required Role role,
    @JsonKey(name: "avatar") Avatar? avatar,
    @JsonKey(name: "slogan") String? slogan,
    @JsonKey(name: "character") String? character,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class Avatar with _$Avatar {
  const factory Avatar({
    @JsonKey(name: "originalName") required OriginalName originalName,
    @JsonKey(name: "path") required String path,
    @JsonKey(name: "fileServer") required String fileServer,
  }) = _Avatar;

  factory Avatar.fromJson(Map<String, dynamic> json) => _$AvatarFromJson(json);
}

enum OriginalName {
  @JsonValue("avatar.jpg")
  AVATAR_JPG
}

final originalNameValues = EnumValues({"avatar.jpg": OriginalName.AVATAR_JPG});

enum Gender {
  @JsonValue("bot")
  BOT,
  @JsonValue("f")
  F,
  @JsonValue("m")
  M
}

final genderValues =
    EnumValues({"bot": Gender.BOT, "f": Gender.F, "m": Gender.M});

enum Role {
  @JsonValue("member")
  MEMBER
}

final roleValues = EnumValues({"member": Role.MEMBER});

enum Title {
  @JsonValue("萌新")
  EMPTY,
  @JsonValue("\ud83d\udc48变态出现")
  TITLE
}

final titleValues =
    EnumValues({"萌新": Title.EMPTY, "\ud83d\udc48变态出现": Title.TITLE});

@freezed
class TopComment with _$TopComment {
  const factory TopComment({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "content") required String content,
    @JsonKey(name: "_user") required User user,
    @JsonKey(name: "_comic") required Comic comic,
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

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
