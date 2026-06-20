import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// iOS / macOS CoreML 超分模型配置。
///
/// 模型文件来自 GitHub `deretame/breeze-binary` 的 `MacOS-iOS.7z`，
/// 目前压缩包里实际只有以下两个变体：
/// - waifu2x_photo_noise0_scale2x.mlmodel
/// - RealCUGAN_2x_no-denoise_block156.mlpackage
/// 后续上传更多变体后，直接往对应族里追加即可。
class CoreMLModelFamily {
  final String id;
  final String label;
  final List<CoreMLModelVariant> variants;

  const CoreMLModelFamily({
    required this.id,
    required this.label,
    required this.variants,
  });
}

class CoreMLModelVariant {
  final String displayName;
  final String fileName;
  final Map<String, dynamic> config;

  const CoreMLModelVariant({
    required this.displayName,
    required this.fileName,
    required this.config,
  });
}

abstract class CoreMLModelConfig {
  CoreMLModelConfig._();

  static const String archiveName = 'MacOS-iOS.7z';
  static const String archiveSubDir = 'MacOS-iOS';
  static const String binaryRepoBaseUrl =
      'https://github.com/deretame/breeze-binary/raw/main';

  static const List<CoreMLModelFamily> families = <CoreMLModelFamily>[
    CoreMLModelFamily(
      id: 'waifu2x',
      label: '速度优先 (waifu2x)',
      variants: <CoreMLModelVariant>[
        CoreMLModelVariant(
          displayName: '降噪 0',
          fileName: 'waifu2x_photo_noise0_scale2x.mlmodel',
          config: <String, dynamic>{
            'inputName': 'input',
            'outputName': 'output',
            'blockSize': 156,
            'shrinkSize': 7,
            'scale': 2,
          },
        ),
      ],
    ),
    CoreMLModelFamily(
      id: 'realcugan',
      label: '质量优先 (Real-CUGAN)',
      variants: <CoreMLModelVariant>[
        CoreMLModelVariant(
          displayName: '无降噪',
          fileName: 'RealCUGAN_2x_no-denoise_block156.mlpackage',
          config: <String, dynamic>{
            'inputName': 'input',
            'outputName': 'output',
            'blockSize': 192,
            'shrinkSize': 18,
            'scale': 2,
          },
        ),
      ],
    ),
  ];

  static CoreMLModelFamily get defaultFamily => families.first;

  static CoreMLModelVariant get defaultVariant => defaultFamily.variants.first;

  static CoreMLModelFamily? familyById(String id) {
    for (final family in families) {
      if (family.id == id) return family;
    }
    return null;
  }

  static CoreMLModelVariant? variantByFileName(
    CoreMLModelFamily family,
    String fileName,
  ) {
    for (final variant in family.variants) {
      if (variant.fileName == fileName) return variant;
    }
    return null;
  }

  /// 内容块尺寸 = 模型输入尺寸 - 2×反射边距。
  static int contentBlockSize(CoreMLModelVariant variant) {
    final blockSize = variant.config['blockSize'] as int? ?? 0;
    final shrinkSize = variant.config['shrinkSize'] as int? ?? 0;
    return blockSize - 2 * shrinkSize;
  }

  /// 返回解压后模型根目录。
  static Future<Directory> get modelsDirectory async {
    final tempDir = await getTemporaryDirectory();
    return Directory(p.join(tempDir.path, 'coreml_models', archiveSubDir));
  }
}
