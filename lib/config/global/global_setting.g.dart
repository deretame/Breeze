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
      md5: json['md5'] as String? ?? '',
      autoSync: json['autoSync'] as bool? ?? true,
      syncNotify: json['syncNotify'] as bool? ?? true,
      shade: json['shade'] as bool? ?? true,
      comicReadTopContainer: json['comicReadTopContainer'] as bool? ?? true,
      readMode: (json['readMode'] as num?)?.toInt() ?? 0,
      maskedKeywords:
          (json['maskedKeywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      socks5Proxy: json['socks5Proxy'] as String? ?? '',
      needCleanCache: json['needCleanCache'] as bool? ?? false,
      comicChoice: (json['comicChoice'] as num?)?.toInt() ?? 1,
      disableBika: json['disableBika'] as bool? ?? false,
      enableMemoryDebug: json['enableMemoryDebug'] as bool? ?? false,
      searchHistory:
          (json['searchHistory'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      windowWidth: (json['windowWidth'] as num?)?.toDouble() ?? 1280.0,
      windowHeight: (json['windowHeight'] as num?)?.toDouble() ?? 720.0,
      windowX: (json['windowX'] as num?)?.toDouble() ?? 0,
      windowY: (json['windowY'] as num?)?.toDouble() ?? 0,
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
      'md5': instance.md5,
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
      'enableMemoryDebug': instance.enableMemoryDebug,
      'searchHistory': instance.searchHistory,
      'windowWidth': instance.windowWidth,
      'windowHeight': instance.windowHeight,
      'windowX': instance.windowX,
      'windowY': instance.windowY,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};
