// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_setting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GlobalSettingState _$GlobalSettingStateFromJson(
  Map<String, dynamic> json,
) => _GlobalSettingState(
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
  syncSetting: json['syncSetting'] == null
      ? const SyncSettingState()
      : SyncSettingState.fromJson(json['syncSetting'] as Map<String, dynamic>),
  md5: json['md5'] as String? ?? '',
  autoSync: json['autoSync'] as bool? ?? true,
  syncNotify: json['syncNotify'] as bool? ?? true,
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
  forceEnableImpeller: json['forceEnableImpeller'] as bool? ?? false,
  updateAccelerate: json['updateAccelerate'] as bool? ?? true,
  searchHistory:
      (json['searchHistory'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  windowWidth: (json['windowWidth'] as num?)?.toDouble() ?? 1280.0,
  windowHeight: (json['windowHeight'] as num?)?.toDouble() ?? 720.0,
  windowX: (json['windowX'] as num?)?.toDouble() ?? 0,
  windowY: (json['windowY'] as num?)?.toDouble() ?? 0,
  readSetting: json['readSetting'] == null
      ? const ReadSettingState()
      : ReadSettingState.fromJson(json['readSetting'] as Map<String, dynamic>),
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
      'syncSetting': instance.syncSetting,
      'md5': instance.md5,
      'autoSync': instance.autoSync,
      'syncNotify': instance.syncNotify,
      'comicReadTopContainer': instance.comicReadTopContainer,
      'readMode': instance.readMode,
      'maskedKeywords': instance.maskedKeywords,
      'socks5Proxy': instance.socks5Proxy,
      'needCleanCache': instance.needCleanCache,
      'comicChoice': instance.comicChoice,
      'disableBika': instance.disableBika,
      'enableMemoryDebug': instance.enableMemoryDebug,
      'forceEnableImpeller': instance.forceEnableImpeller,
      'updateAccelerate': instance.updateAccelerate,
      'searchHistory': instance.searchHistory,
      'windowWidth': instance.windowWidth,
      'windowHeight': instance.windowHeight,
      'windowX': instance.windowX,
      'windowY': instance.windowY,
      'readSetting': instance.readSetting,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};

_WebDavSettingState _$WebDavSettingStateFromJson(Map<String, dynamic> json) =>
    _WebDavSettingState(
      host: json['host'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );

Map<String, dynamic> _$WebDavSettingStateToJson(_WebDavSettingState instance) =>
    <String, dynamic>{
      'host': instance.host,
      'username': instance.username,
      'password': instance.password,
    };

_S3SettingState _$S3SettingStateFromJson(Map<String, dynamic> json) =>
    _S3SettingState(
      endpoint: json['endpoint'] as String? ?? '',
      accessKey: json['accessKey'] as String? ?? '',
      secretKey: json['secretKey'] as String? ?? '',
      bucket: json['bucket'] as String? ?? '',
      region: json['region'] as String? ?? '',
      useSSL: json['useSSL'] as bool? ?? true,
      port: (json['port'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$S3SettingStateToJson(_S3SettingState instance) =>
    <String, dynamic>{
      'endpoint': instance.endpoint,
      'accessKey': instance.accessKey,
      'secretKey': instance.secretKey,
      'bucket': instance.bucket,
      'region': instance.region,
      'useSSL': instance.useSSL,
      'port': instance.port,
    };

_SyncSettingState _$SyncSettingStateFromJson(Map<String, dynamic> json) =>
    _SyncSettingState(
      syncServiceType:
          $enumDecodeNullable(
            _$SyncServiceTypeEnumMap,
            json['syncServiceType'],
          ) ??
          SyncServiceType.webdav,
      webdavSetting: json['webdavSetting'] == null
          ? const WebDavSettingState()
          : WebDavSettingState.fromJson(
              json['webdavSetting'] as Map<String, dynamic>,
            ),
      s3Setting: json['s3Setting'] == null
          ? const S3SettingState()
          : S3SettingState.fromJson(json['s3Setting'] as Map<String, dynamic>),
      syncSettings: json['syncSettings'] as bool? ?? false,
      autoSync: json['autoSync'] as bool? ?? true,
      syncNotify: json['syncNotify'] as bool? ?? true,
    );

Map<String, dynamic> _$SyncSettingStateToJson(_SyncSettingState instance) =>
    <String, dynamic>{
      'syncServiceType': _$SyncServiceTypeEnumMap[instance.syncServiceType]!,
      'webdavSetting': instance.webdavSetting,
      's3Setting': instance.s3Setting,
      'syncSettings': instance.syncSettings,
      'autoSync': instance.autoSync,
      'syncNotify': instance.syncNotify,
    };

const _$SyncServiceTypeEnumMap = {
  SyncServiceType.none: 'none',
  SyncServiceType.webdav: 'webdav',
  SyncServiceType.s3: 's3',
};

_ReadSettingState _$ReadSettingStateFromJson(Map<String, dynamic> json) =>
    _ReadSettingState(
      noAnimation: json['noAnimation'] as bool? ?? false,
      comicReadTopContainer: json['comicReadTopContainer'] as bool? ?? true,
      readMode: (json['readMode'] as num?)?.toInt() ?? 0,
      readerBackgroundMode:
          $enumDecodeNullable(
            _$ReaderBackgroundModeEnumMap,
            json['readerBackgroundMode'],
          ) ??
          ReaderBackgroundMode.auto,
      readFilterEnabled: json['readFilterEnabled'] as bool? ?? true,
      readFilterOpacityPercent:
          (json['readFilterOpacityPercent'] as num?)?.toInt() ?? 50,
      einkOptimization: json['einkOptimization'] as bool? ?? false,
      einkDelayMs: (json['einkDelayMs'] as num?)?.toInt() ?? 120,
      autoScroll: json['autoScroll'] as bool? ?? false,
      autoScrollColumnIntervalMs:
          (json['autoScrollColumnIntervalMs'] as num?)?.toInt() ?? 1600,
      autoScrollPageIntervalMs:
          (json['autoScrollPageIntervalMs'] as num?)?.toInt() ?? 3000,
      autoScrollColumnDistancePercent:
          (json['autoScrollColumnDistancePercent'] as num?)?.toInt() ?? 72,
      doublePageMode: json['doublePageMode'] as bool? ?? false,
      sidePaddingEnabled: json['sidePaddingEnabled'] as bool? ?? false,
      sidePaddingPercent: (json['sidePaddingPercent'] as num?)?.toInt() ?? 10,
      volumeKeyPageTurn: json['volumeKeyPageTurn'] as bool? ?? true,
      volumeKeyPageTurnDistancePercent:
          (json['volumeKeyPageTurnDistancePercent'] as num?)?.toInt() ?? 72,
      doubleTapZoom: json['doubleTapZoom'] as bool? ?? false,
      doubleTapOpenMenu: json['doubleTapOpenMenu'] as bool? ?? false,
      pageInfoShowPage: json['pageInfoShowPage'] as bool? ?? true,
      pageInfoShowNetwork: json['pageInfoShowNetwork'] as bool? ?? true,
      pageInfoShowBattery: json['pageInfoShowBattery'] as bool? ?? false,
      pageInfoShowTime: json['pageInfoShowTime'] as bool? ?? true,
      pageInfoVerticalPosition:
          $enumDecodeNullable(
            _$ReaderInfoVerticalPositionEnumMap,
            json['pageInfoVerticalPosition'],
          ) ??
          ReaderInfoVerticalPosition.bottom,
      pageInfoTopInStatusBar: json['pageInfoTopInStatusBar'] as bool? ?? false,
      pageInfoHorizontalPosition:
          $enumDecodeNullable(
            _$ReaderInfoHorizontalPositionEnumMap,
            json['pageInfoHorizontalPosition'],
          ) ??
          ReaderInfoHorizontalPosition.left,
      pageInfoEdgePadding: (json['pageInfoEdgePadding'] as num?)?.toInt() ?? 12,
      pageInfoOpacityPercent:
          (json['pageInfoOpacityPercent'] as num?)?.toInt() ?? 82,
      pageInfoFontSize: (json['pageInfoFontSize'] as num?)?.toInt() ?? 12,
      autoNextChapter: json['autoNextChapter'] as bool? ?? false,
    );

Map<String, dynamic> _$ReadSettingStateToJson(
  _ReadSettingState instance,
) => <String, dynamic>{
  'noAnimation': instance.noAnimation,
  'comicReadTopContainer': instance.comicReadTopContainer,
  'readMode': instance.readMode,
  'readerBackgroundMode':
      _$ReaderBackgroundModeEnumMap[instance.readerBackgroundMode]!,
  'readFilterEnabled': instance.readFilterEnabled,
  'readFilterOpacityPercent': instance.readFilterOpacityPercent,
  'einkOptimization': instance.einkOptimization,
  'einkDelayMs': instance.einkDelayMs,
  'autoScroll': instance.autoScroll,
  'autoScrollColumnIntervalMs': instance.autoScrollColumnIntervalMs,
  'autoScrollPageIntervalMs': instance.autoScrollPageIntervalMs,
  'autoScrollColumnDistancePercent': instance.autoScrollColumnDistancePercent,
  'doublePageMode': instance.doublePageMode,
  'sidePaddingEnabled': instance.sidePaddingEnabled,
  'sidePaddingPercent': instance.sidePaddingPercent,
  'volumeKeyPageTurn': instance.volumeKeyPageTurn,
  'volumeKeyPageTurnDistancePercent': instance.volumeKeyPageTurnDistancePercent,
  'doubleTapZoom': instance.doubleTapZoom,
  'doubleTapOpenMenu': instance.doubleTapOpenMenu,
  'pageInfoShowPage': instance.pageInfoShowPage,
  'pageInfoShowNetwork': instance.pageInfoShowNetwork,
  'pageInfoShowBattery': instance.pageInfoShowBattery,
  'pageInfoShowTime': instance.pageInfoShowTime,
  'pageInfoVerticalPosition':
      _$ReaderInfoVerticalPositionEnumMap[instance.pageInfoVerticalPosition]!,
  'pageInfoTopInStatusBar': instance.pageInfoTopInStatusBar,
  'pageInfoHorizontalPosition':
      _$ReaderInfoHorizontalPositionEnumMap[instance
          .pageInfoHorizontalPosition]!,
  'pageInfoEdgePadding': instance.pageInfoEdgePadding,
  'pageInfoOpacityPercent': instance.pageInfoOpacityPercent,
  'pageInfoFontSize': instance.pageInfoFontSize,
  'autoNextChapter': instance.autoNextChapter,
};

const _$ReaderBackgroundModeEnumMap = {
  ReaderBackgroundMode.auto: 'auto',
  ReaderBackgroundMode.black: 'black',
  ReaderBackgroundMode.white: 'white',
  ReaderBackgroundMode.grey: 'grey',
};

const _$ReaderInfoVerticalPositionEnumMap = {
  ReaderInfoVerticalPosition.top: 'top',
  ReaderInfoVerticalPosition.bottom: 'bottom',
};

const _$ReaderInfoHorizontalPositionEnumMap = {
  ReaderInfoHorizontalPosition.left: 'left',
  ReaderInfoHorizontalPosition.center: 'center',
  ReaderInfoHorizontalPosition.right: 'right',
};
