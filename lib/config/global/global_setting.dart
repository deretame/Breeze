// 全局设置

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
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
    final temp = state.copyWith(dynamicColor: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetDynamicColor() {
    _box.delete(GlobalSettingBoxKey.dynamicColor);
    final temp = state.copyWith(dynamicColor: _defaults.dynamicColor);
    updateDataBase(temp);
    emit(temp);
  }

  void updateThemeMode(ThemeMode value) {
    _box.put(GlobalSettingBoxKey.themeMode, value.index);
    final temp = state.copyWith(themeMode: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetThemeMode() {
    _box.delete(GlobalSettingBoxKey.themeMode);
    final temp = state.copyWith(themeMode: _defaults.themeMode);
    updateDataBase(temp);
    emit(temp);
  }

  void updateIsAMOLED(bool value) {
    _box.put(GlobalSettingBoxKey.isAMOLED, value);
    final temp = state.copyWith(isAMOLED: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetIsAMOLED() {
    _box.delete(GlobalSettingBoxKey.isAMOLED);
    final temp = state.copyWith(isAMOLED: _defaults.isAMOLED);
    updateDataBase(temp);
    emit(temp);
  }

  void updateSeedColor(Color value) {
    _box.put(GlobalSettingBoxKey.seedColor, value);
    final temp = state.copyWith(seedColor: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetSeedColor() {
    _box.delete(GlobalSettingBoxKey.seedColor);
    final temp = state.copyWith(seedColor: _defaultSeedColor);
    updateDataBase(temp);
    emit(temp);
  }

  void updateThemeInitState(int value) {
    _box.put(GlobalSettingBoxKey.themeInitState, value);
    final temp = state.copyWith(themeInitState: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetThemeInitState() {
    _box.delete(GlobalSettingBoxKey.themeInitState);
    final temp = state.copyWith(themeInitState: _defaults.themeInitState);
    updateDataBase(temp);
    emit(temp);
  }

  void updateLocale(Locale value) {
    _box.put(GlobalSettingBoxKey.locale, value);
    final temp = state.copyWith(locale: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetLocale() {
    _box.delete(GlobalSettingBoxKey.locale);
    final temp = state.copyWith(locale: _defaults.locale);
    updateDataBase(temp);
    emit(temp);
  }

  void updateWelcomePageNum(int value) {
    _box.put(GlobalSettingBoxKey.welcomePageNum, value);
    final temp = state.copyWith(welcomePageNum: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetWelcomePageNum() {
    _box.delete(GlobalSettingBoxKey.welcomePageNum);
    final temp = state.copyWith(welcomePageNum: _defaults.welcomePageNum);
    updateDataBase(temp);
    emit(temp);
  }

  void updateWebdavHost(String value) {
    _box.put(GlobalSettingBoxKey.webdavHost, value);
    final temp = state.copyWith(webdavHost: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetWebdavHost() {
    _box.delete(GlobalSettingBoxKey.webdavHost);
    final temp = state.copyWith(webdavHost: _defaults.webdavHost);
    updateDataBase(temp);
    emit(temp);
  }

  void updateWebdavUsername(String value) {
    _box.put(GlobalSettingBoxKey.webdavUsername, value);
    final temp = state.copyWith(webdavUsername: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetWebdavUsername() {
    _box.delete(GlobalSettingBoxKey.webdavUsername);
    final temp = state.copyWith(webdavUsername: _defaults.webdavUsername);
    updateDataBase(temp);
    emit(temp);
  }

  void updateWebdavPassword(String value) {
    _box.put(GlobalSettingBoxKey.webdavPassword, value);
    final temp = state.copyWith(webdavPassword: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetWebdavPassword() {
    _box.delete(GlobalSettingBoxKey.webdavPassword);
    final temp = state.copyWith(webdavPassword: _defaults.webdavPassword);
    updateDataBase(temp);
    emit(temp);
  }

  void updateAutoSync(bool value) {
    _box.put(GlobalSettingBoxKey.autoSync, value);
    final temp = state.copyWith(autoSync: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetAutoSync() {
    _box.delete(GlobalSettingBoxKey.autoSync);
    final temp = state.copyWith(autoSync: _defaults.autoSync);
    updateDataBase(temp);
    emit(temp);
  }

  void updateSyncNotify(bool value) {
    _box.put(GlobalSettingBoxKey.syncNotify, value);
    final temp = state.copyWith(syncNotify: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetSyncNotify() {
    _box.delete(GlobalSettingBoxKey.syncNotify);
    final temp = state.copyWith(syncNotify: _defaults.syncNotify);
    updateDataBase(temp);
    emit(temp);
  }

  void updateShade(bool value) {
    _box.put(GlobalSettingBoxKey.shade, value);
    final temp = state.copyWith(shade: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetShade() {
    _box.delete(GlobalSettingBoxKey.shade);
    final temp = state.copyWith(shade: _defaults.shade);
    updateDataBase(temp);
    emit(temp);
  }

  void updateComicReadTopContainer(bool value) {
    _box.put(GlobalSettingBoxKey.comicReadTopContainer, value);
    final temp = state.copyWith(comicReadTopContainer: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetComicReadTopContainer() {
    _box.delete(GlobalSettingBoxKey.comicReadTopContainer);
    final temp = state.copyWith(
      comicReadTopContainer: _defaults.comicReadTopContainer,
    );
    updateDataBase(temp);
    emit(temp);
  }

  void updateReadMode(int value) {
    _box.put(GlobalSettingBoxKey.readMode, value);
    final temp = state.copyWith(readMode: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetReadMode() {
    _box.delete(GlobalSettingBoxKey.readMode);
    final temp = state.copyWith(readMode: _defaults.readMode);
    updateDataBase(temp);
    emit(temp);
  }

  void updateMaskedKeywords(List<String> value) {
    _box.put(GlobalSettingBoxKey.maskedKeywords, value);
    final temp = state.copyWith(maskedKeywords: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetMaskedKeywords() {
    _box.delete(GlobalSettingBoxKey.maskedKeywords);
    final temp = state.copyWith(maskedKeywords: _defaults.maskedKeywords);
    updateDataBase(temp);
    emit(temp);
  }

  void updateSocks5Proxy(String value) {
    _box.put(GlobalSettingBoxKey.socks5Proxy, value);
    final temp = state.copyWith(socks5Proxy: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetSocks5Proxy() {
    _box.delete(GlobalSettingBoxKey.socks5Proxy);
    final temp = state.copyWith(socks5Proxy: _defaults.socks5Proxy);
    updateDataBase(temp);
    emit(temp);
  }

  void updateNeedCleanCache(bool value) {
    _box.put(GlobalSettingBoxKey.needCleanCache, value);
    final temp = state.copyWith(needCleanCache: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetNeedCleanCache() {
    _box.delete(GlobalSettingBoxKey.needCleanCache);
    final temp = state.copyWith(needCleanCache: _defaults.needCleanCache);
    updateDataBase(temp);
    emit(temp);
  }

  void updateComicChoice(int value) {
    _box.put(GlobalSettingBoxKey.comicChoice, value);
    final temp = state.copyWith(comicChoice: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetComicChoice() {
    _box.delete(GlobalSettingBoxKey.comicChoice);
    final temp = state.copyWith(comicChoice: _defaults.comicChoice);
    updateDataBase(temp);
    emit(temp);
  }

  void updateDisableBika(bool value) {
    _box.put(GlobalSettingBoxKey.disableBika, value);
    final temp = state.copyWith(disableBika: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetDisableBika() {
    _box.delete(GlobalSettingBoxKey.disableBika);
    final temp = state.copyWith(disableBika: _defaults.disableBika);
    updateDataBase(temp);
    emit(temp);
  }

  void updateEnableMemoryDebug(bool value) {
    _box.put(GlobalSettingBoxKey.enableMemoryDebug, value);
    final temp = state.copyWith(enableMemoryDebug: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetEnableMemoryDebug() {
    _box.delete(GlobalSettingBoxKey.enableMemoryDebug);
    final temp = state.copyWith(enableMemoryDebug: _defaults.enableMemoryDebug);
    updateDataBase(temp);
    emit(temp);
  }

  void updateDataBase(GlobalSettingState state) {
    final userBox = objectbox.userSettingBox;
    var dbSettings = userBox.get(1)!;
    dbSettings.globalSetting = state;
    userBox.put(dbSettings);
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
