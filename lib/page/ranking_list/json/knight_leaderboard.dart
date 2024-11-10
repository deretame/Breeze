// To parse this JSON data, do
//
//     final knightLeaderboard = knightLeaderboardFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'knight_leaderboard.freezed.dart';
part 'knight_leaderboard.g.dart';

KnightLeaderboard knightLeaderboardFromJson(String str) =>
    KnightLeaderboard.fromJson(json.decode(str));

String knightLeaderboardToJson(KnightLeaderboard data) =>
    json.encode(data.toJson());

@freezed
class KnightLeaderboard with _$KnightLeaderboard {
  const factory KnightLeaderboard({
    @JsonKey(name: "code") required int code,
    @JsonKey(name: "message") required String message,
    @JsonKey(name: "data") required Data data,
  }) = _KnightLeaderboard;

  factory KnightLeaderboard.fromJson(Map<String, dynamic> json) =>
      _$KnightLeaderboardFromJson(json);
}

@freezed
class Data with _$Data {
  const factory Data({
    @JsonKey(name: "users") required List<User> users,
  }) = _Data;

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
}

@freezed
class User with _$User {
  const factory User({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "gender") required Gender gender,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "slogan") String? slogan,
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "verified") required bool verified,
    @JsonKey(name: "exp") required int exp,
    @JsonKey(name: "level") required int level,
    @JsonKey(name: "characters") required List<String> characters,
    @JsonKey(name: "role") required Role role,
    @JsonKey(name: "avatar") required Avatar avatar,
    @JsonKey(name: "comicsUploaded") required int comicsUploaded,
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
  @JsonValue("knight")
  KNIGHT
}

final roleValues = EnumValues({"knight": Role.KNIGHT});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
