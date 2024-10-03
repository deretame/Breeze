// To parse this JSON data, do
//
//     final personInfo = personInfoFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'person_info.freezed.dart';
part 'person_info.g.dart';

PersonInfo personInfoFromJson(String str) =>
    PersonInfo.fromJson(json.decode(str));

String personInfoToJson(PersonInfo data) => json.encode(data.toJson());

@freezed
class PersonInfo with _$PersonInfo {
  const factory PersonInfo({
    @JsonKey(name: "user") required User user,
  }) = _PersonInfo;

  factory PersonInfo.fromJson(Map<String, dynamic> json) =>
      _$PersonInfoFromJson(json);
}

@freezed
class User with _$User {
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
    @JsonKey(name: "characters") required List<dynamic> characters,
    @JsonKey(name: "created_at") required DateTime createdAt,
    @JsonKey(name: "avatar") required Avatar avatar,
    @JsonKey(name: "isPunched") required bool isPunched,
    @JsonKey(name: "character") required String character,
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
