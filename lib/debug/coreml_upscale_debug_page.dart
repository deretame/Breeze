import 'dart:io';

import 'package:auto_route/annotations.dart';
import 'package:coreml_upscale/coreml_upscale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zephyr/i18n/strings.g.dart';
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
      setState(() => _status = t.realSr.coremlStatusFillInput);
      return;
    }
    if (_selectedVariant == null) {
      setState(() => _status = t.realSr.coremlStatusNoModelFile);
      return;
    }

    setState(() {
      _loading = true;
      _status = t.realSr.coremlStatusPreparing;
      _outputPath = null;
    });

    try {
      final modelPath = await _prepareModel(_selectedVariant!.fileName);
      final inputPath = await _prepareInputPath(rawInput);
      final cacheDir = await getTemporaryDirectory();
      final outputPath = '${cacheDir.path}/coreml_upscale_output.png';

      setState(() => _status = t.realSr.coremlStatusUpscaling);

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
        _status = t.realSr.coremlStatusDone(outputPath: outputPath, size: size);
      });
    } catch (e, st) {
      logger.e('CoreML upscale failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _status = t.realSr.coremlStatusFailed(error: e));
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
    return t.realSr.blockInfoFormat(
      contentSize: contentSize,
      blockSize: blockSize,
      shrinkSize: shrinkSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.settings.coremlDebug)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 模型族选择：速度优先 / 质量优先
          ListTile(
            leading: const Icon(Icons.speed),
            title: Text(t.realSr.model),
            subtitle: DropdownButton<CoreMLModelFamily>(
              value: _selectedFamily,
              isExpanded: true,
              items: CoreMLModelConfig.families
                  .map(
                    (f) => DropdownMenuItem<CoreMLModelFamily>(
                      value: f,
                      child: Text(f.localizedLabel),
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
              title: Text(t.realSr.coremlModelOption),
              subtitle: DropdownButton<CoreMLModelVariant>(
                value: _selectedVariant,
                isExpanded: true,
                items: _selectedFamily.variants
                    .map(
                      (v) => DropdownMenuItem<CoreMLModelVariant>(
                        value: v,
                        child: Text(v.localizedDisplayName),
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
            ListTile(
              leading: const Icon(Icons.error_outline),
              title: Text(t.realSr.coremlStatusNoModelFile),
            ),
          // 通用选项：放大倍率（当前所有模型都是 2×）
          ListTile(
            leading: const Icon(Icons.zoom_in),
            title: Text(t.realSr.coremlGeneralOption),
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
              title: Text(t.realSr.coremlTileInfo),
              subtitle: Text(_blockInfo(_selectedVariant!)),
              trailing: Tooltip(
                triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 5),
                message: t.realSr.blockInfoTooltip,
                child: const Icon(Icons.help_outline),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _inputController,
            decoration: InputDecoration(
              labelText: t.realSr.coremlInputHint,
              border: const OutlineInputBorder(),
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
                : Text(t.realSr.coremlStartUpscale),
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
