// To parse this JSON data, do
//
//     final profile = profileFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

Profile profileFromJson(String str) => Profile.fromJson(json.decode(str));

String profileToJson(Profile data) => json.encode(data.toJson());

@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    @JsonKey(name: "code") required int code,
    @JsonKey(name: "message") required String message,
    @JsonKey(name: "data") required Data data,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}

@freezed
abstract class Data with _$Data {
  const factory Data({@JsonKey(name: "user") required User user}) = _Data;

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
}

@freezed
abstract class User with _$User {
  const factory User({
    @JsonKey(name: "_id") required String id,
    @JsonKey(name: "birthday") required DateTime birthday,
    @JsonKey(name: "email") required String email,
    @JsonKey(name: "gender") required String gender,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "slogan") required String slogan,
    @JsonKey(name: "title") required String title,
    @JsonKey(name: "verified") required bool verified,
    @JsonKey(name: "exp") required int exp,
    @JsonKey(name: "level") required int level,
    @JsonKey(name: "characters") required List<String> characters,
    @JsonKey(name: "created_at") required DateTime createdAt,
    @JsonKey(name: "avatar") required Avatar avatar,
    @JsonKey(name: "isPunched") required bool isPunched,
    @JsonKey(name: "character") required String character,
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
