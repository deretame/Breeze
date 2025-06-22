// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jm_user_info_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JmUserInfoJson _$JmUserInfoJsonFromJson(Map<String, dynamic> json) =>
    _JmUserInfoJson(
      uid: json['uid'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      emailverified: json['emailverified'] as String,
      photo: json['photo'] as String,
      fname: json['fname'] as String,
      gender: json['gender'] as String,
      message: json['message'] as String,
      coin: json['coin'],
      albumFavorites: (json['album_favorites'] as num).toInt(),
      s: json['s'] as String,
      levelName: json['level_name'] as String,
      level: (json['level'] as num).toInt(),
      nextLevelExp: (json['nextLevelExp'] as num).toInt(),
      exp: json['exp'] as String,
      expPercent: (json['expPercent'] as num).toDouble(),
      badges: json['badges'] as List<dynamic>,
      albumFavoritesMax: (json['album_favorites_max'] as num).toInt(),
      adFree: json['ad_free'] as bool,
      adFreeBefore: json['ad_free_before'] as String,
      charge: json['charge'] as String,
      jar: json['jar'] as String,
      invitationQrcode: json['invitation_qrcode'] as String,
      invitationUrl: json['invitation_url'] as String,
      invitedCnt: json['invited_cnt'] as String,
    );

Map<String, dynamic> _$JmUserInfoJsonToJson(_JmUserInfoJson instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'username': instance.username,
      'email': instance.email,
      'emailverified': instance.emailverified,
      'photo': instance.photo,
      'fname': instance.fname,
      'gender': instance.gender,
      'message': instance.message,
      'coin': instance.coin,
      'album_favorites': instance.albumFavorites,
      's': instance.s,
      'level_name': instance.levelName,
      'level': instance.level,
      'nextLevelExp': instance.nextLevelExp,
      'exp': instance.exp,
      'expPercent': instance.expPercent,
      'badges': instance.badges,
      'album_favorites_max': instance.albumFavoritesMax,
      'ad_free': instance.adFree,
      'ad_free_before': instance.adFreeBefore,
      'charge': instance.charge,
      'jar': instance.jar,
      'invitation_qrcode': instance.invitationQrcode,
      'invitation_url': instance.invitationUrl,
      'invited_cnt': instance.invitedCnt,
    };
