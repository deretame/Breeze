// 全局设置

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'global_setting.g.dart';

// ignore: library_private_types_in_public_api
class GlobalSetting = _GlobalSetting with _$GlobalSetting;

abstract class _GlobalSetting with Store {
  late final Box<dynamic> _box;

  @observable
  bool dynamicColor = true; // 是否开启动态颜色
  @observable
  int themeColor = 0xFF4CAF50; // 主题颜色
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
  dynamic locale = Locale('en', 'US'); // 语言
  @observable
  bool doubleReturn = true; // 双击返回键退出应用
  @observable
  int welcomePageNum = 0; // 开屏页序号
  @observable
  bool permissionDenied = false; // 权限拒绝

  // _GlobalSetting() {
  //   _initBox();
  // }

  Future<void> initBox() async {
    _box = await Hive.openBox(GlobalSettingBoxKey.globalSetting);
    dynamicColor = getDynamicColor();
    themeColor = getThemeColor();
    themeMode = getThemeMode();
    themeType = getThemeType();
    isAMOLED = getIsAMOLED();
    seedColor = getSeedColor();
    backgroundColor = getBackgroundColor();
    textColor = getTextColor();
    themeInitState = getThemeInitState();
    locale = getLocale();
    doubleReturn = getDoubleReturn();
    welcomePageNum = getWelcomePageNum();
    permissionDenied = getPermissionDenied();
  }

  @action
  bool getDynamicColor() {
    dynamicColor =
        _box.get(GlobalSettingBoxKey.dynamicColor, defaultValue: true);
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
  int getThemeColor() {
    themeColor =
        _box.get(GlobalSettingBoxKey.themeColor, defaultValue: 0xFF4CAF50);
    return themeColor;
  }

  @action
  void setThemeColor(int value) {
    themeColor = value;
    _box.put(GlobalSettingBoxKey.themeColor, value);
  }

  @action
  void deleteThemeColor() {
    themeColor = 0xFF4CAF50;
    _box.delete(GlobalSettingBoxKey.themeColor);
  }

  @action
  ThemeMode getThemeMode() {
    final themeModeIndex = _box.get(GlobalSettingBoxKey.themeMode,
        defaultValue: ThemeMode.system.index); // 确保这里获取的是 int 类型
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
    seedColor = _box.get(GlobalSettingBoxKey.seedColor,
        defaultValue: Colors.blue[400]!);
    return seedColor;
  }

  @action
  void setSeedColor(Color value) {
    seedColor = value;
    _box.put(GlobalSettingBoxKey.seedColor, value);
  }

  @action
  void deleteSeedColor() {
    seedColor = Colors.blue[400]!;
    _box.delete(GlobalSettingBoxKey.seedColor);
  }

  @action
  Color getBackgroundColor() {
    backgroundColor = _box.get(GlobalSettingBoxKey.backgroundColor,
        defaultValue: Colors.white);
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
    textColor =
        _box.get(GlobalSettingBoxKey.textColor, defaultValue: Colors.black);
    return textColor;
  }

  @action
  void setTextColor(Color value) {
    textColor = value;
    _box.put(GlobalSettingBoxKey.textColor, value);
  }

  @action
  void deleteTextColor() {
    textColor =
        _box.get(GlobalSettingBoxKey.textColor, defaultValue: Colors.black);
    _box.delete(GlobalSettingBoxKey.textColor);
  }

  @action
  int getThemeInitState() {
    themeInitState =
        _box.get(GlobalSettingBoxKey.themeInitState, defaultValue: 0);
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
    locale =
        _box.get(GlobalSettingBoxKey.locale, defaultValue: Locale('zh', 'CN'));
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
  bool getDoubleReturn() {
    doubleReturn =
        _box.get(GlobalSettingBoxKey.doubleReturn, defaultValue: true);
    return doubleReturn;
  }

  @action
  void setDoubleReturn(bool value) {
    doubleReturn = value;
    _box.put(GlobalSettingBoxKey.doubleReturn, value);
  }

  @action
  void deleteDoubleReturn() {
    doubleReturn = true;
    _box.delete(GlobalSettingBoxKey.doubleReturn);
  }

  @action
  int getWelcomePageNum() {
    welcomePageNum =
        _box.get(GlobalSettingBoxKey.welcomePageNum, defaultValue: 0);
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
  bool getPermissionDenied() {
    permissionDenied =
        _box.get(GlobalSettingBoxKey.permissionDenied, defaultValue: false);
    return permissionDenied;
  }

  @action
  void setPermissionDenied(bool value) {
    permissionDenied = value;
    _box.put(GlobalSettingBoxKey.permissionDenied, value);
  }

  @action
  void deletePermissionDenied() {
    permissionDenied = false;
    _box.delete(GlobalSettingBoxKey.permissionDenied);
  }
}

class GlobalSettingBoxKey {
  static const String globalSetting = 'globalSetting';
  static const String dynamicColor = 'dynamicColor'; // 是否开启动态颜色
  static const String themeColor = 'themeColor'; // 主题颜色
  static const String themeMode = 'themeMode1'; // 主题模式
  static const String themeType = 'themeType'; // 是否是浅色主题
  static const String isAMOLED = 'isAMOLED'; // 是否是AMOLED屏幕
  static const String seedColor = 'seedColor'; // 种子颜色
  static const String themeInitState = 'themeInitState'; // 主题初始状态
  static const String locale = 'locale'; // 语言
  static const String backgroundColor = 'backgroundColor'; // 背景颜色
  static const String textColor = 'textColor'; // 文字颜色
  static const String doubleReturn = 'doubleReturn'; // 双击返回键退出应用
  static const String welcomePageNum = 'welcomePageNum'; // 开屏页序号
  static const String permissionDenied = 'permissionDenied'; // 权限拒绝
}
