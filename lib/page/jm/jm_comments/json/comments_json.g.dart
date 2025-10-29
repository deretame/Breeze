// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comments_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CommentsJson _$CommentsJsonFromJson(Map<String, dynamic> json) =>
    _CommentsJson(
      list: (json['list'] as List<dynamic>)
          .map((e) => ListElement.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as String,
    );

Map<String, dynamic> _$CommentsJsonToJson(_CommentsJson instance) =>
    <String, dynamic>{'list': instance.list, 'total': instance.total};

_ListElement _$ListElementFromJson(Map<String, dynamic> json) => _ListElement(
  aid: json['AID'] as String,
  bid: json['BID'],
  cid: json['CID'] as String,
  uid: json['UID'] as String,
  username: json['username'] as String,
  nickname: json['nickname'] as String,
  likes: json['likes'] as String,
  gender: json['gender'] as String,
  updateAt: json['update_at'] as String,
  addtime: json['addtime'] as String,
  parentCid: json['parent_CID'] as String,
  expinfo: Expinfo.fromJson(json['expinfo'] as Map<String, dynamic>),
  name: json['name'] as String,
  content: json['content'] as String,
  photo: json['photo'] as String,
  spoiler: json['spoiler'] as String,
  replys: (json['replys'] as List<dynamic>?)
      ?.map((e) => Reply.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ListElementToJson(_ListElement instance) =>
    <String, dynamic>{
      'AID': instance.aid,
      'BID': instance.bid,
      'CID': instance.cid,
      'UID': instance.uid,
      'username': instance.username,
      'nickname': instance.nickname,
      'likes': instance.likes,
      'gender': instance.gender,
      'update_at': instance.updateAt,
      'addtime': instance.addtime,
      'parent_CID': instance.parentCid,
      'expinfo': instance.expinfo,
      'name': instance.name,
      'content': instance.content,
      'photo': instance.photo,
      'spoiler': instance.spoiler,
      'replys': instance.replys,
    };

_Expinfo _$ExpinfoFromJson(Map<String, dynamic> json) => _Expinfo(
  levelName: json['level_name'] as String,
  level: (json['level'] as num).toInt(),
  nextLevelExp: (json['nextLevelExp'] as num).toInt(),
  exp: json['exp'] as String,
  expPercent: (json['expPercent'] as num).toDouble(),
  uid: json['uid'] as String,
  badges: (json['badges'] as List<dynamic>)
      .map((e) => Badge.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ExpinfoToJson(_Expinfo instance) => <String, dynamic>{
  'level_name': instance.levelName,
  'level': instance.level,
  'nextLevelExp': instance.nextLevelExp,
  'exp': instance.exp,
  'expPercent': instance.expPercent,
  'uid': instance.uid,
  'badges': instance.badges,
};

_Badge _$BadgeFromJson(Map<String, dynamic> json) => _Badge(
  content: json['content'] as String,
  name: json['name'] as String,
  id: json['id'] as String,
);

Map<String, dynamic> _$BadgeToJson(_Badge instance) => <String, dynamic>{
  'content': instance.content,
  'name': instance.name,
  'id': instance.id,
};

_Reply _$ReplyFromJson(Map<String, dynamic> json) => _Reply(
  cid: json['CID'] as String,
  uid: json['UID'] as String,
  username: json['username'] as String,
  nickname: json['nickname'] as String,
  likes: json['likes'] as String,
  gender: json['gender'] as String,
  updateAt: json['update_at'] as String,
  addtime: json['addtime'] as String,
  parentCid: json['parent_CID'] as String,
  photo: json['photo'] as String,
  content: json['content'] as String,
  expinfo: Expinfo.fromJson(json['expinfo'] as Map<String, dynamic>),
  spoiler: json['spoiler'] as String,
);

Map<String, dynamic> _$ReplyToJson(_Reply instance) => <String, dynamic>{
  'CID': instance.cid,
  'UID': instance.uid,
  'username': instance.username,
  'nickname': instance.nickname,
  'likes': instance.likes,
  'gender': instance.gender,
  'update_at': instance.updateAt,
  'addtime': instance.addtime,
  'parent_CID': instance.parentCid,
  'photo': instance.photo,
  'content': instance.content,
  'expinfo': instance.expinfo,
  'spoiler': instance.spoiler,
};
