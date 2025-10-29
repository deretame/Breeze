// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bika_setting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BikaSettingState _$BikaSettingStateFromJson(Map<String, dynamic> json) =>
    _BikaSettingState(
      account: json['account'] as String? ?? '',
      password: json['password'] as String? ?? '',
      authorization: json['authorization'] as String? ?? '',
      level: (json['level'] as num?)?.toInt() ?? 0,
      checkIn: json['checkIn'] as bool? ?? false,
      proxy: (json['proxy'] as num?)?.toInt() ?? 3,
      imageQuality: json['imageQuality'] as String? ?? 'original',
      shieldCategoryMap:
          (json['shieldCategoryMap'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as bool),
          ) ??
          const <String, bool>{},
      shieldHomePageCategoriesMap:
          (json['shieldHomePageCategoriesMap'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as bool),
          ) ??
          const <String, bool>{},
      signIn: json['signIn'] as bool? ?? false,
      brevity: json['brevity'] as bool? ?? false,
      slowDownload: json['slowDownload'] as bool? ?? false,
    );

Map<String, dynamic> _$BikaSettingStateToJson(_BikaSettingState instance) =>
    <String, dynamic>{
      'account': instance.account,
      'password': instance.password,
      'authorization': instance.authorization,
      'level': instance.level,
      'checkIn': instance.checkIn,
      'proxy': instance.proxy,
      'imageQuality': instance.imageQuality,
      'shieldCategoryMap': instance.shieldCategoryMap,
      'shieldHomePageCategoriesMap': instance.shieldHomePageCategoriesMap,
      'signIn': instance.signIn,
      'brevity': instance.brevity,
      'slowDownload': instance.slowDownload,
    };
