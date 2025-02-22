// 全局设置

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

import 'color_theme_types.dart';

part 'global_setting.g.dart';

// ignore: library_private_types_in_public_api
class GlobalSetting = _GlobalSetting with _$GlobalSetting;

abstract class _GlobalSetting with Store {
  late final Box<dynamic> _box;

  @observable
  bool dynamicColor = true; // 是否开启动态颜色
  @observable
  ThemeMode themeMode = ThemeMode.system; // 主题模式
  @observable
  bool themeType = true; // 是否是浅色主题
  @observable
  bool isAMOLED = true; // 是否是AMOLED屏幕
  @observable
  Color seedColor = Colors.red[400]!; // 种子颜色
  @observable
  Color backgroundColor = Colors.white; // 背景颜色
  @observable
  Color textColor = Colors.black; // 文字颜色
  @observable
  int themeInitState = 0; // 主题初始状态
  @observable
  dynamic locale = Locale('zh', 'CN'); // 语言
  @observable
  int welcomePageNum = 0; // 开屏页序号
  @observable
  String webdavHost = ''; // webdav地址
  @observable
  String webdavUsername = ''; // webdav用户名
  @observable
  String webdavPassword = ''; // webdav密码
  @observable
  bool autoSync = true; // 是否自动同步
  @observable
  bool syncNotify = true; // 同步提示
  @observable
  bool shade = true; // 夜间模式遮罩
  @observable
  bool comicReadTopContainer = true; // 漫画阅读器顶部占位容器

  Future<void> initBox() async {
    _box = await Hive.openBox(GlobalSettingBoxKey.globalSetting);
    dynamicColor = getDynamicColor();
    themeMode = getThemeMode();
    themeType = getThemeType();
    isAMOLED = getIsAMOLED();
    seedColor = getSeedColor();
    backgroundColor = getBackgroundColor();
    textColor = getTextColor();
    themeInitState = getThemeInitState();
    locale = getLocale();
    welcomePageNum = getWelcomePageNum();
    webdavHost = getWebdavHost();
    webdavUsername = getWebdavUsername();
    webdavPassword = getWebdavPassword();
    autoSync = getAutoSync();
    syncNotify = getSyncNotify();
    shade = getShade();
    comicReadTopContainer = getComicReadTopContainer();
  }

  @action
  bool getDynamicColor() {
    dynamicColor = _box.get(
      GlobalSettingBoxKey.dynamicColor,
      defaultValue: true,
    );
    return dynamicColor;
  }

  @action
  void setDynamicColor(bool value) {
    dynamicColor = value;
    _box.put(GlobalSettingBoxKey.dynamicColor, value);
  }

  @action
  void deleteDynamicColor() {
    dynamicColor = true;
    _box.delete(GlobalSettingBoxKey.dynamicColor);
  }

  @action
  ThemeMode getThemeMode() {
    final themeModeIndex = _box.get(
      GlobalSettingBoxKey.themeMode,
      defaultValue: ThemeMode.system.index,
    ); // 确保这里获取的是 int 类型
    themeMode = ThemeMode.values[themeModeIndex]; // 转换为 ThemeMode
    return themeMode;
  }

  @action
  void setThemeMode(int value) {
    themeMode = ThemeMode.values[value]; // 根据索引设置 ThemeMode
    _box.put(GlobalSettingBoxKey.themeMode, value); // 存储 int 值
  }

  @action
  void deleteThemeMode() {
    themeMode = ThemeMode.system;
    _box.delete(GlobalSettingBoxKey.themeMode);
  }

  @action
  bool getThemeType() {
    themeType = _box.get(GlobalSettingBoxKey.themeType, defaultValue: true);
    return themeType;
  }

  @action
  void setThemeType(bool value) {
    themeType = value;
    _box.put(GlobalSettingBoxKey.themeType, value);
  }

  @action
  void deleteThemeType() {
    themeType = true;
    _box.delete(GlobalSettingBoxKey.themeType);
  }

  @action
  bool getIsAMOLED() {
    isAMOLED = _box.get(GlobalSettingBoxKey.isAMOLED, defaultValue: true);
    return isAMOLED;
  }

  @action
  void setIsAMOLED(bool value) {
    isAMOLED = value;
    _box.put(GlobalSettingBoxKey.isAMOLED, value);
  }

  @action
  void deleteIsAMOLED() {
    isAMOLED = true;
    _box.delete(GlobalSettingBoxKey.isAMOLED);
  }

  @action
  Color getSeedColor() {
    seedColor = _box.get(
      GlobalSettingBoxKey.seedColor,
      defaultValue: colorThemeList[6].color,
    );
    return seedColor;
  }

  @action
  void setSeedColor(Color value) {
    seedColor = value;
    _box.put(GlobalSettingBoxKey.seedColor, value);
  }

  @action
  void deleteSeedColor() {
    seedColor = _box.get(
      GlobalSettingBoxKey.seedColor,
      defaultValue: colorThemeList[6].color,
    );
    _box.delete(GlobalSettingBoxKey.seedColor);
  }

  @action
  Color getBackgroundColor() {
    backgroundColor = _box.get(
      GlobalSettingBoxKey.backgroundColor,
      defaultValue: Colors.white,
    );
    return backgroundColor;
  }

  @action
  void setBackgroundColor(Color value) {
    backgroundColor = value;
    _box.put(GlobalSettingBoxKey.backgroundColor, value);
  }

  @action
  void deleteBackgroundColor() {
    backgroundColor = Colors.white;
    _box.delete(GlobalSettingBoxKey.backgroundColor);
  }

  @action
  Color getTextColor() {
    textColor = _box.get(
      GlobalSettingBoxKey.textColor,
      defaultValue: Colors.black,
    );
    return textColor;
  }

  @action
  void setTextColor(Color value) {
    textColor = value;
    _box.put(GlobalSettingBoxKey.textColor, value);
  }

  @action
  void deleteTextColor() {
    textColor = _box.get(
      GlobalSettingBoxKey.textColor,
      defaultValue: Colors.black,
    );
    _box.delete(GlobalSettingBoxKey.textColor);
  }

  @action
  int getThemeInitState() {
    themeInitState = _box.get(
      GlobalSettingBoxKey.themeInitState,
      defaultValue: 0,
    );
    return themeInitState;
  }

  @action
  void setThemeInitState(int value) {
    themeInitState = value;
    _box.put(GlobalSettingBoxKey.themeInitState, value);
  }

  @action
  void deleteThemeInitState() {
    themeInitState = 0;
    _box.delete(GlobalSettingBoxKey.themeInitState);
  }

  @action
  dynamic getLocale() {
    locale = _box.get(
      GlobalSettingBoxKey.locale,
      defaultValue: Locale('zh', 'CN'),
    );
    return locale;
  }

  @action
  void setLocale(dynamic value) {
    locale = value;
    _box.put(GlobalSettingBoxKey.locale, value);
  }

  @action
  void deleteLocale() {
    locale = Locale('zh', 'CN');
    _box.delete(GlobalSettingBoxKey.locale);
  }

  @action
  int getWelcomePageNum() {
    welcomePageNum = _box.get(
      GlobalSettingBoxKey.welcomePageNum,
      defaultValue: 0,
    );
    return welcomePageNum;
  }

  @action
  void setWelcomePageNum(int value) {
    welcomePageNum = value;
    _box.put(GlobalSettingBoxKey.welcomePageNum, value);
  }

  @action
  void deleteWelcomePageNum() {
    welcomePageNum = 0;
    _box.delete(GlobalSettingBoxKey.welcomePageNum);
  }

  @action
  String getWebdavHost() {
    webdavHost = _box.get(GlobalSettingBoxKey.webdavHost, defaultValue: '');
    return webdavHost;
  }

  @action
  void setWebdavHost(String value) {
    webdavHost = value;
    _box.put(GlobalSettingBoxKey.webdavHost, value);
  }

  @action
  void deleteWebdavHost() {
    webdavHost = '';
    _box.delete(GlobalSettingBoxKey.webdavHost);
  }

  @action
  String getWebdavUsername() {
    webdavUsername = _box.get(
      GlobalSettingBoxKey.webdavUsername,
      defaultValue: '',
    );
    return webdavUsername;
  }

  @action
  void setWebdavUsername(String value) {
    webdavUsername = value;
    _box.put(GlobalSettingBoxKey.webdavUsername, value);
  }

  @action
  void deleteWebdavUsername() {
    webdavUsername = '';
    _box.delete(GlobalSettingBoxKey.webdavUsername);
  }

  @action
  String getWebdavPassword() {
    webdavPassword = _box.get(
      GlobalSettingBoxKey.webdavPassword,
      defaultValue: '',
    );
    return webdavPassword;
  }

  @action
  void setWebdavPassword(String value) {
    webdavPassword = value;
    _box.put(GlobalSettingBoxKey.webdavPassword, value);
  }

  @action
  void deleteWebdavPassword() {
    webdavPassword = '';
    _box.delete(GlobalSettingBoxKey.webdavPassword);
  }

  @action
  bool getAutoSync() {
    autoSync = _box.get(GlobalSettingBoxKey.autoSync, defaultValue: true);
    return autoSync;
  }

  @action
  void setAutoSync(bool value) {
    autoSync = value;
    _box.put(GlobalSettingBoxKey.autoSync, value);
  }

  @action
  void deleteAutoSync() {
    autoSync = true;
    _box.delete(GlobalSettingBoxKey.autoSync);
  }

  @action
  void setSyncNotify(bool value) {
    syncNotify = value;
    _box.put(GlobalSettingBoxKey.syncNotify, value);
  }

  @action
  bool getSyncNotify() {
    syncNotify = _box.get(GlobalSettingBoxKey.syncNotify, defaultValue: true);
    return syncNotify;
  }

  @action
  void deleteSyncNotify() {
    syncNotify = true;
    _box.delete(GlobalSettingBoxKey.syncNotify);
  }

  @action
  void setShade(bool value) {
    shade = value;
    _box.put(GlobalSettingBoxKey.shade, value);
  }

  @action
  bool getShade() {
    shade = _box.get(GlobalSettingBoxKey.shade, defaultValue: true);
    return shade;
  }

  @action
  void deleteShade() {
    shade = true;
    _box.delete(GlobalSettingBoxKey.shade);
  }

  @action
  bool getComicReadTopContainer() {
    comicReadTopContainer = _box.get(
      GlobalSettingBoxKey.comicReadTopContainer,
      defaultValue: true,
    );
    return comicReadTopContainer;
  }

  @action
  void setComicReadTopContainer(bool value) {
    comicReadTopContainer = value;
    _box.put(GlobalSettingBoxKey.comicReadTopContainer, value);
  }

  @action
  void deleteComicReadTopContainer() {
    comicReadTopContainer = true;
    _box.delete(GlobalSettingBoxKey.comicReadTopContainer);
  }
}

class GlobalSettingBoxKey {
  static const String globalSetting = 'globalSetting';
  static const String dynamicColor = 'dynamicColor'; // 是否开启动态颜色
  static const String themeMode = 'themeMode1'; // 主题模式
  static const String themeType = 'themeType'; // 是否是浅色主题
  static const String isAMOLED = 'isAMOLED'; // 是否是AMOLED屏幕
  static const String seedColor = 'seedColor'; // 种子颜色
  static const String themeInitState = 'themeInitState'; // 主题初始状态
  static const String locale = 'locale'; // 语言
  static const String backgroundColor = 'backgroundColor'; // 背景颜色
  static const String textColor = 'textColor'; // 文字颜色
  static const String welcomePageNum = 'welcomePageNum'; // 开屏页序号
  static const String webdavHost = 'webdavHost'; // webdav地址
  static const String webdavUsername = 'webdavUsername'; // webdav用户名
  static const String webdavPassword = 'webdavPassword'; // webdav密码
  static const String autoSync = 'autoSync'; // 是否自动同步
  static const String syncNotify = 'syncNotify'; // 自动同步提醒
  static const String shade = 'shade'; // 黑夜模式遮罩
  static const String comicReadTopContainer =
      'comicReadTopContainer'; // 漫画阅读器顶部占位容器
}
