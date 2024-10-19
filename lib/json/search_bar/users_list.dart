// To parse this JSON data, do
//
//     final usersList = usersListFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'users_list.freezed.dart';
part 'users_list.g.dart';

UsersList usersListFromJson(String str) => UsersList.fromJson(json.decode(str));

String usersListToJson(UsersList data) => json.encode(data.toJson());

@freezed
class UsersList with _$UsersList {
  const factory UsersList({
    @JsonKey(name: "users") required List<User> users,
  }) = _UsersList;

  factory UsersList.fromJson(Map<String, dynamic> json) =>
      _$UsersListFromJson(json);
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
