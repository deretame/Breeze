// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'knight_leaderboard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KnightLeaderboard _$KnightLeaderboardFromJson(Map<String, dynamic> json) =>
    _KnightLeaderboard(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String,
      data: Data.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$KnightLeaderboardToJson(_KnightLeaderboard instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
    };

_Data _$DataFromJson(Map<String, dynamic> json) => _Data(
  users:
      (json['users'] as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$DataToJson(_Data instance) => <String, dynamic>{
  'users': instance.users,
};

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: json['_id'] as String,
  gender: json['gender'] as String,
  name: json['name'] as String,
  slogan: json['slogan'] as String?,
  title: json['title'] as String,
  verified: json['verified'] as bool,
  exp: (json['exp'] as num).toInt(),
  level: (json['level'] as num).toInt(),
  characters:
      (json['characters'] as List<dynamic>).map((e) => e as String).toList(),
  role: json['role'] as String,
  avatar: Avatar.fromJson(json['avatar'] as Map<String, dynamic>),
  comicsUploaded: (json['comicsUploaded'] as num).toInt(),
  character: json['character'] as String?,
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  '_id': instance.id,
  'gender': instance.gender,
  'name': instance.name,
  'slogan': instance.slogan,
  'title': instance.title,
  'verified': instance.verified,
  'exp': instance.exp,
  'level': instance.level,
  'characters': instance.characters,
  'role': instance.role,
  'avatar': instance.avatar,
  'comicsUploaded': instance.comicsUploaded,
  'character': instance.character,
};

_Avatar _$AvatarFromJson(Map<String, dynamic> json) => _Avatar(
  originalName: json['originalName'] as String,
  path: json['path'] as String,
  fileServer: json['fileServer'] as String,
);

Map<String, dynamic> _$AvatarToJson(_Avatar instance) => <String, dynamic>{
  'originalName': instance.originalName,
  'path': instance.path,
  'fileServer': instance.fileServer,
};
