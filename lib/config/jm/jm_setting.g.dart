// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jm_setting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JmSettingState _$JmSettingStateFromJson(Map<String, dynamic> json) =>
    _JmSettingState(
      account: json['account'] as String? ?? '',
      password: json['password'] as String? ?? '',
      userInfo: json['userInfo'] as String? ?? '',
      loginStatus:
          $enumDecodeNullable(_$LoginStatusEnumMap, json['loginStatus']) ??
          LoginStatus.logout,
      favoriteSet: (json['favoriteSet'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$JmSettingStateToJson(_JmSettingState instance) =>
    <String, dynamic>{
      'account': instance.account,
      'password': instance.password,
      'userInfo': instance.userInfo,
      'loginStatus': _$LoginStatusEnumMap[instance.loginStatus]!,
      'favoriteSet': instance.favoriteSet,
    };

const _$LoginStatusEnumMap = {
  LoginStatus.login: 'login',
  LoginStatus.loggingIn: 'loggingIn',
  LoginStatus.logout: 'logout',
};
