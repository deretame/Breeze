// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PersonInfoImpl _$$PersonInfoImplFromJson(Map<String, dynamic> json) =>
    _$PersonInfoImpl(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$PersonInfoImplToJson(_$PersonInfoImpl instance) =>
    <String, dynamic>{
      'user': instance.user,
    };

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
      id: json['_id'] as String,
      birthday: DateTime.parse(json['birthday'] as String),
      email: json['email'] as String,
      gender: json['gender'] as String,
      name: json['name'] as String,
      slogan: json['slogan'] as String,
      title: json['title'] as String,
      verified: json['verified'] as bool,
      exp: (json['exp'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      characters: json['characters'] as List<dynamic>,
      createdAt: DateTime.parse(json['created_at'] as String),
      avatar: Avatar.fromJson(json['avatar'] as Map<String, dynamic>),
      isPunched: json['isPunched'] as bool,
      character: json['character'] as String,
    );

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'birthday': instance.birthday.toIso8601String(),
      'email': instance.email,
      'gender': instance.gender,
      'name': instance.name,
      'slogan': instance.slogan,
      'title': instance.title,
      'verified': instance.verified,
      'exp': instance.exp,
      'level': instance.level,
      'characters': instance.characters,
      'created_at': instance.createdAt.toIso8601String(),
      'avatar': instance.avatar,
      'isPunched': instance.isPunched,
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
