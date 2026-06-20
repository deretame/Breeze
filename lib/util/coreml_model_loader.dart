import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/util/coreml_model_config.dart';

/// 从 GitHub 下载并解压 iOS/macOS CoreML 超分模型。
///
/// 仓库里模型被打包成 `MacOS-iOS.7z`，下载后通过 Rust 侧的 `decompress7Z`
/// 解压到临时目录，再返回具体模型文件/目录的本地路径。
class CoreMLModelLoader {
  CoreMLModelLoader._();

  /// 返回指定模型的本地路径。
  ///
  /// [fileName] 是模型文件名，例如：
  /// - `waifu2x_photo_noise0_scale2x.mlmodel`
  /// - `RealCUGAN_2x_no-denoise_block156.mlpackage`
  ///
  /// [onProgress] 可选，会收到已下载字节数和总字节数。
  static Future<String> prepareModel(
    String fileName, {
    void Function(int received, int total)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final modelsDir = Directory(p.join(tempDir.path, 'coreml_models'));
    final extractedDir = Directory(
      p.join(modelsDir.path, CoreMLModelConfig.archiveSubDir),
    );
    final archiveFile = File(
      p.join(modelsDir.path, CoreMLModelConfig.archiveName),
    );
    final modelPath = p.join(extractedDir.path, fileName);

    // 已经存在就直接返回
    if (_modelExists(modelPath)) {
      return modelPath;
    }

    await modelsDir.create(recursive: true);

    const maxAttempts = 2;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      // 没有压缩包（或上一次下载不完整）就重新下载
      if (!archiveFile.existsSync() || attempt > 0) {
        final dio = Dio();
        final url =
            '${CoreMLModelConfig.binaryRepoBaseUrl}/${CoreMLModelConfig.archiveName}';
        logger.i('下载 CoreML 模型压缩包: $url');
        await dio.download(
          url,
          archiveFile.path,
          onReceiveProgress: (received, total) {
            if (total > 0) onProgress?.call(received, total);
          },
        );
      }

      // 清理旧解压目录，防止残留
      if (extractedDir.existsSync()) {
        await extractedDir.delete(recursive: true);
      }

      // 用 Rust 解压 7z
      logger.i('解压 CoreML 模型压缩包...');
      try {
        await decompress7Z(
          archivePath: archiveFile.path,
          destPath: modelsDir.path,
        );
        break;
      } catch (e, s) {
        logger.w('CoreML 压缩包解压失败，可能是下载不完整，准备重新下载', error: e, stackTrace: s);
        if (archiveFile.existsSync()) {
          try {
            await archiveFile.delete();
          } catch (_) {}
        }
        if (attempt == maxAttempts - 1) rethrow;
      }
    }

    // 解压完成后删除压缩包节省空间
    try {
      await archiveFile.delete();
    } catch (_) {}

    if (!_modelExists(modelPath)) {
      throw Exception('模型不存在: $modelPath');
    }

    return modelPath;
  }

  /// 检查指定模型是否已在本地（不会触发下载）。
  static Future<bool> isModelAvailable(String fileName) async {
    final dir = await CoreMLModelConfig.modelsDirectory;
    return _modelExists(p.join(dir.path, fileName));
  }

  static bool _modelExists(String path) {
    if (path.endsWith('.mlpackage')) {
      return Directory(path).existsSync();
    }
    return File(path).existsSync();
  }
}
