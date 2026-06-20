import 'package:flutter/services.dart';

/// CoreML 图片超分插件。
///
/// 目前支持 macOS / iOS，模型通过绝对路径传入。
class CoreMLUpscale {
  static const MethodChannel _channel = MethodChannel('coreml_upscale');

  /// 对单张图片做超分。
  ///
  /// [modelPath] 为 .mlmodel 或 .mlpackage 的绝对路径。
  /// [modelType] 可选 `multiarray`（默认）或 `image`。
  /// [config] 透传给原生模型，例如 `{"blockSize": 156, "shrinkSize": 7, "scale": 2}`。
  static Future<void> upscale({
    required String inputPath,
    required String outputPath,
    required String modelPath,
    String modelType = 'multiarray',
    Map<String, dynamic>? config,
  }) async {
    await _channel.invokeMethod('upscale', {
      'inputPath': inputPath,
      'outputPath': outputPath,
      'modelPath': modelPath,
      'modelType': modelType,
      'config': config,
    });
  }
}
