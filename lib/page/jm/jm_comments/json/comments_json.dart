// To parse this JSON data, do
//
//     final commentsJson = commentsJsonFromJson(jsonString);

import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'comments_json.freezed.dart';
part 'comments_json.g.dart';

CommentsJson commentsJsonFromJson(String str) =>
    CommentsJson.fromJson(json.decode(str));

String commentsJsonToJson(CommentsJson data) => json.encode(data.toJson());

@freezed
abstract class CommentsJson with _$CommentsJson {
  const factory CommentsJson({
    @JsonKey(name: "list") required List<ListElement> list,
    @JsonKey(name: "total") required String total,
  }) = _CommentsJson;

  factory CommentsJson.fromJson(Map<String, dynamic> json) =>
      _$CommentsJsonFromJson(json);
}

@freezed
abstract class ListElement with _$ListElement {
  const factory ListElement({
    @JsonKey(name: "AID") required String aid,
    @JsonKey(name: "BID") required dynamic bid,
    @JsonKey(name: "CID") required String cid,
    @JsonKey(name: "UID") required String uid,
    @JsonKey(name: "username") required String username,
    @JsonKey(name: "nickname") required String nickname,
    @JsonKey(name: "likes") required String likes,
    @JsonKey(name: "gender") required String gender,
    @JsonKey(name: "update_at") required String updateAt,
    @JsonKey(name: "addtime") required String addtime,
    @JsonKey(name: "parent_CID") required String parentCid,
    @JsonKey(name: "expinfo") required Expinfo expinfo,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "content") required String content,
    @JsonKey(name: "photo") required String photo,
    @JsonKey(name: "spoiler") required String spoiler,
    @JsonKey(name: "replys") List<Reply>? replys,
  }) = _ListElement;

  factory ListElement.fromJson(Map<String, dynamic> json) =>
      _$ListElementFromJson(json);
}

@freezed
abstract class Expinfo with _$Expinfo {
  const factory Expinfo({
    @JsonKey(name: "level_name") required String levelName,
    @JsonKey(name: "level") required int level,
    @JsonKey(name: "nextLevelExp") required int nextLevelExp,
    @JsonKey(name: "exp") required String exp,
    @JsonKey(name: "expPercent") required double expPercent,
    @JsonKey(name: "uid") required String uid,
    @JsonKey(name: "badges") required List<Badge> badges,
  }) = _Expinfo;

  factory Expinfo.fromJson(Map<String, dynamic> json) =>
      _$ExpinfoFromJson(json);
}

@freezed
abstract class Badge with _$Badge {
  const factory Badge({
    @JsonKey(name: "content") required String content,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "id") required String id,
  }) = _Badge;

  factory Badge.fromJson(Map<String, dynamic> json) => _$BadgeFromJson(json);
}

@freezed
abstract class Reply with _$Reply {
  const factory Reply({
    @JsonKey(name: "CID") required String cid,
    @JsonKey(name: "UID") required String uid,
    @JsonKey(name: "username") required String username,
    @JsonKey(name: "nickname") required String nickname,
    @JsonKey(name: "likes") required String likes,
    @JsonKey(name: "gender") required String gender,
    @JsonKey(name: "update_at") required String updateAt,
    @JsonKey(name: "addtime") required String addtime,
    @JsonKey(name: "parent_CID") required String parentCid,
    @JsonKey(name: "photo") required String photo,
    @JsonKey(name: "content") required String content,
    @JsonKey(name: "expinfo") required Expinfo expinfo,
    @JsonKey(name: "spoiler") required String spoiler,
  }) = _Reply;

  factory Reply.fromJson(Map<String, dynamic> json) => _$ReplyFromJson(json);
}
