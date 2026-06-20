import 'dart:io';

import 'package:auto_route/annotations.dart';
import 'package:coreml_upscale/coreml_upscale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/coreml_model_config.dart';
import 'package:zephyr/util/coreml_model_loader.dart';

@RoutePage()
class CoreMLUpscaleDebugPage extends StatefulWidget {
  const CoreMLUpscaleDebugPage({super.key});

  @override
  State<CoreMLUpscaleDebugPage> createState() => _CoreMLUpscaleDebugPageState();
}

class _CoreMLUpscaleDebugPageState extends State<CoreMLUpscaleDebugPage> {
  final TextEditingController _inputController = TextEditingController(
    text: 'asset/image/error_image/404.png',
  );

  late CoreMLModelFamily _selectedFamily;
  CoreMLModelVariant? _selectedVariant;

  /// 放大倍率是通用选项，切换模型族时不应被重置。
  int _scale = 2;

  bool _loading = false;
  String? _status;
  String? _outputPath;

  @override
  void initState() {
    super.initState();
    // 默认选择 waifu2x（速度优先）。
    _selectedFamily = CoreMLModelConfig.defaultFamily;
    _selectedVariant = _selectedFamily.variants.first;
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  /// 从 GitHub 下载并准备模型，返回本地绝对路径。
  Future<String> _prepareModel(String fileName) async {
    return CoreMLModelLoader.prepareModel(fileName);
  }

  Future<String> _prepareInputPath(String input) async {
    if (input.startsWith('asset/')) {
      final cacheDir = await getTemporaryDirectory();
      final fileName = input.split('/').last;
      final file = File('${cacheDir.path}/$fileName');
      if (!file.existsSync()) {
        final data = await rootBundle.load(input);
        await file.writeAsBytes(data.buffer.asUint8List());
      }
      return file.path;
    }
    return input;
  }

  Future<void> _runUpscale() async {
    final rawInput = _inputController.text.trim();
    if (rawInput.isEmpty) {
      setState(() => _status = '请填写输入图片路径');
      return;
    }
    if (_selectedVariant == null) {
      setState(() => _status = '当前模型族没有可用的模型文件');
      return;
    }

    setState(() {
      _loading = true;
      _status = '正在准备资源...';
      _outputPath = null;
    });

    try {
      final modelPath = await _prepareModel(_selectedVariant!.fileName);
      final inputPath = await _prepareInputPath(rawInput);
      final cacheDir = await getTemporaryDirectory();
      final outputPath = '${cacheDir.path}/coreml_upscale_output.png';

      setState(() => _status = '正在超分...');

      // 通用选项（scale）可以覆盖模型默认配置。
      final config = Map<String, dynamic>.from(_selectedVariant!.config);
      config['scale'] = _scale;

      await CoreMLUpscale.upscale(
        inputPath: inputPath,
        outputPath: outputPath,
        modelPath: modelPath,
        modelType: 'multiarray',
        config: config,
      );

      final file = File(outputPath);
      final exists = file.existsSync();
      final size = exists ? file.lengthSync() : 0;

      if (!mounted) return;
      setState(() {
        _outputPath = outputPath;
        _status = '完成\n$outputPath\nsize: $size bytes';
      });
    } catch (e, st) {
      logger.e('CoreML 超分失败', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _status = '失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 分块大小的说明：
  /// - blockSize 是模型真实输入尺寸（含四周反射填充）。
  /// - 实际参与拼接的“内容块”是 blockSize - 2*shrinkSize。
  /// - 这里必须向用户展示两者的区别，避免把模型输入尺寸误当成内容块。
  String _blockInfo(CoreMLModelVariant variant) {
    final blockSize = variant.config['blockSize'] as int? ?? 0;
    final shrinkSize = variant.config['shrinkSize'] as int? ?? 0;
    final contentSize = CoreMLModelConfig.contentBlockSize(variant);
    return '内容块 $contentSize×$contentSize，模型输入 $blockSize×$blockSize'
        '（含 ${shrinkSize}px 反射边距）';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CoreML 超分调试')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 模型族选择：速度优先 / 质量优先
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('模型'),
            subtitle: DropdownButton<CoreMLModelFamily>(
              value: _selectedFamily,
              isExpanded: true,
              items: CoreMLModelConfig.families
                  .map(
                    (f) => DropdownMenuItem<CoreMLModelFamily>(
                      value: f,
                      child: Text(f.label),
                    ),
                  )
                  .toList(),
              onChanged: _loading
                  ? null
                  : (value) {
                      if (value != null && value != _selectedFamily) {
                        setState(() {
                          _selectedFamily = value;
                          // 切换模型族后，模型专有选项（降噪变体）重置为该族第一个。
                          _selectedVariant = value.variants.isNotEmpty
                              ? value.variants.first
                              : null;
                        });
                      }
                    },
            ),
          ),
          // 模型专有选项：降噪级别 / 变体
          if (_selectedVariant != null)
            ListTile(
              leading: const Icon(Icons.healing),
              title: const Text('模型选项（降噪级别）'),
              subtitle: DropdownButton<CoreMLModelVariant>(
                value: _selectedVariant,
                isExpanded: true,
                items: _selectedFamily.variants
                    .map(
                      (v) => DropdownMenuItem<CoreMLModelVariant>(
                        value: v,
                        child: Text(v.displayName),
                      ),
                    )
                    .toList(),
                onChanged: _loading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedVariant = value);
                        }
                      },
              ),
            )
          else
            const ListTile(
              leading: Icon(Icons.error_outline),
              title: Text('当前模型族没有可用的模型文件'),
            ),
          // 通用选项：放大倍率（当前所有模型都是 2×）
          ListTile(
            leading: const Icon(Icons.zoom_in),
            title: const Text('通用选项（放大倍率）'),
            subtitle: DropdownButton<int>(
              value: _scale,
              isExpanded: true,
              items: const [DropdownMenuItem(value: 2, child: Text('2×'))],
              onChanged: _loading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _scale = value);
                      }
                    },
            ),
          ),
          // 分块信息（只读）
          if (_selectedVariant != null)
            ListTile(
              leading: const Icon(Icons.grid_view),
              title: const Text('分块信息'),
              subtitle: Text(_blockInfo(_selectedVariant!)),
              trailing: Tooltip(
                triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 5),
                message:
                    'blockSize 是模型输入尺寸，包含反射边距；\n'
                    '内容块 = blockSize - 2×shrinkSize，才是真正拼接输出的区域。\n'
                    '切换模型时，这一组参数会随模型自动变化。',
                child: const Icon(Icons.help_outline),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _inputController,
            decoration: const InputDecoration(
              labelText: '输入图片绝对路径或 asset 路径',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loading || _selectedVariant == null
                ? null
                : _runUpscale,
            child: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('开始超分'),
          ),
          const SizedBox(height: 16),
          if (_status != null)
            SelectableText(
              _status!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          if (_outputPath != null && File(_outputPath!).existsSync()) ...[
            const SizedBox(height: 16),
            Image.file(File(_outputPath!)),
          ],
        ],
      ),
    );
  }
}
