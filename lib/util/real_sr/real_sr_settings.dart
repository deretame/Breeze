import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/real_sr/android_ncnn_model_config.dart';
import 'package:zephyr/util/coreml_model_config.dart';

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
  static const _keyCoreMLFamily = 'realsr_coreml_family';
  static const _keyCoreMLVariant = 'realsr_coreml_variant';
  static const _keyAndroidNcnnMode = 'realsr_android_ncnn_mode';
  static const _keyAndroidNcnnNoise = 'realsr_android_ncnn_noise';
  static const _keyDesktopNcnnMode = 'realsr_desktop_ncnn_mode';
  static const _keyDesktopNcnnNoise = 'realsr_desktop_ncnn_noise';

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

  /// iOS / macOS 使用的 CoreML 模型族，默认 waifu2x（速度优先）。
  static Future<CoreMLModelFamily> loadCoreMLFamily() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_keyCoreMLFamily);
    return CoreMLModelConfig.familyById(id ?? '') ??
        CoreMLModelConfig.defaultFamily;
  }

  static Future<void> saveCoreMLFamily(CoreMLModelFamily value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCoreMLFamily, value.id);
  }

  /// iOS / macOS 使用的 CoreML 模型变体。
  ///
  /// 如果保存的变体不在当前族中，自动回退到该族第一个变体。
  static Future<CoreMLModelVariant> loadCoreMLVariant(
    CoreMLModelFamily family,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final fileName = prefs.getString(_keyCoreMLVariant);
    return CoreMLModelConfig.variantByFileName(family, fileName ?? '') ??
        family.variants.first;
  }

  static Future<void> saveCoreMLVariant(CoreMLModelVariant value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCoreMLVariant, value.fileName);
  }

  /// Android 使用的 NCNN 超分模式，默认效率优先（waifu2x）。
  static Future<AndroidNcnnMode> loadAndroidNcnnMode() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyAndroidNcnnMode);
    return AndroidNcnnMode.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AndroidNcnnModelConfig.defaultMode,
    );
  }

  static Future<void> saveAndroidNcnnMode(AndroidNcnnMode value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAndroidNcnnMode, value.name);
  }

  /// Android 使用的 NCNN 降噪档位，默认无降噪（适合漫画）。
  static Future<AndroidNcnnNoise> loadAndroidNcnnNoise() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyAndroidNcnnNoise);
    return AndroidNcnnNoise.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AndroidNcnnModelConfig.defaultNoise,
    );
  }

  static Future<void> saveAndroidNcnnNoise(AndroidNcnnNoise value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAndroidNcnnNoise, value.name);
  }

  /// 桌面端（Windows / Linux）使用的 NCNN 超分模式。
  static Future<AndroidNcnnMode> loadDesktopNcnnMode() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyDesktopNcnnMode);
    return AndroidNcnnMode.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AndroidNcnnModelConfig.defaultMode,
    );
  }

  static Future<void> saveDesktopNcnnMode(AndroidNcnnMode value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDesktopNcnnMode, value.name);
  }

  /// 桌面端（Windows / Linux）使用的 NCNN 降噪档位。
  static Future<AndroidNcnnNoise> loadDesktopNcnnNoise() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyDesktopNcnnNoise);
    return AndroidNcnnNoise.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AndroidNcnnModelConfig.defaultNoise,
    );
  }

  static Future<void> saveDesktopNcnnNoise(AndroidNcnnNoise value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDesktopNcnnNoise, value.name);
  }
}
