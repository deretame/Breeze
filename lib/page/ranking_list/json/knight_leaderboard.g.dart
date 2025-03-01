// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'knight_leaderboard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$KnightLeaderboardImpl _$$KnightLeaderboardImplFromJson(
        Map<String, dynamic> json) =>
    _$KnightLeaderboardImpl(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String,
      data: Data.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$KnightLeaderboardImplToJson(
        _$KnightLeaderboardImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
    };

_$DataImpl _$$DataImplFromJson(Map<String, dynamic> json) => _$DataImpl(
      users: (json['users'] as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$DataImplToJson(_$DataImpl instance) =>
    <String, dynamic>{
      'users': instance.users,
    };

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
      id: json['_id'] as String,
      gender: json['gender'] as String,
      name: json['name'] as String,
      slogan: json['slogan'] as String?,
      title: json['title'] as String,
      verified: json['verified'] as bool,
      exp: (json['exp'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      characters: (json['characters'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      role: json['role'] as String,
      avatar: Avatar.fromJson(json['avatar'] as Map<String, dynamic>),
      comicsUploaded: (json['comicsUploaded'] as num).toInt(),
      character: json['character'] as String?,
    );

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
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

_$AvatarImpl _$$AvatarImplFromJson(Map<String, dynamic> json) => _$AvatarImpl(
      originalName: json['originalName'] as String,
      path: json['path'] as String,
      fileServer: json['fileServer'] as String,
    );

Map<String, dynamic> _$$AvatarImplToJson(_$AvatarImpl instance) =>
    <String, dynamic>{
      'originalName': instance.originalName,
      'path': instance.path,
      'fileServer': instance.fileServer,
    };
