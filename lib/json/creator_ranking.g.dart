// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creator_ranking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CreatorRankingImpl _$$CreatorRankingImplFromJson(Map<String, dynamic> json) =>
    _$CreatorRankingImpl(
      users: (json['users'] as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$CreatorRankingImplToJson(
        _$CreatorRankingImpl instance) =>
    <String, dynamic>{
      'users': instance.users,
    };

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
      id: json['_id'] as String,
      gender: $enumDecode(_$GenderEnumMap, json['gender']),
      name: json['name'] as String,
      slogan: json['slogan'] as String?,
      title: json['title'] as String,
      verified: json['verified'] as bool,
      exp: (json['exp'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      characters: (json['characters'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      role: $enumDecode(_$RoleEnumMap, json['role']),
      avatar: Avatar.fromJson(json['avatar'] as Map<String, dynamic>),
      comicsUploaded: (json['comicsUploaded'] as num).toInt(),
      character: json['character'] as String?,
    );

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'gender': _$GenderEnumMap[instance.gender]!,
      'name': instance.name,
      'slogan': instance.slogan,
      'title': instance.title,
      'verified': instance.verified,
      'exp': instance.exp,
      'level': instance.level,
      'characters': instance.characters,
      'role': _$RoleEnumMap[instance.role]!,
      'avatar': instance.avatar,
      'comicsUploaded': instance.comicsUploaded,
      'character': instance.character,
    };

const _$GenderEnumMap = {
  Gender.BOT: 'bot',
  Gender.F: 'f',
  Gender.M: 'm',
};

const _$RoleEnumMap = {
  Role.KNIGHT: 'knight',
};

_$AvatarImpl _$$AvatarImplFromJson(Map<String, dynamic> json) => _$AvatarImpl(
      originalName: $enumDecode(_$OriginalNameEnumMap, json['originalName']),
      path: json['path'] as String,
      fileServer: json['fileServer'] as String,
    );

Map<String, dynamic> _$$AvatarImplToJson(_$AvatarImpl instance) =>
    <String, dynamic>{
      'originalName': _$OriginalNameEnumMap[instance.originalName]!,
      'path': instance.path,
      'fileServer': instance.fileServer,
    };

const _$OriginalNameEnumMap = {
  OriginalName.AVATAR_JPG: 'avatar.jpg',
};
