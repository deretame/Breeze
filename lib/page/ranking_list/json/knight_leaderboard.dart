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
    @JsonKey(name: "gender") required String gender,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "slogan") String? slogan,
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "verified") required bool verified,
    @JsonKey(name: "exp") required int exp,
    @JsonKey(name: "level") required int level,
    @JsonKey(name: "characters") required List<String> characters,
    @JsonKey(name: "role") required String role,
    @JsonKey(name: "avatar") required Avatar avatar,
    @JsonKey(name: "comicsUploaded") required int comicsUploaded,
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
