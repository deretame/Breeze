// To parse this JSON data, do
//
//     final jmUserInfoJson = jmUserInfoJsonFromJson(jsonString);

import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'jm_user_info_json.freezed.dart';
part 'jm_user_info_json.g.dart';

JmUserInfoJson jmUserInfoJsonFromJson(String str) =>
    JmUserInfoJson.fromJson(json.decode(str));

String jmUserInfoJsonToJson(JmUserInfoJson data) => json.encode(data.toJson());

@freezed
abstract class JmUserInfoJson with _$JmUserInfoJson {
  const factory JmUserInfoJson({
    @JsonKey(name: "uid") required String uid,
    @JsonKey(name: "username") required String username,
    @JsonKey(name: "email") required String email,
    @JsonKey(name: "emailverified") required String emailverified,
    @JsonKey(name: "photo") required String photo,
    @JsonKey(name: "fname") required String fname,
    @JsonKey(name: "gender") required String gender,
    @JsonKey(name: "message") required String message,
    @JsonKey(name: "coin") required dynamic coin,
    @JsonKey(name: "album_favorites") required int albumFavorites,
    @JsonKey(name: "s") required String s,
    @JsonKey(name: "level_name") required String levelName,
    @JsonKey(name: "level") required int level,
    @JsonKey(name: "nextLevelExp") required int nextLevelExp,
    @JsonKey(name: "exp") required String exp,
    @JsonKey(name: "expPercent") required double expPercent,
    @JsonKey(name: "badges") required List<dynamic> badges,
    @JsonKey(name: "album_favorites_max") required int albumFavoritesMax,
    @JsonKey(name: "ad_free") required bool adFree,
    @JsonKey(name: "ad_free_before") required String adFreeBefore,
    @JsonKey(name: "charge") required String charge,
    @JsonKey(name: "jar") required String jar,
    @JsonKey(name: "invitation_qrcode") required String invitationQrcode,
    @JsonKey(name: "invitation_url") required String invitationUrl,
    @JsonKey(name: "invited_cnt") required String invitedCnt,
  }) = _JmUserInfoJson;

  factory JmUserInfoJson.fromJson(Map<String, dynamic> json) =>
      _$JmUserInfoJsonFromJson(json);
}
