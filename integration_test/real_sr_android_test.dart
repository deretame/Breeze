import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zephyr/util/real_sr/android_ncnn_model_config.dart';
import 'package:zephyr/util/real_sr/real_sr_settings.dart';
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

  Future<void> runMode(AndroidNcnnMode mode, AndroidNcnnNoise noise) async {
    await RealSrSettings.saveAndroidNcnnMode(mode);
    await RealSrSettings.saveAndroidNcnnNoise(noise);

    final inputPath = await prepareInput();
    final outputPath =
        '${(await getTemporaryDirectory()).path}/realsr_${mode.name}_${noise.name}.png';

    await RealSrSuperResolution.upscale(
      inputPath: inputPath,
      outputPath: outputPath,
    );

    expect(File(outputPath).existsSync(), isTrue);
    final outputImage = await decodePng(outputPath);
    expect(outputImage.width, 1010);
    expect(outputImage.height, 1010);
  }

  testWidgets('RealSR Android 模型已就绪', (tester) async {
    expect(await RealSrSuperResolution.isDeviceSupported, isTrue);
    if (!await RealSrSuperResolution.isAvailable) {
      await RealSrSuperResolution.downloadModel();
    }
    expect(await RealSrSuperResolution.isAvailable, isTrue);
  });

  testWidgets('效率优先 waifu2x upconv 2x 超分', (tester) async {
    await runMode(AndroidNcnnMode.efficiency, AndroidNcnnNoise.noise0);
  });

  testWidgets('质量优先 Real-CUGAN no-denoise 2x 超分', (tester) async {
    await runMode(AndroidNcnnMode.quality, AndroidNcnnNoise.noise0);
  });

  testWidgets('质量优先 Real-CUGAN conservative 2x 超分', (tester) async {
    await runMode(AndroidNcnnMode.quality, AndroidNcnnNoise.noiseConservative);
  });
}
