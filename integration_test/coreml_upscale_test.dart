import 'dart:io';
import 'dart:ui' as ui;

import 'package:coreml_upscale/coreml_upscale.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zephyr/util/coreml_model_loader.dart';
import 'package:zephyr/util/real_sr/real_sr_super_resolution.dart';
import 'package:zephyr/util/rust_loader.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initRustLib(silent: true);
  });

  const inputAsset = 'asset/image/error_image/404.png';

  Future<String> prepareInput() async {
    final cacheDir = await getTemporaryDirectory();
    final fileName = inputAsset.split('/').last;
    final file = File('${cacheDir.path}/$fileName');
    if (!file.existsSync()) {
      final data = await rootBundle.load(inputAsset);
      await file.writeAsBytes(data.buffer.asUint8List());
    }
    return file.path;
  }

  Future<ui.Image> decodePng(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  testWidgets('waifu2x 2x multiarray upscale', (tester) async {
    final modelPath = await CoreMLModelLoader.prepareModel(
      'waifu2x_photo_noise0_scale2x.mlmodel',
    );
    final inputPath = await prepareInput();
    final outputPath =
        '${(await getTemporaryDirectory()).path}/waifu2x_output.png';

    await CoreMLUpscale.upscale(
      inputPath: inputPath,
      outputPath: outputPath,
      modelPath: modelPath,
      modelType: 'multiarray',
      config: const <String, dynamic>{
        'inputName': 'input',
        'outputName': 'output',
        'blockSize': 156,
        'shrinkSize': 7,
        'scale': 2,
      },
    );

    expect(File(outputPath).existsSync(), isTrue);
    final outputImage = await decodePng(outputPath);
    expect(outputImage.width, 1010);
    expect(outputImage.height, 1010);
  });

  testWidgets('Real-CUGAN 2x multiarray upscale', (tester) async {
    final modelPath = await CoreMLModelLoader.prepareModel(
      'RealCUGAN_2x_no-denoise_block156.mlpackage',
    );
    final inputPath = await prepareInput();
    final outputPath =
        '${(await getTemporaryDirectory()).path}/realcugan_output.png';

    await CoreMLUpscale.upscale(
      inputPath: inputPath,
      outputPath: outputPath,
      modelPath: modelPath,
      modelType: 'multiarray',
      config: const <String, dynamic>{
        'inputName': 'input',
        'outputName': 'output',
        'blockSize': 192,
        'shrinkSize': 18,
        'scale': 2,
      },
    );

    expect(File(outputPath).existsSync(), isTrue);
    final outputImage = await decodePng(outputPath);
    expect(outputImage.width, 1010);
    expect(outputImage.height, 1010);
  });

  testWidgets('CoreML 模型强制重新下载', (tester) async {
    await RealSrSuperResolution.downloadModel(force: true);
    expect(await RealSrSuperResolution.isAvailable, isTrue);
  });

  testWidgets('RealSrSuperResolution 联动设置使用 CoreML 超分', (tester) async {
    final inputPath = await prepareInput();
    final outputPath =
        '${(await getTemporaryDirectory()).path}/realsr_settings_output.png';

    // 这里会读取设置中默认的 CoreML 模型（waifu2x）并执行超分。
    await RealSrSuperResolution.upscale(
      inputPath: inputPath,
      outputPath: outputPath,
    );

    expect(File(outputPath).existsSync(), isTrue);
    final outputImage = await decodePng(outputPath);
    expect(outputImage.width, 1010);
    expect(outputImage.height, 1010);
  });
}
