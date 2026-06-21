import 'dart:io';
import 'dart:ui' as ui;

import 'package:coreml_upscale/coreml_upscale.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pool/pool.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_info/method/export_comic.dart';
import 'package:zephyr/src/rust/api/image.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/coreml_model_config.dart';
import 'package:zephyr/util/coreml_model_loader.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/real_sr/android_ncnn_model_config.dart';
import 'package:zephyr/util/real_sr/desktop_ncnn_model_config.dart';
import 'package:zephyr/util/real_sr/real_sr_settings.dart';
import 'package:zephyr/widgets/toast.dart';

/// Breeze 内置 RealSR / Real-CUGAN / CoreML 超分封装
///
/// - Android：调用 bundled 的 waifu2x-ncnn CLI
/// - iOS / macOS：从 `deretame/breeze-binary` 下载 `MacOS-iOS.7z` 后，
///   调用 `CoreMLUpscale` 使用用户选择的 waifu2x / Real-CUGAN 模型
/// - Windows / Linux：从 `deretame/breeze-binary` 下载模型后，
///   调用 `getFilePath()/super_resolution/` 下的 waifu2x-ncnn-vulkan
///   或 realcugan-ncnn-vulkan
class RealSrSuperResolution {
  RealSrSuperResolution._();

  static const MethodChannel _channel = MethodChannel(
    'realsr_super_resolution',
  );

  /// GitHub 上存放桌面端模型压缩包的仓库。
  static const String _binaryRepoBaseUrl =
      'https://github.com/deretame/breeze-binary/raw/main';

  /// 最大并发超分任务数。
  ///
  /// - 桌面端（Windows / Linux / macOS）默认 2，高端显卡可设更高。
  /// - 移动设备（Android / iOS）默认 1，避免 OOM / 发热。
  ///
  /// 修改后会立即影响新任务，已在执行的任务不受影响。
  static int get maxConcurrency {
    if (_maxConcurrency != null) return _maxConcurrency!;
    return RealSrSettings.defaultConcurrency;
  }

  static set maxConcurrency(int value) {
    if (value < 1) {
      throw ArgumentError.value(value, 'maxConcurrency', 'must be >= 1');
    }
    _maxConcurrency = value;
    _pool = Pool(value);
  }

  static int? _maxConcurrency;
  static Pool _pool = Pool(maxConcurrency);

  /// 桌面端模型下载/解压目录：`<getFilePath()>/super_resolution`
  static Future<String> get _modelDirectory async {
    return p.join(await getFilePath(), 'super_resolution');
  }

  /// 当前设备是否支持内置超分（包含模型/可执行文件是否已就绪）。
  ///
  /// - Android：arm64-v8a 且 NCNN 模型已下载并解压
  /// - iOS / macOS：CoreML 模型已下载并解压
  /// - Windows / Linux：存在对应平台的 realcugan-ncnn-vulkan 可执行文件
  static Future<bool> get isAvailable async {
    if (Platform.isAndroid) {
      try {
        if (!await isDeviceSupported) return false;
        return _isAndroidNcnnAvailable(
          variant: AndroidNcnnModelConfig.variantFor(
            mode: AndroidNcnnModelConfig.defaultMode,
            noise: AndroidNcnnModelConfig.defaultNoise,
          ),
        );
      } catch (_) {
        return false;
      }
    }

    if (Platform.isIOS || Platform.isMacOS) {
      return _isCoreMLAvailable;
    }

    if (Platform.isWindows || Platform.isLinux) {
      final modelRoot = await _modelDirectory;
      final mode = await RealSrSettings.loadDesktopNcnnMode();
      final exeName = DesktopNcnnModelConfig.executableNameFor(mode);
      return File(p.join(modelRoot, exeName)).existsSync();
    }

    return false;
  }

  /// 当前设备平台是否支持超分（不检查模型是否已下载）。
  ///
  /// 用于在设置页显示入口；Android 仅要求 arm64-v8a，其他平台默认支持。
  static Future<bool> get isDeviceSupported async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        return androidInfo.supportedAbis.contains('arm64-v8a');
      } catch (_) {
        return false;
      }
    }

    if (Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux) {
      return true;
    }

    return false;
  }

  /// 检查 Android NCNN 模型是否已就绪。
  static Future<bool> _isAndroidNcnnAvailable({
    required NcnnModelVariant variant,
  }) async {
    final modelRoot = await _modelDirectory;
    final modelDir = p.join(modelRoot, variant.modelDir);
    final modelFiles = _androidModelFilesFor(variant);
    for (final relative in modelFiles) {
      if (!File(p.join(modelDir, relative)).existsSync()) {
        return false;
      }
    }
    return true;
  }

  /// 返回指定 Android NCNN 变体所需的模型文件相对路径列表。
  static List<String> _androidModelFilesFor(NcnnModelVariant variant) {
    final modelDir = variant.modelDir.toLowerCase();
    final isWaifu2x =
        modelDir.contains('models-cunet') || modelDir.contains('models-upconv');

    if (!isWaifu2x) {
      final suffix = variant.noise == -1
          ? 'conservative'
          : variant.noise == 0
          ? 'no-denoise'
          : 'denoise${variant.noise}x';
      return [
        'up${variant.scale}x-$suffix.param',
        'up${variant.scale}x-$suffix.bin',
      ];
    }

    if (isWaifu2x) {
      if (variant.noise == -1) {
        return ['scale2.0x_model.param', 'scale2.0x_model.bin'];
      }
      if (variant.scale == 1) {
        return [
          'noise${variant.noise}_model.param',
          'noise${variant.noise}_model.bin',
        ];
      }
      return [
        'noise${variant.noise}_scale2.0x_model.param',
        'noise${variant.noise}_scale2.0x_model.bin',
      ];
    }

    return [];
  }

  /// 检查 iOS / macOS 的 CoreML 模型是否已就绪。
  static Future<bool> get _isCoreMLAvailable async {
    final results = await Future.wait([
      CoreMLModelLoader.isModelAvailable(
        CoreMLModelConfig.defaultVariant.fileName,
      ),
      CoreMLModelLoader.isModelAvailable(
        CoreMLModelConfig.families[1].variants.first.fileName,
      ),
    ]);
    return results.every((e) => e);
  }

  /// 当前平台对应的 7z 压缩包文件名。
  static String? get _assetName {
    if (Platform.isAndroid) return 'realsr-android.7z';
    if (Platform.isWindows) return 'realsr-win.7z';
    if (Platform.isLinux) return 'realsr-linux.7z';
    return null;
  }

  /// 下载并解压当前平台需要的超分模型。
  ///
  /// - Android：下载 `realsr-android.7z` 并解压 NCNN 模型。
  /// - iOS / macOS：下载 `MacOS-iOS.7z` 并解压 CoreML 模型。
  /// - Windows / Linux：下载对应平台的 realcugan-ncnn-vulkan 压缩包。
  ///
  /// [force] 为 true 时，会先删除本地已有模型再重新下载。
  static Future<void> downloadModel({
    void Function(int received, int total)? onProgress,
    bool force = false,
  }) async {
    if (Platform.isIOS || Platform.isMacOS) {
      final tempDir = await getTemporaryDirectory();
      final modelsDir = Directory(p.join(tempDir.path, 'coreml_models'));

      if (force && modelsDir.existsSync()) {
        await modelsDir.delete(recursive: true);
      }

      // 压缩包里包含两个模型，下载任意一个都会把完整压缩包拉下来。
      await CoreMLModelLoader.prepareModel(
        CoreMLModelConfig.defaultVariant.fileName,
        onProgress: onProgress,
      );
      // 确保另一个模型也被解压出来
      await CoreMLModelLoader.prepareModel(
        CoreMLModelConfig.families[1].variants.first.fileName,
      );
      return;
    }

    final assetName = _assetName;
    if (assetName == null) {
      throw UnsupportedError('当前平台不支持下载 RealSR 模型');
    }

    final url = '$_binaryRepoBaseUrl/$assetName';
    final cachePath = await getCachePath();
    final archivePath = p.join(cachePath, assetName);
    final destDir = await _modelDirectory;

    if (force && Directory(destDir).existsSync()) {
      await Directory(destDir).delete(recursive: true);
    }

    await Directory(destDir).create(recursive: true);

    try {
      // 强制重新下载时先删掉本地缓存的压缩包
      if (force && File(archivePath).existsSync()) {
        await File(archivePath).delete();
      }

      await dio.download(
        url,
        archivePath,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress?.call(received, total);
        },
      );

      await decompress7Z(archivePath: archivePath, destPath: destDir);

      // Linux / macOS 需要给可执行文件授权
      if (Platform.isLinux || Platform.isMacOS) {
        final modelRoot = await _modelDirectory;
        for (final name in ['realcugan-ncnn-vulkan', 'waifu2x-ncnn-vulkan']) {
          final exe = p.join(modelRoot, name);
          try {
            await Process.run('chmod', ['+x', exe], runInShell: false);
          } catch (e, s) {
            logger.w('RealSR 可执行文件授权失败: $exe', error: e, stackTrace: s);
          }
        }
      }

      _missingModelNotified = false;
      showSuccessToast('模型下载完成');
    } finally {
      try {
        await File(archivePath).delete();
      } catch (_) {}
    }
  }

  /// 判断图片是否需要超分：仅当能解析出横向分辨率且小于阈值时返回 true。
  static Future<bool> shouldUpscale(
    String inputPath, {
    RealSrResolutionThreshold? threshold,
  }) async {
    logger.d('Checking if $inputPath needs to be upscaled...');
    final effectiveThreshold =
        threshold ?? await RealSrSettings.loadResolutionThreshold();

    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    try {
      buffer = await ui.ImmutableBuffer.fromFilePath(inputPath);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      return descriptor.width < effectiveThreshold.maxWidth;
    } catch (e, s) {
      logger.w('RealSR 无法解析图片尺寸，跳过超分: $inputPath', error: e, stackTrace: s);
      return false;
    } finally {
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  static bool _missingModelNotified = false;

  /// 对单张图片做超分放大，成功后再转换为 WebP 以节省空间。
  static Future<void> upscaleAndConvertToWebp(String inputPath) async {
    final autoUpscale = await RealSrSettings.loadAutoUpscale();
    if (!autoUpscale) return;

    if (!await isAvailable) {
      if (!_missingModelNotified) {
        _missingModelNotified = true;
        showErrorToast('模型不完整');
      }
      return;
    }

    final concurrency = await RealSrSettings.loadConcurrency();
    final targetConcurrency = concurrency == 0 ? 64 : concurrency;
    if (maxConcurrency != targetConcurrency) {
      maxConcurrency = targetConcurrency;
    }

    final threshold = await RealSrSettings.loadResolutionThreshold();
    if (!await shouldUpscale(inputPath, threshold: threshold)) {
      logger.d('Input $inputPath does not need to be upscaled.');
      return;
    }

    final tileSize = await RealSrSettings.loadTileSize();

    // Android NCNN 通过 OpenCV imwrite 写图，只能按扩展名识别格式；
    // 输出路径若带 webp/jpg 等扩展名会崩溃。因此 Android 先写到临时 PNG，
    // 转 WebP 后再覆盖回原路径。
    if (Platform.isAndroid) {
      final cacheDir = await getCachePath();
      final tempOutput = p.join(
        cacheDir,
        'realsr_output_${const Uuid().v4()}.png',
      );

      try {
        await upscale(
          inputPath: inputPath,
          outputPath: tempOutput,
          tileSize: tileSize,
        );

        // 超分成功后输出的是 PNG，再转换为 WebP 以节省空间
        await convertImageToWebp(inputPath: tempOutput, imageType: 'png');
        await File(tempOutput).rename(inputPath);
      } catch (e, s) {
        logger.w('Android 超分/WebP 转换失败: $inputPath', error: e, stackTrace: s);
        rethrow;
      } finally {
        try {
          if (File(tempOutput).existsSync()) {
            await File(tempOutput).delete();
          }
        } catch (_) {}
      }
      return;
    }

    // Windows / Linux：根据用户选择的策略与降噪档位，解析到具体 CLI 与模型。
    if (Platform.isWindows || Platform.isLinux) {
      final mode = await RealSrSettings.loadDesktopNcnnMode();
      final noise = await RealSrSettings.loadDesktopNcnnNoise();
      final variant = DesktopNcnnModelConfig.variantFor(
        mode: mode,
        noise: noise,
      );
      final noiseLevel = RealSrNoiseLevel.values.firstWhere(
        (e) => e.value == variant.noise,
        orElse: () => RealSrNoiseLevel.conservative,
      );

      await upscale(
        inputPath: inputPath,
        outputPath: inputPath,
        executable: variant.displayName,
        modelDir: variant.modelDir,
        scale: variant.scale,
        noiseLevel: noiseLevel,
        tileSize: tileSize,
      );
    } else {
      final noiseLevel = await RealSrSettings.loadNoiseLevel();
      await upscale(
        inputPath: inputPath,
        outputPath: inputPath,
        noiseLevel: noiseLevel,
        tileSize: tileSize,
      );
    }

    // 超分成功后输出的是 PNG，再转换为 WebP 以节省空间
    try {
      await convertImageToWebp(inputPath: inputPath, imageType: 'png');
    } catch (e, s) {
      logger.w('WebP 转换失败，保留超分后的原图: $inputPath', error: e, stackTrace: s);
    }
  }

  /// 对单张图片做超分放大。
  static Future<void> upscale({
    required String inputPath,
    String? outputPath,
    String executable = 'realcugan-ncnn-vulkan',
    String modelDir = 'models-pro',
    int scale = 2,
    RealSrNoiseLevel noiseLevel = RealSrNoiseLevel.conservative,
    int tileSize = 0,
    int syncGapMode = 3,
  }) async {
    if (!await isAvailable) {
      logger.d('Upscaling $inputPath to $outputPath...');
      return;
    }

    await _pool.withResource(() async {
      final startAt = DateTime.now();
      logger.d('Upscaling $inputPath to $outputPath');

      final inputFile = File(inputPath);
      if (!inputFile.existsSync()) {
        throw ArgumentError.value(
          inputPath,
          'inputPath',
          'Input file does not exist',
        );
      }

      final out =
          outputPath ??
          p.join(
            p.dirname(inputPath),
            '${p.basenameWithoutExtension(inputPath)}_sr.png',
          );

      final rawExt = await detectImageExtension(inputFile);
      final normalizedExt = rawExt.toLowerCase();
      const supportedFormats = {'.jpg', '.jpeg', '.png', '.webp'};
      if (!supportedFormats.contains(normalizedExt)) {
        logger.w('RealSR 不支持的图片格式，跳过超分: $inputPath ($rawExt)');
        return;
      }

      if (normalizedExt == '.webp' && await isAnimatedWebP(inputFile)) {
        logger.w('RealSR 不支持动图 WebP，跳过超分: $inputPath');
        return;
      }

      // 超分引擎统一按 PNG 输入处理，先转换到临时 PNG。
      String pngInputPath = inputPath;
      File? tempPngFile;
      if (normalizedExt != '.png') {
        final cacheDir = await getCachePath();
        pngInputPath = p.join(
          cacheDir,
          'realsr_input_${const Uuid().v4()}.png',
        );
        tempPngFile = File(pngInputPath);
        await convertImageToPng(inputPath: inputPath, outputPath: pngInputPath);
      }

      try {
        if (Platform.isAndroid) {
          final variant = AndroidNcnnModelConfig.variantFor(
            mode: AndroidNcnnModelConfig.defaultMode,
            noise: AndroidNcnnModelConfig.defaultNoise,
          );
          await _upscaleAndroidCli(
            inputPath: pngInputPath,
            outputPath: out,
            variant: variant,
            tileSize: tileSize,
          );
        } else if (Platform.isIOS || Platform.isMacOS) {
          await _upscaleCoreML(inputPath: pngInputPath, outputPath: out);
        } else {
          await _upscaleCli(
            inputPath: pngInputPath,
            outputPath: out,
            executable: executable,
            modelDir: modelDir,
            scale: scale,
            noiseLevel: noiseLevel,
            tileSize: tileSize,
            syncGapMode: syncGapMode,
          );
        }
      } finally {
        if (tempPngFile != null && tempPngFile.existsSync()) {
          await tempPngFile.delete();
        }
      }

      final endAt = DateTime.now();
      final duration = endAt.difference(startAt).inMilliseconds;
      logger.d('Upscaling took ${duration}ms');
    });
  }

  /// Android 通过 bundled waifu2x CLI 超分。
  static Future<void> _upscaleAndroidCli({
    required String inputPath,
    required String outputPath,
    required NcnnModelVariant variant,
    required int tileSize,
  }) async {
    final exePath = await _prepareAndroidCli();
    final modelRoot = await _modelDirectory;
    final modelPath = p.join(modelRoot, variant.modelDir);

    final result = await Process.run(
      exePath,
      [
        '-i',
        inputPath,
        '-o',
        outputPath,
        '-s',
        variant.scale.toString(),
        '-n',
        variant.noise.toString(),
        '-m',
        modelPath,
        '-g',
        '0',
        '-t',
        tileSize.toString(),
      ],
      runInShell: false,
      workingDirectory: modelRoot,
    );

    if (result.exitCode != 0) {
      throw StateError(
        'waifu2x CLI 失败 (exitCode=${result.exitCode})\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}',
      );
    }
  }

  static String? _androidCliPath;

  /// 获取 APK 中 bundled 的 waifu2x CLI 路径（位于 nativeLibraryDir）。
  static Future<String> _prepareAndroidCli() async {
    if (_androidCliPath != null) return _androidCliPath!;

    final path = await _channel.invokeMethod<String>('getWaifu2xCliPath');
    if (path == null || path.isEmpty) {
      throw StateError('getWaifu2xCliPath returned empty path');
    }
    _androidCliPath = path;
    return path;
  }

  /// iOS / macOS 通过 CoreML 插件超分。
  static Future<void> _upscaleCoreML({
    required String inputPath,
    required String outputPath,
  }) async {
    final family = await RealSrSettings.loadCoreMLFamily();
    final variant = await RealSrSettings.loadCoreMLVariant(family);
    final modelPath = await CoreMLModelLoader.prepareModel(variant.fileName);

    await CoreMLUpscale.upscale(
      inputPath: inputPath,
      outputPath: outputPath,
      modelPath: modelPath,
      modelType: 'multiarray',
      config: variant.config,
    );
  }

  /// 桌面端通过 Process.run 调用 waifu2x-ncnn-vulkan / realcugan-ncnn-vulkan。
  static Future<void> _upscaleCli({
    required String inputPath,
    required String outputPath,
    required String executable,
    required String modelDir,
    required int scale,
    required RealSrNoiseLevel noiseLevel,
    required int tileSize,
    required int syncGapMode,
  }) async {
    final modelRoot = await _modelDirectory;
    final exe = p.join(modelRoot, executable);
    final isWaifu2x = executable.toLowerCase().contains('waifu2x');
    final cachePath = await getCachePath();
    final workDir = Directory(
      p.normalize(p.join(cachePath, 'realsr-upscale', const Uuid().v4())),
    );

    try {
      await workDir.create(recursive: true);

      // CLI 根据后缀判断输入格式，用真实扩展名避免格式错配导致花图。
      final rawExt = await detectImageExtension(File(inputPath));
      final inputExt = rawExt.startsWith('.') ? rawExt.substring(1) : rawExt;
      final tempInput = p.join(
        workDir.path,
        'input.${inputExt.isEmpty ? 'png' : inputExt}',
      );
      final tempOutput = p.join(workDir.path, 'output.png');
      await File(inputPath).copy(tempInput);

      final modelPath = p.join(modelRoot, modelDir);
      final args = [
        '-i',
        tempInput,
        '-o',
        tempOutput,
        '-s',
        scale.toString(),
        '-n',
        noiseLevel.value.toString(),
        '-m',
        modelPath,
        '-g',
        '0',
        '-t',
        tileSize.toString(),
        if (!isWaifu2x) ...['-c', syncGapMode.toString()],
      ];
      final result = await Process.run(
        exe,
        args,
        runInShell: false,
        workingDirectory: modelRoot,
      );

      if (result.exitCode != 0) {
        throw StateError(
          '${isWaifu2x ? 'waifu2x' : 'Real-CUGAN'} CLI 失败 '
          '(exitCode=${result.exitCode})\n'
          'stdout: ${result.stdout}\n'
          'stderr: ${result.stderr}',
        );
      }

      await File(tempOutput).copy(outputPath);
    } finally {
      if (workDir.existsSync()) {
        workDir.deleteSync(recursive: true);
      }
    }
  }
}

class RealSrUpscaleResult {
  final bool success;
  final int exitCode;
  final String outputPath;
  final String stdout;
  final String stderr;

  const RealSrUpscaleResult({
    required this.success,
    required this.exitCode,
    required this.outputPath,
    required this.stdout,
    required this.stderr,
  });

  /// 如果成功，返回输出文件；否则抛出异常并附带 stderr。
  File get outputFile {
    if (!success) {
      throw StateError(
        'RealSR upscale failed (exitCode=$exitCode)\nstdout: $stdout\nstderr: $stderr',
      );
    }
    return File(outputPath);
  }

  @override
  String toString() {
    return 'RealSrUpscaleResult(success=$success, exitCode=$exitCode, outputPath=$outputPath)';
  }
}

/// 检测 WebP 文件是否为动图
/// 返回 true 表示是动图，false 表示静态图或读取失败
Future<bool> isAnimatedWebP(File file) async {
  try {
    // 只需要读取前 20 个字节就够了（实际只需 16 个，读 20 以防万一）
    final bytes = await file.openRead(0, 20).first;

    // 长度不足则判定为非动图
    if (bytes.length < 16) return false;

    // 校验头部是否为 RIFF...WEBP (0x52= R, 0x49=I, 0x46=F)
    // 偏移 0-3: RIFF, 偏移 8-11: WEBP
    if (bytes[0] != 0x52 ||
        bytes[1] != 0x49 ||
        bytes[2] != 0x46 ||
        bytes[3] != 0x46) {
      return false;
    }
    if (bytes[8] != 0x57 ||
        bytes[9] != 0x45 ||
        bytes[10] != 0x42 ||
        bytes[11] != 0x50) {
      return false;
    }

    // 关键判断：偏移 12-15 必须是 'ANIM' (0x41=A, 0x4E=N, 0x49=I, 0x4D=M)
    // 只要是 ANIM，就说明包含动画控制块，必然是动图
    return bytes[12] == 0x41 &&
        bytes[13] == 0x4E &&
        bytes[14] == 0x49 &&
        bytes[15] == 0x4D;
  } catch (_) {
    return true;
  }
}
