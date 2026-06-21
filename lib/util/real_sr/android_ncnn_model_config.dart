/// Android NCNN 超分模式。
///
/// 不直接暴露底层模型名给用户，只提供「效率优先」和「质量优先」两种策略：
/// - 效率优先：waifu2x，速度更快
/// - 质量优先：Real-CUGAN，画质更好
enum AndroidNcnnMode {
  efficiency('效率优先'),
  quality('质量优先');

  final String label;

  const AndroidNcnnMode(this.label);
}

/// Android NCNN 降噪档位。
///
/// 直接对应底层模型的 `-n` 参数：
/// - `noiseConservative` / `-1`：保守降噪（Real-CUGAN 专用）
/// - `noise0` / `0`：无降噪，适合干净漫画
/// - `noise1` / `1`：轻度降噪
/// - `noise2` / `2`：中度降噪
/// - `noise3` / `3`：强力降噪
enum AndroidNcnnNoise {
  noiseConservative(-1, '保守'),
  noise0(0, '无降噪'),
  noise1(1, '降噪 1'),
  noise2(2, '降噪 2'),
  noise3(3, '降噪 3');

  final int noise;
  final String label;

  const AndroidNcnnNoise(this.noise, this.label);
}

class NcnnModelVariant {
  final String displayName;

  /// 模型目录名，解压后位于 `<modelRoot>/<modelDir>`。
  final String modelDir;

  /// 降噪级别，对应 CLI 的 `-n` 参数。
  final int noise;

  /// 放大倍率，对应 CLI 的 `-s` 参数。
  final int scale;

  const NcnnModelVariant({
    required this.displayName,
    required this.modelDir,
    required this.noise,
    required this.scale,
  });
}

abstract class AndroidNcnnModelConfig {
  AndroidNcnnModelConfig._();

  /// 默认使用效率优先（waifu2x）。
  static const AndroidNcnnMode defaultMode = AndroidNcnnMode.efficiency;

  /// 默认降噪级别。
  ///
  /// 漫画图片通常比较干净，默认使用无降噪档位：
  /// - 效率优先使用 waifu2x upconv，固定无降噪
  /// - Real-CUGAN models-pro no-denoise 同样适合干净漫画
  static const AndroidNcnnNoise defaultNoise = AndroidNcnnNoise.noise0;

  /// 当前支持的降噪档位数值。
  static const List<int> noiseLevels = [-1, 0, 1, 2, 3];

  /// 根据 [mode] 和 [noise] 返回对应的模型变体。
  static NcnnModelVariant variantFor({
    required AndroidNcnnMode mode,
    required AndroidNcnnNoise noise,
  }) {
    final noiseValue = noise.noise;
    if (mode == AndroidNcnnMode.efficiency) {
      // 效率优先使用 waifu2x upconv 动漫模型，速度最快且适合漫画。
      // upconv 只有无降噪的 scale2.0x 模型，因此忽略传入的降噪档位。
      return const NcnnModelVariant(
        displayName: 'waifu2x upconv 动漫',
        modelDir: 'models-upconv_7_anime_style_art_rgb',
        noise: -1,
        scale: 2,
      );
    }

    // 质量优先使用 Real-CUGAN。
    // models-pro 只有 conservative/no-denoise/denoise3x，denoise1x/2x 在 models-se 中。
    final modelDir = (noiseValue == 1 || noiseValue == 2)
        ? 'models-se'
        : 'models-pro';
    return NcnnModelVariant(
      displayName: 'Real-CUGAN 降噪 $noiseValue',
      modelDir: modelDir,
      noise: noiseValue,
      scale: 2,
    );
  }
}
