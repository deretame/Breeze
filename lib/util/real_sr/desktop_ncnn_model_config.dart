import 'dart:io';

import 'package:zephyr/util/real_sr/android_ncnn_model_config.dart';

/// 桌面端（Windows / Linux）NCNN 超分模型配置。
///
/// 语义与 Android 保持一致：
/// - 效率优先：waifu2x，速度更快
/// - 质量优先：Real-CUGAN，画质更好
abstract class DesktopNcnnModelConfig {
  DesktopNcnnModelConfig._();

  static const AndroidNcnnMode defaultMode = AndroidNcnnModelConfig.defaultMode;

  static const AndroidNcnnNoise defaultNoise =
      AndroidNcnnModelConfig.defaultNoise;

  /// 根据 [mode] 和 [noise] 返回对应的模型变体。
  ///
  /// 返回的 [NcnnModelVariant.displayName] 字段被复用为可执行文件名
  ///（`waifu2x-ncnn-vulkan` 或 `realcugan-ncnn-vulkan`），便于上层统一调用。
  static NcnnModelVariant variantFor({
    required AndroidNcnnMode mode,
    required AndroidNcnnNoise noise,
  }) {
    if (mode == AndroidNcnnMode.efficiency) {
      // 效率优先使用 waifu2x upconv 动漫模型。
      // waifu2x upconv 只有无降噪的 scale2.0x 模型，因此固定 noise 为 -1。
      return NcnnModelVariant(
        displayName: _executableNameFor(mode),
        modelDir: 'models-upconv_7_anime_style_art_rgb',
        noise: -1,
        scale: 2,
      );
    }

    // 质量优先使用 Real-CUGAN。
    // denoise1x / denoise2x 只在 models-se 中，其余在 models-pro 中。
    final noiseValue = noise.noise;
    final modelDir = (noiseValue == 1 || noiseValue == 2)
        ? 'models-se'
        : 'models-pro';
    return NcnnModelVariant(
      displayName: _executableNameFor(mode),
      modelDir: modelDir,
      noise: noiseValue,
      scale: 2,
    );
  }

  static String executableNameFor(AndroidNcnnMode mode) =>
      _executableNameFor(mode);

  static String _executableNameFor(AndroidNcnnMode mode) {
    final base = mode == AndroidNcnnMode.efficiency
        ? 'waifu2x-ncnn-vulkan'
        : 'realcugan-ncnn-vulkan';
    return Platform.isWindows ? '$base.exe' : base;
  }
}
