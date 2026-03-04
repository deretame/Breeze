// 全局设置

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/config/global/color_theme_types.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/json/converter.dart';

part 'global_setting.freezed.dart';
part 'global_setting.g.dart';

enum ReaderInfoVerticalPosition { top, bottom }

enum ReaderInfoHorizontalPosition { left, center, right }

enum ReaderBackgroundMode { auto, black, white, grey }

enum SyncServiceType { none, webdav, s3 }

extension SyncServiceTypeExtension on SyncServiceType {
  String get label {
    switch (this) {
      case SyncServiceType.none:
        return '不启用';
      case SyncServiceType.webdav:
        return 'WebDAV';
      case SyncServiceType.s3:
        return 'S3';
    }
  }
}

const Color readerBackgroundBlack = Colors.black;
const Color readerBackgroundWhite = Colors.white;
const Color readerBackgroundGrey = Color(0xFF2D2D2D);

extension ReadSettingStateBackgroundColor on ReadSettingState {
  Color resolveReaderBackgroundColor(Brightness brightness) {
    switch (readerBackgroundMode) {
      case ReaderBackgroundMode.auto:
        return brightness == Brightness.dark
            ? readerBackgroundBlack
            : readerBackgroundWhite;
      case ReaderBackgroundMode.black:
        return readerBackgroundBlack;
      case ReaderBackgroundMode.white:
        return readerBackgroundWhite;
      case ReaderBackgroundMode.grey:
        return readerBackgroundGrey;
    }
  }

  Color resolveReaderForegroundColor(Brightness brightness) {
    final backgroundColor = resolveReaderBackgroundColor(brightness);
    return backgroundColor.computeLuminance() < 0.5
        ? Colors.white
        : Colors.black;
  }
}

GlobalSettingState get globalSetting {
  return objectbox.userSettingBox.get(1)!.globalSetting;
}

@freezed
abstract class GlobalSettingState with _$GlobalSettingState {
  const factory GlobalSettingState({
    @Default(true) bool dynamicColor,
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(true) bool isAMOLED,
    @ColorConverter() @Default(Color(0xFFEF5350)) Color seedColor,
    @Default(0) int themeInitState,
    @LocaleConverter() @Default(Locale('zh', 'CN')) Locale locale,
    @Default(0) int welcomePageNum,
    @Default(SyncSettingState()) SyncSettingState syncSetting,
    @Default('') String md5,
    @Default(true) bool autoSync,
    @Default(true) bool syncNotify,
    @Default(true) bool comicReadTopContainer,
    @Default(0) int readMode,
    @Default([]) List<String> maskedKeywords,
    @Default('') String socks5Proxy,
    @Default(false) bool needCleanCache,
    @Default(1) int comicChoice,
    @Default(false) bool disableBika,
    @Default(false) bool enableMemoryDebug,
    @Default(true) bool updateAccelerate,
    @Default([]) List<String> searchHistory,
    @Default(1280.0) double windowWidth,
    @Default(720.0) double windowHeight,
    @Default(0) double windowX,
    @Default(0) double windowY,
    @Default(ReadSettingState()) ReadSettingState readSetting,
  }) = _GlobalSettingState;

  factory GlobalSettingState.fromJson(Map<String, dynamic> json) =>
      _$GlobalSettingStateFromJson(_migrateGlobalSettingJson(json));
}

@freezed
abstract class WebDavSettingState with _$WebDavSettingState {
  const factory WebDavSettingState({
    @Default('') String host,
    @Default('') String username,
    @Default('') String password,
  }) = _WebDavSettingState;

  factory WebDavSettingState.fromJson(Map<String, dynamic> json) =>
      _$WebDavSettingStateFromJson(json);
}

@freezed
abstract class S3SettingState with _$S3SettingState {
  const factory S3SettingState({
    @Default('') String endpoint,
    @Default('') String accessKey,
    @Default('') String secretKey,
    @Default('') String bucket,
    @Default('') String region,
    @Default(true) bool useSSL,
    @Default(0) int port,
  }) = _S3SettingState;

  factory S3SettingState.fromJson(Map<String, dynamic> json) =>
      _$S3SettingStateFromJson(json);
}

@freezed
abstract class SyncSettingState with _$SyncSettingState {
  const factory SyncSettingState({
    @Default(SyncServiceType.webdav) SyncServiceType syncServiceType,
    @Default(WebDavSettingState()) WebDavSettingState webdavSetting,
    @Default(S3SettingState()) S3SettingState s3Setting,
    @Default(false) bool syncSettings,
    @Default(true) bool autoSync,
    @Default(true) bool syncNotify,
  }) = _SyncSettingState;

  factory SyncSettingState.fromJson(Map<String, dynamic> json) =>
      _$SyncSettingStateFromJson(json);
}

@freezed
abstract class ReadSettingState with _$ReadSettingState {
  const factory ReadSettingState({
    @Default(false) bool noAnimation,
    @Default(true) bool comicReadTopContainer,
    @Default(0) int readMode,
    @Default(ReaderBackgroundMode.auto)
    ReaderBackgroundMode readerBackgroundMode,
    @Default(true) bool readFilterEnabled,
    @Default(50) int readFilterOpacityPercent,
    @Default(false) bool einkOptimization,
    @Default(120) int einkDelayMs,
    @Default(false) bool autoScroll,
    @Default(1600) int autoScrollColumnIntervalMs,
    @Default(3000) int autoScrollPageIntervalMs,
    @Default(72) int autoScrollColumnDistancePercent,
    @Default(false) bool doublePageMode,
    @Default(false) bool sidePaddingEnabled,
    @Default(10) int sidePaddingPercent,
    @Default(true) bool volumeKeyPageTurn,
    @Default(72) int volumeKeyPageTurnDistancePercent,
    @Default(false) bool doubleTapZoom,
    @Default(false) bool doubleTapOpenMenu,
    @Default(true) bool pageInfoShowPage,
    @Default(true) bool pageInfoShowNetwork,
    @Default(false) bool pageInfoShowBattery,
    @Default(true) bool pageInfoShowTime,
    @Default(ReaderInfoVerticalPosition.bottom)
    ReaderInfoVerticalPosition pageInfoVerticalPosition,
    @Default(false) bool pageInfoTopInStatusBar,
    @Default(ReaderInfoHorizontalPosition.left)
    ReaderInfoHorizontalPosition pageInfoHorizontalPosition,
    @Default(12) int pageInfoEdgePadding,
    @Default(82) int pageInfoOpacityPercent,
    @Default(12) int pageInfoFontSize,
  }) = _ReadSettingState;

  factory ReadSettingState.fromJson(Map<String, dynamic> json) =>
      _$ReadSettingStateFromJson(json);
}

Map<String, dynamic> _toMutableJsonMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }

  if (value is Map) {
    return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
  }

  return <String, dynamic>{};
}

Map<String, dynamic> _migrateGlobalSettingJson(Map<String, dynamic> json) {
  final migrated = Map<String, dynamic>.from(json);

  final syncSetting = _toMutableJsonMap(migrated['syncSetting']);
  final webdavSetting = _toMutableJsonMap(syncSetting['webdavSetting']);

  if (!syncSetting.containsKey('syncServiceType') &&
      migrated.containsKey('syncServiceType')) {
    syncSetting['syncServiceType'] = migrated['syncServiceType'];
  }

  if (!syncSetting.containsKey('autoSync') &&
      migrated.containsKey('autoSync')) {
    syncSetting['autoSync'] = migrated['autoSync'];
  }

  if (!syncSetting.containsKey('syncNotify') &&
      migrated.containsKey('syncNotify')) {
    syncSetting['syncNotify'] = migrated['syncNotify'];
  }

  if (!migrated.containsKey('autoSync') &&
      syncSetting.containsKey('autoSync')) {
    migrated['autoSync'] = syncSetting['autoSync'];
  }

  if (!migrated.containsKey('syncNotify') &&
      syncSetting.containsKey('syncNotify')) {
    migrated['syncNotify'] = syncSetting['syncNotify'];
  }

  if (!webdavSetting.containsKey('host') &&
      migrated.containsKey('webdavHost')) {
    webdavSetting['host'] = migrated['webdavHost'];
  }

  if (!webdavSetting.containsKey('username') &&
      migrated.containsKey('webdavUsername')) {
    webdavSetting['username'] = migrated['webdavUsername'];
  }

  if (!webdavSetting.containsKey('password') &&
      migrated.containsKey('webdavPassword')) {
    webdavSetting['password'] = migrated['webdavPassword'];
  }

  if (webdavSetting.isNotEmpty || syncSetting.containsKey('webdavSetting')) {
    syncSetting['webdavSetting'] = webdavSetting;
  }

  if (syncSetting.isNotEmpty || migrated.containsKey('syncSetting')) {
    migrated['syncSetting'] = syncSetting;
  }

  final readSetting = _toMutableJsonMap(migrated['readSetting']);

  if (!readSetting.containsKey('comicReadTopContainer') &&
      migrated.containsKey('comicReadTopContainer')) {
    readSetting['comicReadTopContainer'] = migrated['comicReadTopContainer'];
  }

  if (!readSetting.containsKey('readMode') &&
      migrated.containsKey('readMode')) {
    readSetting['readMode'] = migrated['readMode'];
  }

  final rawReadMode =
      (readSetting['readMode'] as num?)?.toInt() ??
      (migrated['readMode'] as num?)?.toInt();
  if (rawReadMode != null && rawReadMode >= 3) {
    readSetting['doublePageMode'] = true;
    if (rawReadMode == 3) {
      readSetting['readMode'] = 1;
    } else if (rawReadMode == 4) {
      readSetting['readMode'] = 2;
    } else {
      readSetting['readMode'] = 0;
    }
  }

  if (!migrated.containsKey('comicReadTopContainer') &&
      readSetting.containsKey('comicReadTopContainer')) {
    migrated['comicReadTopContainer'] = readSetting['comicReadTopContainer'];
  }

  if (!migrated.containsKey('readMode') &&
      readSetting.containsKey('readMode')) {
    migrated['readMode'] = readSetting['readMode'];
  }

  if (readSetting.isNotEmpty || migrated.containsKey('readSetting')) {
    migrated['readSetting'] = readSetting;
  }

  return migrated;
}

const _defaultGlobalSetting = GlobalSettingState();

T _resolveCanonicalValue<T>({
  required T legacy,
  required T nested,
  required T previousLegacy,
  required T previousNested,
}) {
  final legacyChanged = legacy != previousLegacy;
  final nestedChanged = nested != previousNested;

  if (legacyChanged && !nestedChanged) {
    return legacy;
  }

  if (nestedChanged && !legacyChanged) {
    return nested;
  }

  return nested;
}

extension GlobalSettingStateLegacySync on GlobalSettingState {
  GlobalSettingState syncLegacyAndNested({GlobalSettingState? previous}) {
    final autoSyncValue = previous == null
        ? (autoSync != _defaultGlobalSetting.autoSync
              ? autoSync
              : syncSetting.autoSync)
        : _resolveCanonicalValue(
            legacy: autoSync,
            nested: syncSetting.autoSync,
            previousLegacy: previous.autoSync,
            previousNested: previous.syncSetting.autoSync,
          );

    final syncNotifyValue = previous == null
        ? (syncNotify != _defaultGlobalSetting.syncNotify
              ? syncNotify
              : syncSetting.syncNotify)
        : _resolveCanonicalValue(
            legacy: syncNotify,
            nested: syncSetting.syncNotify,
            previousLegacy: previous.syncNotify,
            previousNested: previous.syncSetting.syncNotify,
          );

    final comicReadTopContainerValue = previous == null
        ? (comicReadTopContainer != _defaultGlobalSetting.comicReadTopContainer
              ? comicReadTopContainer
              : readSetting.comicReadTopContainer)
        : _resolveCanonicalValue(
            legacy: comicReadTopContainer,
            nested: readSetting.comicReadTopContainer,
            previousLegacy: previous.comicReadTopContainer,
            previousNested: previous.readSetting.comicReadTopContainer,
          );

    final readModeValue = previous == null
        ? (readMode != _defaultGlobalSetting.readMode
              ? readMode
              : readSetting.readMode)
        : _resolveCanonicalValue(
            legacy: readMode,
            nested: readSetting.readMode,
            previousLegacy: previous.readMode,
            previousNested: previous.readSetting.readMode,
          );

    return copyWith(
      autoSync: autoSyncValue,
      syncNotify: syncNotifyValue,
      comicReadTopContainer: comicReadTopContainerValue,
      readMode: readModeValue,
      syncSetting: syncSetting.copyWith(
        autoSync: autoSyncValue,
        syncNotify: syncNotifyValue,
      ),
      readSetting: readSetting.copyWith(
        comicReadTopContainer: comicReadTopContainerValue,
        readMode: readModeValue,
      ),
    );
  }
}

extension GlobalSettingStateCompat on GlobalSettingState {
  SyncServiceType get syncServiceType => syncSetting.syncServiceType;

  bool get syncSettings => syncSetting.syncSettings;

  WebDavSettingState get webdavSetting => syncSetting.webdavSetting;

  String get webdavHost => webdavSetting.host;

  String get webdavUsername => webdavSetting.username;

  String get webdavPassword => webdavSetting.password;

  S3SettingState get s3Setting => syncSetting.s3Setting;
}

class GlobalSettingCubit extends Cubit<GlobalSettingState> {
  // 构造函数，传入由 freezed 生成的默认 state
  GlobalSettingCubit() : super(const GlobalSettingState());

  // 用于获取 freezed 中定义的默认值的便捷实例
  static const _defaults = GlobalSettingState();
  // colorThemeList[6].color 是动态的，不能在 const 中，单独处理
  late final Color _defaultSeedColor = colorThemeList[6].color;

  Future<void> initBox() async {
    final dbState = objectbox.userSettingBox.get(1)!.globalSetting;
    final migratedState = dbState.syncLegacyAndNested();
    if (migratedState != dbState) {
      _updateDataBase(migratedState);
    }
    emit(migratedState);
  }

  GlobalSettingState get defaults =>
      _defaults.copyWith(seedColor: _defaultSeedColor);

  void updateState(
    GlobalSettingState Function(GlobalSettingState current) updates,
  ) {
    final newState = updates(state);
    _persistAndEmit(newState);
  }

  void updateReadSetting(
    ReadSettingState Function(ReadSettingState current) updates,
  ) {
    updateState(
      (current) => current.copyWith(readSetting: updates(current.readSetting)),
    );
  }

  void updateSyncSetting(
    SyncSettingState Function(SyncSettingState current) updates,
  ) {
    updateState(
      (current) => current.copyWith(syncSetting: updates(current.syncSetting)),
    );
  }

  void updateWebDavSetting(
    WebDavSettingState Function(WebDavSettingState current) updates,
  ) {
    updateSyncSetting(
      (current) =>
          current.copyWith(webdavSetting: updates(current.webdavSetting)),
    );
  }

  void resetState(
    GlobalSettingState Function(
      GlobalSettingState current,
      GlobalSettingState defaults,
    )
    updates,
  ) {
    final newState = updates(state, defaults);
    _persistAndEmit(newState);
  }

  void _persistAndEmit(GlobalSettingState newState) {
    final syncedState = newState.syncLegacyAndNested(previous: state);
    final currentDbState = objectbox.userSettingBox.get(1)?.globalSetting;
    final reconciledState = currentDbState == null
        ? syncedState
        : syncedState.copyWith(md5: currentDbState.md5);

    if (reconciledState == state) return;
    _updateDataBase(reconciledState);
    emit(reconciledState);
  }

  void _updateDataBase(GlobalSettingState state) {
    // logger.d(state.toJson());
    final userBox = objectbox.userSettingBox;
    var dbSettings = userBox.get(1)!;
    dbSettings.globalSetting = state;
    userBox.put(dbSettings);
  }
}
