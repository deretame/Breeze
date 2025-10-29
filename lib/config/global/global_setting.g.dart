// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_setting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GlobalSettingState _$GlobalSettingStateFromJson(Map<String, dynamic> json) =>
    _GlobalSettingState(
      dynamicColor: json['dynamicColor'] as bool? ?? true,
      themeMode:
          $enumDecodeNullable(_$ThemeModeEnumMap, json['themeMode']) ??
          ThemeMode.system,
      isAMOLED: json['isAMOLED'] as bool? ?? true,
      seedColor: json['seedColor'] == null
          ? const Color(0xFFEF5350)
          : const ColorConverter().fromJson((json['seedColor'] as num).toInt()),
      themeInitState: (json['themeInitState'] as num?)?.toInt() ?? 0,
      locale: json['locale'] == null
          ? const Locale('zh', 'CN')
          : const LocaleConverter().fromJson(json['locale'] as String),
      welcomePageNum: (json['welcomePageNum'] as num?)?.toInt() ?? 0,
      webdavHost: json['webdavHost'] as String? ?? '',
      webdavUsername: json['webdavUsername'] as String? ?? '',
      webdavPassword: json['webdavPassword'] as String? ?? '',
      autoSync: json['autoSync'] as bool? ?? true,
      syncNotify: json['syncNotify'] as bool? ?? true,
      shade: json['shade'] as bool? ?? true,
      comicReadTopContainer: json['comicReadTopContainer'] as bool? ?? true,
      readMode: (json['readMode'] as num?)?.toInt() ?? 0,
      maskedKeywords:
          (json['maskedKeywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [""],
      socks5Proxy: json['socks5Proxy'] as String? ?? '',
      needCleanCache: json['needCleanCache'] as bool? ?? false,
      comicChoice: (json['comicChoice'] as num?)?.toInt() ?? 1,
      disableBika: json['disableBika'] as bool? ?? false,
    );

Map<String, dynamic> _$GlobalSettingStateToJson(_GlobalSettingState instance) =>
    <String, dynamic>{
      'dynamicColor': instance.dynamicColor,
      'themeMode': _$ThemeModeEnumMap[instance.themeMode]!,
      'isAMOLED': instance.isAMOLED,
      'seedColor': const ColorConverter().toJson(instance.seedColor),
      'themeInitState': instance.themeInitState,
      'locale': const LocaleConverter().toJson(instance.locale),
      'welcomePageNum': instance.welcomePageNum,
      'webdavHost': instance.webdavHost,
      'webdavUsername': instance.webdavUsername,
      'webdavPassword': instance.webdavPassword,
      'autoSync': instance.autoSync,
      'syncNotify': instance.syncNotify,
      'shade': instance.shade,
      'comicReadTopContainer': instance.comicReadTopContainer,
      'readMode': instance.readMode,
      'maskedKeywords': instance.maskedKeywords,
      'socks5Proxy': instance.socks5Proxy,
      'needCleanCache': instance.needCleanCache,
      'comicChoice': instance.comicChoice,
      'disableBika': instance.disableBika,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};
