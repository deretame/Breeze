import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:zephyr/type/enum.dart';

bool get _isDesktop =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

/// RealSR / Real-CUGAN 超分设置
///
/// 这些配置不进入 ObjectBox 的 [GlobalSettingState]，而是直接存在
/// SharedPreferences 中，避免把“功能开关”和“全局配置”混在一起。
class RealSrSettings {
  RealSrSettings._();

  static const _keyAutoUpscale = 'realsr_auto_upscale';
  static const _keyResolutionThreshold = 'realsr_resolution_threshold';
  static const _keyConcurrency = 'realsr_concurrency';
  static const _keyNoiseLevel = 'realsr_noise_level';
  static const _keyTileSize = 'realsr_tile_size';

  /// 根据当前运行平台返回推荐的默认并发数。
  ///
  /// - 桌面端（Windows / Linux / macOS）：2
  /// - 移动设备（Android / iOS）：1
  static int get defaultConcurrency {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return 2;
    if (Platform.isAndroid || Platform.isIOS) return 1;
    return 1;
  }

  static Future<bool> loadAutoUpscale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoUpscale) ?? false;
  }

  static Future<void> saveAutoUpscale(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoUpscale, value);
  }

  static Future<RealSrResolutionThreshold> loadResolutionThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyResolutionThreshold);
    final value = RealSrResolutionThreshold.values.firstWhere(
      (e) => e.name == name,
      orElse: () => RealSrResolutionThreshold.p720,
    );

    // 桌面端最高 2160p，移动设备最高 1080p
    const desktopMax = RealSrResolutionThreshold.p2160;
    const mobileMax = RealSrResolutionThreshold.p1080;
    final max = _isDesktop ? desktopMax : mobileMax;
    if (value.maxWidth > max.maxWidth) {
      return max;
    }

    return value;
  }

  static Future<void> saveResolutionThreshold(
    RealSrResolutionThreshold value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyResolutionThreshold, value.name);
  }

  static Future<int> loadConcurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyConcurrency) ?? defaultConcurrency;
  }

  static Future<void> saveConcurrency(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyConcurrency, value);
  }

  static Future<int> loadTileSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTileSize) ?? 256;
  }

  static Future<void> saveTileSize(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTileSize, value);
  }

  static Future<RealSrNoiseLevel> loadNoiseLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyNoiseLevel);
    return RealSrNoiseLevel.values.firstWhere(
      (e) => e.name == name,
      orElse: () => RealSrNoiseLevel.conservative,
    );
  }

  static Future<void> saveNoiseLevel(RealSrNoiseLevel value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNoiseLevel, value.name);
  }
}
