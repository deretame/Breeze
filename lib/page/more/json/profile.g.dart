// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Profile _$ProfileFromJson(Map<String, dynamic> json) => _Profile(
  code: (json['code'] as num).toInt(),
  message: json['message'] as String,
  data: Data.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ProfileToJson(_Profile instance) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'data': instance.data,
};

_Data _$DataFromJson(Map<String, dynamic> json) =>
    _Data(user: User.fromJson(json['user'] as Map<String, dynamic>));

Map<String, dynamic> _$DataToJson(_Data instance) => <String, dynamic>{
  'user': instance.user,
};

_User _$UserFromJson(Map<String, dynamic> json) => _User(
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
  characters:
      (json['characters'] as List<dynamic>).map((e) => e as String).toList(),
  createdAt: DateTime.parse(json['created_at'] as String),
  avatar: Avatar.fromJson(json['avatar'] as Map<String, dynamic>),
  isPunched: json['isPunched'] as bool,
  character: json['character'] as String,
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
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
