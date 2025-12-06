// 全局设置

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:zephyr/config/global/color_theme_types.dart';
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
    @Default([""]) List<String> maskedKeywords,
    @Default('') String socks5Proxy,
    @Default(false) bool needCleanCache,
    @Default(1) int comicChoice,
    @Default(false) bool disableBika,
    @Default(false) bool enableMemoryDebug,
  }) = _GlobalSettingState;

  factory GlobalSettingState.fromJson(Map<String, dynamic> json) =>
      _$GlobalSettingStateFromJson(json);
}

class GlobalSettingCubit extends Cubit<GlobalSettingState> {
  late final Box<dynamic> _box;

  // 构造函数，传入由 freezed 生成的默认 state
  GlobalSettingCubit() : super(const GlobalSettingState());

  // 用于获取 freezed 中定义的默认值的便捷实例
  static const _defaults = GlobalSettingState();
  // colorThemeList[6].color 是动态的，不能在 const 中，单独处理
  late final Color _defaultSeedColor = colorThemeList[6].color;

  Future<void> initBox() async {
    _box = await Hive.openBox(GlobalSettingBoxKey.globalSetting);

    // 从 Hive 加载数据
    // 我们使用 state.fieldName (来自 freezed 的 @Default) 作为 Hive.get 的 defaultValue
    emit(
      state.copyWith(
        dynamicColor: _box.get(
          GlobalSettingBoxKey.dynamicColor,
          defaultValue: state.dynamicColor,
        ),
        themeMode:
            ThemeMode.values[_box.get(
              GlobalSettingBoxKey.themeMode,
              defaultValue: state.themeMode.index,
            )],
        isAMOLED: _box.get(
          GlobalSettingBoxKey.isAMOLED,
          defaultValue: state.isAMOLED,
        ),
        seedColor: _box.get(
          GlobalSettingBoxKey.seedColor,
          defaultValue: _defaultSeedColor,
        ),
        themeInitState: _box.get(
          GlobalSettingBoxKey.themeInitState,
          defaultValue: state.themeInitState,
        ),
        locale: _box.get(
          GlobalSettingBoxKey.locale,
          defaultValue: state.locale,
        ),
        welcomePageNum: _box.get(
          GlobalSettingBoxKey.welcomePageNum,
          defaultValue: state.welcomePageNum,
        ),
        webdavHost: _box.get(
          GlobalSettingBoxKey.webdavHost,
          defaultValue: state.webdavHost,
        ),
        webdavUsername: _box.get(
          GlobalSettingBoxKey.webdavUsername,
          defaultValue: state.webdavUsername,
        ),
        webdavPassword: _box.get(
          GlobalSettingBoxKey.webdavPassword,
          defaultValue: state.webdavPassword,
        ),
        autoSync: _box.get(
          GlobalSettingBoxKey.autoSync,
          defaultValue: state.autoSync,
        ),
        syncNotify: _box.get(
          GlobalSettingBoxKey.syncNotify,
          defaultValue: state.syncNotify,
        ),
        shade: _box.get(GlobalSettingBoxKey.shade, defaultValue: state.shade),
        comicReadTopContainer: _box.get(
          GlobalSettingBoxKey.comicReadTopContainer,
          defaultValue: state.comicReadTopContainer,
        ),
        readMode: _box.get(
          GlobalSettingBoxKey.readMode,
          defaultValue: state.readMode,
        ),
        maskedKeywords: _box.get(
          GlobalSettingBoxKey.maskedKeywords,
          defaultValue: state.maskedKeywords,
        ),
        socks5Proxy: _box.get(
          GlobalSettingBoxKey.socks5Proxy,
          defaultValue: state.socks5Proxy,
        ),
        needCleanCache: _box.get(
          GlobalSettingBoxKey.needCleanCache,
          defaultValue: state.needCleanCache,
        ),
        comicChoice: _box.get(
          GlobalSettingBoxKey.comicChoice,
          defaultValue: state.comicChoice,
        ),
        disableBika: _box.get(
          GlobalSettingBoxKey.disableBika,
          defaultValue: state.disableBika,
        ),
        enableMemoryDebug: _box.get(
          GlobalSettingBoxKey.enableMemoryDebug,
          defaultValue: state.enableMemoryDebug,
        ),
      ),
    );
  }

  void updateDynamicColor(bool value) {
    _box.put(GlobalSettingBoxKey.dynamicColor, value);
    emit(state.copyWith(dynamicColor: value));
  }

  void resetDynamicColor() {
    _box.delete(GlobalSettingBoxKey.dynamicColor);
    emit(state.copyWith(dynamicColor: _defaults.dynamicColor));
  }

  void updateThemeMode(ThemeMode value) {
    _box.put(GlobalSettingBoxKey.themeMode, value.index);
    emit(state.copyWith(themeMode: value));
  }

  void resetThemeMode() {
    _box.delete(GlobalSettingBoxKey.themeMode);
    emit(state.copyWith(themeMode: _defaults.themeMode));
  }

  void updateIsAMOLED(bool value) {
    _box.put(GlobalSettingBoxKey.isAMOLED, value);
    emit(state.copyWith(isAMOLED: value));
  }

  void resetIsAMOLED() {
    _box.delete(GlobalSettingBoxKey.isAMOLED);
    emit(state.copyWith(isAMOLED: _defaults.isAMOLED));
  }

  void updateSeedColor(Color value) {
    _box.put(GlobalSettingBoxKey.seedColor, value);
    emit(state.copyWith(seedColor: value));
  }

  void resetSeedColor() {
    _box.delete(GlobalSettingBoxKey.seedColor);
    emit(state.copyWith(seedColor: _defaultSeedColor));
  }

  void updateThemeInitState(int value) {
    _box.put(GlobalSettingBoxKey.themeInitState, value);
    emit(state.copyWith(themeInitState: value));
  }

  void resetThemeInitState() {
    _box.delete(GlobalSettingBoxKey.themeInitState);
    emit(state.copyWith(themeInitState: _defaults.themeInitState));
  }

  void updateLocale(Locale value) {
    _box.put(GlobalSettingBoxKey.locale, value);
    emit(state.copyWith(locale: value));
  }

  void resetLocale() {
    _box.delete(GlobalSettingBoxKey.locale);
    emit(state.copyWith(locale: _defaults.locale));
  }

  void updateWelcomePageNum(int value) {
    _box.put(GlobalSettingBoxKey.welcomePageNum, value);
    emit(state.copyWith(welcomePageNum: value));
  }

  void resetWelcomePageNum() {
    _box.delete(GlobalSettingBoxKey.welcomePageNum);
    emit(state.copyWith(welcomePageNum: _defaults.welcomePageNum));
  }

  void updateWebdavHost(String value) {
    _box.put(GlobalSettingBoxKey.webdavHost, value);
    emit(state.copyWith(webdavHost: value));
  }

  void resetWebdavHost() {
    _box.delete(GlobalSettingBoxKey.webdavHost);
    emit(state.copyWith(webdavHost: _defaults.webdavHost));
  }

  void updateWebdavUsername(String value) {
    _box.put(GlobalSettingBoxKey.webdavUsername, value);
    emit(state.copyWith(webdavUsername: value));
  }

  void resetWebdavUsername() {
    _box.delete(GlobalSettingBoxKey.webdavUsername);
    emit(state.copyWith(webdavUsername: _defaults.webdavUsername));
  }

  void updateWebdavPassword(String value) {
    _box.put(GlobalSettingBoxKey.webdavPassword, value);
    emit(state.copyWith(webdavPassword: value));
  }

  void resetWebdavPassword() {
    _box.delete(GlobalSettingBoxKey.webdavPassword);
    emit(state.copyWith(webdavPassword: _defaults.webdavPassword));
  }

  void updateAutoSync(bool value) {
    _box.put(GlobalSettingBoxKey.autoSync, value);
    emit(state.copyWith(autoSync: value));
  }

  void resetAutoSync() {
    _box.delete(GlobalSettingBoxKey.autoSync);
    emit(state.copyWith(autoSync: _defaults.autoSync));
  }

  void updateSyncNotify(bool value) {
    _box.put(GlobalSettingBoxKey.syncNotify, value);
    emit(state.copyWith(syncNotify: value));
  }

  void resetSyncNotify() {
    _box.delete(GlobalSettingBoxKey.syncNotify);
    emit(state.copyWith(syncNotify: _defaults.syncNotify));
  }

  void updateShade(bool value) {
    _box.put(GlobalSettingBoxKey.shade, value);
    emit(state.copyWith(shade: value));
  }

  void resetShade() {
    _box.delete(GlobalSettingBoxKey.shade);
    emit(state.copyWith(shade: _defaults.shade));
  }

  void updateComicReadTopContainer(bool value) {
    _box.put(GlobalSettingBoxKey.comicReadTopContainer, value);
    emit(state.copyWith(comicReadTopContainer: value));
  }

  void resetComicReadTopContainer() {
    _box.delete(GlobalSettingBoxKey.comicReadTopContainer);
    emit(
      state.copyWith(comicReadTopContainer: _defaults.comicReadTopContainer),
    );
  }

  void updateReadMode(int value) {
    _box.put(GlobalSettingBoxKey.readMode, value);
    emit(state.copyWith(readMode: value));
  }

  void resetReadMode() {
    _box.delete(GlobalSettingBoxKey.readMode);
    emit(state.copyWith(readMode: _defaults.readMode));
  }

  void updateMaskedKeywords(List<String> value) {
    _box.put(GlobalSettingBoxKey.maskedKeywords, value);
    emit(state.copyWith(maskedKeywords: value));
  }

  void resetMaskedKeywords() {
    _box.delete(GlobalSettingBoxKey.maskedKeywords);
    emit(state.copyWith(maskedKeywords: _defaults.maskedKeywords));
  }

  void updateSocks5Proxy(String value) {
    _box.put(GlobalSettingBoxKey.socks5Proxy, value);
    emit(state.copyWith(socks5Proxy: value));
  }

  void resetSocks5Proxy() {
    _box.delete(GlobalSettingBoxKey.socks5Proxy);
    emit(state.copyWith(socks5Proxy: _defaults.socks5Proxy));
  }

  void updateNeedCleanCache(bool value) {
    _box.put(GlobalSettingBoxKey.needCleanCache, value);
    emit(state.copyWith(needCleanCache: value));
  }

  void resetNeedCleanCache() {
    _box.delete(GlobalSettingBoxKey.needCleanCache);
    emit(state.copyWith(needCleanCache: _defaults.needCleanCache));
  }

  void updateComicChoice(int value) {
    _box.put(GlobalSettingBoxKey.comicChoice, value);
    emit(state.copyWith(comicChoice: value));
  }

  void resetComicChoice() {
    _box.delete(GlobalSettingBoxKey.comicChoice);
    emit(state.copyWith(comicChoice: _defaults.comicChoice));
  }

  void updateDisableBika(bool value) {
    _box.put(GlobalSettingBoxKey.disableBika, value);
    emit(state.copyWith(disableBika: value));
  }

  void resetDisableBika() {
    _box.delete(GlobalSettingBoxKey.disableBika);
    emit(state.copyWith(disableBika: _defaults.disableBika));
  }

  void updateEnableMemoryDebug(bool value) {
    _box.put(GlobalSettingBoxKey.enableMemoryDebug, value);
    emit(state.copyWith(enableMemoryDebug: value));
  }

  void resetEnableMemoryDebug() {
    _box.delete(GlobalSettingBoxKey.enableMemoryDebug);
    emit(state.copyWith(enableMemoryDebug: _defaults.enableMemoryDebug));
  }
}

class GlobalSettingBoxKey {
  static const String globalSetting = 'globalSetting';
  static const String dynamicColor = 'dynamicColor'; // 是否开启动态颜色
  static const String themeMode = 'themeMode1'; // 主题模式
  static const String isAMOLED = 'isAMOLED'; // 是否是AMOLED屏幕
  static const String seedColor = 'seedColor'; // 种子颜色
  static const String themeInitState = 'themeInitState'; // 主题初始状态
  static const String locale = 'locale'; // 语言
  static const String welcomePageNum = 'welcomePageNum'; // 开屏页序号
  static const String webdavHost = 'webdavHost'; // webdav地址
  static const String webdavUsername = 'webdavUsername'; // webdav用户名
  static const String webdavPassword = 'webdavPassword'; // webdav密码
  static const String autoSync = 'autoSync'; // 是否自动同步
  static const String syncNotify = 'syncNotify'; // 自动同步提醒
  static const String shade = 'shade'; // 黑夜模式遮罩
  static const String comicReadTopContainer =
      'comicReadTopContainer'; // 漫画阅读器顶部占位容器
  static const String readMode = "readMode"; // 阅读模式
  static const String maskedKeywords = 'maskedKeywords'; // 屏蔽关键词
  static const String socks5Proxy = 'socks5Proxy'; // socks5代理
  static const String needCleanCache = 'needCleanCache'; // 是否需要清理缓存
  static const String comicChoice = 'comicChoice'; // 漫画选择
  static const String disableBika = 'disableBika'; // 禁用哔咔
  static const String enableMemoryDebug = 'enableMemoryDebug'; // 是否启用内存调试
}
