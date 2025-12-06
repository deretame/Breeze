import 'package:flutter/material.dart'; // 需要导入 Locale 和 ThemeMode
import 'package:hive_ce/hive.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
// 1. 导入你所有的 BoxKey 定义文件
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/jm/jm_setting.dart';

/// 一个简单的工具类，用于在没有 BuildContext 时直接从 Hive 读取设置的 *初始* 值。
///
/// **警告:**
/// - **仅用于读取**：不要用这个类写入 Hive，请使用对应的 Cubit 方法。
/// - **仅用于初始化**：主要用于 `initState`。在 `build` 方法中，请使用 `context.watch` 或 `context.read` 来获取响应式状态。
/// - **假设 Box 已打开**：这个类假设所有相关的 Hive Box 已经在 `main()` 函数中被 `Hive.openBox()` 打开。
class SettingsHiveUtils {
  // 私有构造函数，防止实例化
  SettingsHiveUtils._();

  // --- Global Setting Getters ---

  static Box<dynamic> get _globalBox =>
      Hive.box(GlobalSettingBoxKey.globalSetting);

  static bool get dynamicColor =>
      _globalBox.get(GlobalSettingBoxKey.dynamicColor, defaultValue: true);
  static ThemeMode get themeMode {
    final index = _globalBox.get(
      GlobalSettingBoxKey.themeMode,
      defaultValue: ThemeMode.system.index,
    );
    // 安全转换，防止索引越界
    return index >= 0 && index < ThemeMode.values.length
        ? ThemeMode.values[index]
        : ThemeMode.system;
  }

  static bool get isAMOLED =>
      _globalBox.get(GlobalSettingBoxKey.isAMOLED, defaultValue: true);
  // 注意：seedColor 的动态默认值无法在这里处理，这里只能用 freezed 里的 const 默认值
  static Color get seedColor => _globalBox.get(
    GlobalSettingBoxKey.seedColor,
    defaultValue: const Color(0xFFEF5350),
  );
  static int get themeInitState =>
      _globalBox.get(GlobalSettingBoxKey.themeInitState, defaultValue: 0);
  static Locale get locale => _globalBox.get(
    GlobalSettingBoxKey.locale,
    defaultValue: const Locale('zh', 'CN'),
  );
  static int get welcomePageNum =>
      _globalBox.get(GlobalSettingBoxKey.welcomePageNum, defaultValue: 0);
  static String get webdavHost =>
      _globalBox.get(GlobalSettingBoxKey.webdavHost, defaultValue: '');
  static String get webdavUsername =>
      _globalBox.get(GlobalSettingBoxKey.webdavUsername, defaultValue: '');
  static String get webdavPassword =>
      _globalBox.get(GlobalSettingBoxKey.webdavPassword, defaultValue: '');
  static bool get autoSync =>
      _globalBox.get(GlobalSettingBoxKey.autoSync, defaultValue: true);
  static bool get syncNotify =>
      _globalBox.get(GlobalSettingBoxKey.syncNotify, defaultValue: true);
  static bool get shade =>
      _globalBox.get(GlobalSettingBoxKey.shade, defaultValue: true);
  static bool get comicReadTopContainer => _globalBox.get(
    GlobalSettingBoxKey.comicReadTopContainer,
    defaultValue: true,
  );
  static int get readMode =>
      _globalBox.get(GlobalSettingBoxKey.readMode, defaultValue: 0);
  static List<String> get maskedKeywords => _globalBox.get(
    GlobalSettingBoxKey.maskedKeywords,
    defaultValue: const [""],
  );
  static String get socks5Proxy =>
      _globalBox.get(GlobalSettingBoxKey.socks5Proxy, defaultValue: '');
  static bool get needCleanCache =>
      _globalBox.get(GlobalSettingBoxKey.needCleanCache, defaultValue: false);
  static int get comicChoice =>
      _globalBox.get(GlobalSettingBoxKey.comicChoice, defaultValue: 1);
  static bool get disableBika =>
      _globalBox.get(GlobalSettingBoxKey.disableBika, defaultValue: false);
  static bool get enableMemoryDebug => _globalBox.get(
    GlobalSettingBoxKey.enableMemoryDebug,
    defaultValue: false,
  );

  // --- JM Setting Getters ---

  static Box<dynamic> get _jmBox => Hive.box(JmSettingBoxKeys.jmSettingBox);

  static String get jmAccount =>
      _jmBox.get(JmSettingBoxKeys.account, defaultValue: '');
  static String get jmPassword =>
      _jmBox.get(JmSettingBoxKeys.password, defaultValue: '');
  // 注意：userInfo 和 loginStatus 不是持久化的，不能从 Hive 获取

  // --- Bika Setting Getters ---

  static Box<dynamic> get _bikaBox =>
      Hive.box(BikaSettingBoxKeys.bikaSettingBox);

  static String get bikaAccount =>
      _bikaBox.get(BikaSettingBoxKeys.account, defaultValue: '');
  static String get bikaPassword =>
      _bikaBox.get(BikaSettingBoxKeys.password, defaultValue: '');
  static String get bikaAuthorization =>
      _bikaBox.get(BikaSettingBoxKeys.authorization, defaultValue: '');
  static int get bikaLevel =>
      _bikaBox.get(BikaSettingBoxKeys.level, defaultValue: 0);
  static bool get bikaCheckIn =>
      _bikaBox.get(BikaSettingBoxKeys.checkIn, defaultValue: false);
  static int get bikaProxy =>
      _bikaBox.get(BikaSettingBoxKeys.proxy, defaultValue: 3);
  static String get bikaImageQuality =>
      _bikaBox.get(BikaSettingBoxKeys.imageQuality, defaultValue: 'original');
  static Map<String, bool> get bikaShieldCategoryMap {
    final dynamic map = _bikaBox.get(
      BikaSettingBoxKeys.shieldCategoryMap,
      defaultValue: Map.of(categoryMap),
    );
    // 需要手动转换类型
    return Map<String, bool>.from(map);
  }

  static Map<String, bool> get bikaShieldHomePageCategoriesMap {
    final dynamic map = _bikaBox.get(
      BikaSettingBoxKeys.shieldHomePageCategories,
      defaultValue: Map.of(homePageCategoriesMap),
    );
    // 需要手动转换类型
    return Map<String, bool>.from(map);
  }

  static bool get bikaSignIn =>
      _bikaBox.get(BikaSettingBoxKeys.signIn, defaultValue: false);
  static bool get bikaBrevity =>
      _bikaBox.get(BikaSettingBoxKeys.brevity, defaultValue: false);
  static bool get bikaSlowDownload =>
      _bikaBox.get(BikaSettingBoxKeys.slowDownload, defaultValue: false);
}
