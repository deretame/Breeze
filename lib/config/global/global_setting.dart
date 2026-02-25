// 全局设置

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/config/global/color_theme_types.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/json/converter.dart';

part 'global_setting.freezed.dart';
part 'global_setting.g.dart';

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
    @Default('') String webdavHost,
    @Default('') String webdavUsername,
    @Default('') String webdavPassword,
    @Default(true) bool autoSync,
    @Default(true) bool syncNotify,
    @Default(true) bool shade,
    @Default(true) bool comicReadTopContainer,
    @Default(0) int readMode,
    @Default([]) List<String> maskedKeywords,
    @Default('') String socks5Proxy,
    @Default(false) bool needCleanCache,
    @Default(1) int comicChoice,
    @Default(false) bool disableBika,
    @Default(false) bool enableMemoryDebug,
    @Default([]) List<String> searchHistory,
    @Default(1280.0) double windowWidth,
    @Default(720.0) double windowHeight,
    @Default(0) double windowX,
    @Default(0) double windowY,
  }) = _GlobalSettingState;

  factory GlobalSettingState.fromJson(Map<String, dynamic> json) =>
      _$GlobalSettingStateFromJson(json);
}

class GlobalSettingCubit extends Cubit<GlobalSettingState> {
  // 构造函数，传入由 freezed 生成的默认 state
  GlobalSettingCubit() : super(const GlobalSettingState());

  // 用于获取 freezed 中定义的默认值的便捷实例
  static const _defaults = GlobalSettingState();
  // colorThemeList[6].color 是动态的，不能在 const 中，单独处理
  late final Color _defaultSeedColor = colorThemeList[6].color;

  Future<void> initBox() async {
    emit(objectbox.userSettingBox.get(1)!.globalSetting);
  }

  void updateDynamicColor(bool value) {
    final temp = state.copyWith(dynamicColor: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetDynamicColor() {
    final temp = state.copyWith(dynamicColor: _defaults.dynamicColor);
    updateDataBase(temp);
    emit(temp);
  }

  void updateThemeMode(ThemeMode value) {
    final temp = state.copyWith(themeMode: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetThemeMode() {
    final temp = state.copyWith(themeMode: _defaults.themeMode);
    updateDataBase(temp);
    emit(temp);
  }

  void updateIsAMOLED(bool value) {
    final temp = state.copyWith(isAMOLED: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetIsAMOLED() {
    final temp = state.copyWith(isAMOLED: _defaults.isAMOLED);
    updateDataBase(temp);
    emit(temp);
  }

  void updateSeedColor(Color value) {
    final temp = state.copyWith(seedColor: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetSeedColor() {
    final temp = state.copyWith(seedColor: _defaultSeedColor);
    updateDataBase(temp);
    emit(temp);
  }

  void updateThemeInitState(int value) {
    final temp = state.copyWith(themeInitState: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetThemeInitState() {
    final temp = state.copyWith(themeInitState: _defaults.themeInitState);
    updateDataBase(temp);
    emit(temp);
  }

  void updateLocale(Locale value) {
    final temp = state.copyWith(locale: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetLocale() {
    final temp = state.copyWith(locale: _defaults.locale);
    updateDataBase(temp);
    emit(temp);
  }

  void updateWelcomePageNum(int value) {
    final temp = state.copyWith(welcomePageNum: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetWelcomePageNum() {
    final temp = state.copyWith(welcomePageNum: _defaults.welcomePageNum);
    updateDataBase(temp);
    emit(temp);
  }

  void updateWebdavHost(String value) {
    final temp = state.copyWith(webdavHost: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetWebdavHost() {
    final temp = state.copyWith(webdavHost: _defaults.webdavHost);
    updateDataBase(temp);
    emit(temp);
  }

  void updateWebdavUsername(String value) {
    final temp = state.copyWith(webdavUsername: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetWebdavUsername() {
    final temp = state.copyWith(webdavUsername: _defaults.webdavUsername);
    updateDataBase(temp);
    emit(temp);
  }

  void updateWebdavPassword(String value) {
    final temp = state.copyWith(webdavPassword: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetWebdavPassword() {
    final temp = state.copyWith(webdavPassword: _defaults.webdavPassword);
    updateDataBase(temp);
    emit(temp);
  }

  void updateAutoSync(bool value) {
    final temp = state.copyWith(autoSync: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetAutoSync() {
    final temp = state.copyWith(autoSync: _defaults.autoSync);
    updateDataBase(temp);
    emit(temp);
  }

  void updateSyncNotify(bool value) {
    final temp = state.copyWith(syncNotify: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetSyncNotify() {
    final temp = state.copyWith(syncNotify: _defaults.syncNotify);
    updateDataBase(temp);
    emit(temp);
  }

  void updateShade(bool value) {
    final temp = state.copyWith(shade: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetShade() {
    final temp = state.copyWith(shade: _defaults.shade);
    updateDataBase(temp);
    emit(temp);
  }

  void updateComicReadTopContainer(bool value) {
    final temp = state.copyWith(comicReadTopContainer: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetComicReadTopContainer() {
    final temp = state.copyWith(
      comicReadTopContainer: _defaults.comicReadTopContainer,
    );
    updateDataBase(temp);
    emit(temp);
  }

  void updateReadMode(int value) {
    final temp = state.copyWith(readMode: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetReadMode() {
    final temp = state.copyWith(readMode: _defaults.readMode);
    updateDataBase(temp);
    emit(temp);
  }

  void updateMaskedKeywords(List<String> value) {
    final temp = state.copyWith(maskedKeywords: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetMaskedKeywords() {
    final temp = state.copyWith(maskedKeywords: _defaults.maskedKeywords);
    updateDataBase(temp);
    emit(temp);
  }

  void updateSocks5Proxy(String value) {
    final temp = state.copyWith(socks5Proxy: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetSocks5Proxy() {
    final temp = state.copyWith(socks5Proxy: _defaults.socks5Proxy);
    updateDataBase(temp);
    emit(temp);
  }

  void updateNeedCleanCache(bool value) {
    final temp = state.copyWith(needCleanCache: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetNeedCleanCache() {
    final temp = state.copyWith(needCleanCache: _defaults.needCleanCache);
    updateDataBase(temp);
    emit(temp);
  }

  void updateComicChoice(int value) {
    final temp = state.copyWith(comicChoice: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetComicChoice() {
    final temp = state.copyWith(comicChoice: _defaults.comicChoice);
    updateDataBase(temp);
    emit(temp);
  }

  void updateDisableBika(bool value) {
    final temp = state.copyWith(disableBika: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetDisableBika() {
    final temp = state.copyWith(disableBika: _defaults.disableBika);
    updateDataBase(temp);
    emit(temp);
  }

  void updateEnableMemoryDebug(bool value) {
    final temp = state.copyWith(enableMemoryDebug: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetEnableMemoryDebug() {
    final temp = state.copyWith(enableMemoryDebug: _defaults.enableMemoryDebug);
    updateDataBase(temp);
    emit(temp);
  }

  void updateSearchHistory(List<String> value) {
    final temp = state.copyWith(searchHistory: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetSearchHistory() {
    final temp = state.copyWith(searchHistory: _defaults.searchHistory);
    updateDataBase(temp);
    emit(temp);
  }

  void updateWindowWidth(double value) {
    final temp = state.copyWith(windowWidth: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetWindowWidth() {
    final temp = state.copyWith(windowWidth: _defaults.windowWidth);
    updateDataBase(temp);
    emit(temp);
  }

  void updateWindowHeight(double value) {
    final temp = state.copyWith(windowHeight: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetWindowHeight() {
    final temp = state.copyWith(windowHeight: _defaults.windowHeight);
    updateDataBase(temp);
    emit(temp);
  }

  void updateWindowX(double value) {
    final temp = state.copyWith(windowX: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetWindowX() {
    final temp = state.copyWith(windowX: _defaults.windowX);
    updateDataBase(temp);
    emit(temp);
  }

  void updateWindowY(double value) {
    final temp = state.copyWith(windowY: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetWindowY() {
    final temp = state.copyWith(windowY: _defaults.windowY);
    updateDataBase(temp);
    emit(temp);
  }

  void updateDataBase(GlobalSettingState state) {
    // logger.d(state.toJson());
    final userBox = objectbox.userSettingBox;
    var dbSettings = userBox.get(1)!;
    dbSettings.globalSetting = state;
    userBox.put(dbSettings);
  }
}
