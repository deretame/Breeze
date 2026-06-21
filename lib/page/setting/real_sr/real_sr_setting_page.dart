import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/coreml_model_config.dart';
import 'package:zephyr/util/real_sr/android_ncnn_model_config.dart';
import 'package:zephyr/util/real_sr/desktop_ncnn_model_config.dart';
import 'package:zephyr/util/real_sr/real_sr_settings.dart';
import 'package:zephyr/util/real_sr/real_sr_super_resolution.dart';
import 'package:zephyr/widgets/toast.dart';

import '../common/setting_ui.dart';

const Map<int, String> _realSrConcurrencyLabels = {
  1: '1',
  2: '2',
  4: '4',
  6: '6',
  8: '8',
  0: '不限制',
};

const Map<int, String> _realSrTileSizeLabels = {
  0: '0',
  128: '128',
  256: '256',
  512: '512',
  1024: '1024',
};

final List<int> _realSrConcurrencyOptions =
    _realSrConcurrencyLabels.keys.toList()..sort();
final List<int> _realSrTileSizeOptions = _realSrTileSizeLabels.keys.toList()
  ..sort();

@RoutePage()
class RealSrSettingPage extends StatefulWidget {
  const RealSrSettingPage({super.key});

  @override
  State<RealSrSettingPage> createState() => _RealSrSettingPageState();
}

class _RealSrSettingPageState extends State<RealSrSettingPage> {
  bool _loading = true;
  bool _autoUpscale = false;
  RealSrResolutionThreshold _resolutionThreshold =
      RealSrResolutionThreshold.p720;
  int _concurrency = 2;
  int _tileSize = 0;
  AndroidNcnnMode _desktopNcnnMode = DesktopNcnnModelConfig.defaultMode;
  AndroidNcnnNoise _desktopNcnnNoise = DesktopNcnnModelConfig.defaultNoise;

  CoreMLModelFamily _coreMLFamily = CoreMLModelConfig.defaultFamily;
  CoreMLModelVariant _coreMLVariant = CoreMLModelConfig.defaultVariant;

  bool _isAvailable = false;
  bool _downloading = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final family = await RealSrSettings.loadCoreMLFamily();
    final variant = await RealSrSettings.loadCoreMLVariant(family);

    final results = await Future.wait([
      RealSrSettings.loadAutoUpscale(),
      RealSrSettings.loadResolutionThreshold(),
      RealSrSettings.loadConcurrency(),
      RealSrSettings.loadTileSize(),
      RealSrSettings.loadDesktopNcnnMode(),
      RealSrSettings.loadDesktopNcnnNoise(),
      RealSrSuperResolution.isAvailable,
    ]);

    if (!mounted) return;

    setState(() {
      _autoUpscale = results[0] as bool;
      _resolutionThreshold = results[1] as RealSrResolutionThreshold;
      _concurrency = results[2] as int;
      _tileSize = results[3] as int;
      _desktopNcnnMode = results[4] as AndroidNcnnMode;
      _desktopNcnnNoise = results[5] as AndroidNcnnNoise;
      _isAvailable = results[6] as bool;
      _coreMLFamily = family;
      _coreMLVariant = variant;
      _loading = false;
    });
  }

  Future<void> _setAutoUpscale(bool value) async {
    await RealSrSettings.saveAutoUpscale(value);
    setState(() => _autoUpscale = value);
  }

  Future<void> _setResolutionThreshold(RealSrResolutionThreshold value) async {
    await RealSrSettings.saveResolutionThreshold(value);
    setState(() => _resolutionThreshold = value);
  }

  Future<void> _setConcurrency(int value) async {
    await RealSrSettings.saveConcurrency(value);
    setState(() => _concurrency = value);
  }

  Future<void> _setTileSize(int value) async {
    await RealSrSettings.saveTileSize(value);
    setState(() => _tileSize = value);
  }

  Future<void> _setDesktopNcnnMode(AndroidNcnnMode value) async {
    await RealSrSettings.saveDesktopNcnnMode(value);
    setState(() => _desktopNcnnMode = value);
  }

  Future<void> _setDesktopNcnnNoise(AndroidNcnnNoise value) async {
    await RealSrSettings.saveDesktopNcnnNoise(value);
    setState(() => _desktopNcnnNoise = value);
  }

  Future<void> _setCoreMLFamily(CoreMLModelFamily value) async {
    final newVariant = value.variants.first;
    await Future.wait([
      RealSrSettings.saveCoreMLFamily(value),
      RealSrSettings.saveCoreMLVariant(newVariant),
    ]);
    setState(() {
      _coreMLFamily = value;
      _coreMLVariant = newVariant;
    });
  }

  Future<void> _setCoreMLVariant(CoreMLModelVariant value) async {
    await RealSrSettings.saveCoreMLVariant(value);
    setState(() => _coreMLVariant = value);
  }

  Future<void> _downloadModel() async {
    setState(() {
      _downloading = true;
      _downloadProgress = 0;
    });

    try {
      await RealSrSuperResolution.downloadModel(
        force: _isAvailable,
        onProgress: (received, total) {
          if (!mounted || total <= 0) return;
          setState(() => _downloadProgress = received / total);
        },
      );
    } catch (e, s) {
      logger.e('模型下载失败', error: e, stackTrace: s);
      showErrorToast('模型下载失败: $e');
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
        await _refreshAvailability();
      }
    }
  }

  Future<void> _refreshAvailability() async {
    final available = await RealSrSuperResolution.isAvailable;
    if (mounted) setState(() => _isAvailable = available);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '图片超分（实验性）',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: _loading ? _buildLoading() : _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  List<RealSrResolutionThreshold> get _availableThresholds {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return RealSrResolutionThreshold.values;
    }
    return const [
      RealSrResolutionThreshold.p540,
      RealSrResolutionThreshold.p720,
      RealSrResolutionThreshold.p1080,
    ];
  }

  RealSrResolutionThreshold get _effectiveResolutionThreshold {
    if (_availableThresholds.contains(_resolutionThreshold)) {
      return _resolutionThreshold;
    }
    return RealSrResolutionThreshold.p1080;
  }

  bool get _usesCoreML => Platform.isIOS || Platform.isMacOS;

  Widget _buildContent(BuildContext context) {
    return ListView(
      children: [
        _buildSectionTitle(context, '自动超分'),
        SwitchListTile(
          secondary: const Icon(Icons.auto_fix_high_outlined),
          title: const Text('自动超分'),
          subtitle: Text(!_isAvailable ? '模型未下载，开启后无法自动超分' : '下载或加载图片时自动调用超分'),
          thumbIcon: kSettingSwitchThumbIcon,
          value: _autoUpscale,
          onChanged: _setAutoUpscale,
        ),

        const SizedBox(height: 8),
        const Divider(height: 1, thickness: 0.3),
        _buildSectionTitle(context, '超分条件'),
        ListTile(
          leading: const Icon(Icons.hd_outlined),
          title: const Text('分辨率阈值'),
          subtitle: const Text('仅当图片宽度小于该值时才自动超分'),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<RealSrResolutionThreshold>(
              value: _effectiveResolutionThreshold,
              icon: const Icon(Icons.expand_more),
              onChanged: (RealSrResolutionThreshold? value) {
                if (value != null) _setResolutionThreshold(value);
              },
              items: _availableThresholds
                  .map(
                    (value) => DropdownMenuItem<RealSrResolutionThreshold>(
                      value: value,
                      child: Text(value.label),
                    ),
                  )
                  .toList(),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 15,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),
        const Divider(height: 1, thickness: 0.3),
        _buildSectionTitle(context, '性能'),
        ListTile(
          leading: const Icon(Icons.speed_outlined),
          title: const Text('并发数量'),
          subtitle: const Text('高端显卡可适当提高，移动设备或性能较低时不建议设置高于1的并发量'),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _realSrConcurrencyOptions.contains(_concurrency)
                  ? _concurrency
                  : RealSrSettings.defaultConcurrency,
              icon: const Icon(Icons.expand_more),
              onChanged: (int? value) {
                if (value != null) _setConcurrency(value);
              },
              items: _realSrConcurrencyOptions.map((value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(_realSrConcurrencyLabels[value] ?? '$value'),
                );
              }).toList(),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 15,
              ),
            ),
          ),
        ),

        // iOS / macOS 使用 CoreML，分块大小由模型决定，不显示可配置项。
        if (!_usesCoreML)
          ListTile(
            leading: const Icon(Icons.grid_on_outlined),
            title: const Text('分块大小'),
            subtitle: const Text('遇到崩溃可设置较小值，0为不分块，桌面端可尝试设置为0'),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _realSrTileSizeOptions.contains(_tileSize)
                    ? _tileSize
                    : 0,
                icon: const Icon(Icons.expand_more),
                onChanged: (int? value) {
                  if (value != null) _setTileSize(value);
                },
                items: _realSrTileSizeOptions.map((value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(_realSrTileSizeLabels[value] ?? '$value'),
                  );
                }).toList(),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 15,
                ),
              ),
            ),
          ),

        const SizedBox(height: 8),
        const Divider(height: 1, thickness: 0.3),
        _buildSectionTitle(context, '模型'),

        // iOS / macOS：使用 CoreML，模型族 + 变体 + 分块信息。
        if (_usesCoreML) ...[
          ListTile(
            leading: const Icon(Icons.speed_outlined),
            title: const Text('模型'),
            subtitle: const Text('切换模型族会重置对应的变体选项'),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<CoreMLModelFamily>(
                value: _coreMLFamily,
                icon: const Icon(Icons.expand_more),
                onChanged: (CoreMLModelFamily? value) {
                  if (value != null) _setCoreMLFamily(value);
                },
                items: CoreMLModelConfig.families
                    .map(
                      (value) => DropdownMenuItem<CoreMLModelFamily>(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.healing_outlined),
            title: const Text('降噪级别'),
            subtitle: const Text('该选项随所选模型变化'),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<CoreMLModelVariant>(
                value: _coreMLVariant,
                icon: const Icon(Icons.expand_more),
                onChanged: (CoreMLModelVariant? value) {
                  if (value != null) _setCoreMLVariant(value);
                },
                items: _coreMLFamily.variants
                    .map(
                      (value) => DropdownMenuItem<CoreMLModelVariant>(
                        value: value,
                        child: Text(value.displayName),
                      ),
                    )
                    .toList(),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.grid_view_outlined),
            title: const Text('分块信息'),
            subtitle: Text(_coreMLBlockInfo),
            trailing: Tooltip(
              triggerMode: TooltipTriggerMode.tap,
              showDuration: const Duration(seconds: 5),
              message:
                  'blockSize 是模型输入尺寸，包含反射边距；\n'
                  '内容块 = blockSize - 2×shrinkSize，才是真正拼接输出的区域。',
              child: const Icon(Icons.help_outline),
            ),
          ),
        ] else if (Platform.isAndroid) ...[
          // Android：固定使用 waifu2x upconv CLI，不暴露策略/降噪选项。
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Android 超分'),
            subtitle: Text('当前使用 waifu2x upconv 动漫模型，2 倍放大'),
          ),
        ] else ...[
          // Windows / Linux：与 Android 保持一致的策略 + 降噪档位。
          ListTile(
            leading: const Icon(Icons.speed_outlined),
            title: const Text('超分策略'),
            subtitle: const Text('效率优先使用 waifu2x，质量优先使用 Real-CUGAN'),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<AndroidNcnnMode>(
                value: _desktopNcnnMode,
                icon: const Icon(Icons.expand_more),
                onChanged: (AndroidNcnnMode? value) {
                  if (value != null) _setDesktopNcnnMode(value);
                },
                items: AndroidNcnnMode.values
                    .map(
                      (value) => DropdownMenuItem<AndroidNcnnMode>(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.healing_outlined),
            title: const Text('降噪级别'),
            subtitle: const Text('保守适合普通漫画，降噪级别越高涂抹感越强'),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<AndroidNcnnNoise>(
                value: _desktopNcnnNoise,
                icon: const Icon(Icons.expand_more),
                onChanged: (AndroidNcnnNoise? value) {
                  if (value != null) _setDesktopNcnnNoise(value);
                },
                items: AndroidNcnnNoise.values
                    .map(
                      (value) => DropdownMenuItem<AndroidNcnnNoise>(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 8),
        const Divider(height: 1, thickness: 0.3),
        _buildSectionTitle(context, '模型管理'),
        _buildModelManagementTile(context),

        const SizedBox(height: 32),
      ],
    );
  }

  String get _coreMLBlockInfo {
    final blockSize = _coreMLVariant.config['blockSize'] as int? ?? 0;
    final shrinkSize = _coreMLVariant.config['shrinkSize'] as int? ?? 0;
    final contentSize = CoreMLModelConfig.contentBlockSize(_coreMLVariant);
    return '内容块 $contentSize×$contentSize，模型输入 $blockSize×$blockSize'
        '（含 ${shrinkSize}px 反射边距）';
  }

  Widget _buildModelManagementTile(BuildContext context) {
    if (_downloading) {
      return ListTile(
        leading: const Icon(Icons.downloading_outlined),
        title: const Text('正在下载模型'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _downloadProgress),
            const SizedBox(height: 4),
            Text('${(_downloadProgress * 100).toStringAsFixed(1)}%'),
          ],
        ),
      );
    }

    if (_isAvailable) {
      return ListTile(
        leading: Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('模型已就绪'),
        trailing: TextButton(
          onPressed: _downloadModel,
          child: const Text('重新下载'),
        ),
      );
    }

    return ListTile(
      leading: const Icon(Icons.warning_amber_rounded),
      title: const Text('模型未下载'),
      subtitle: const Text('使用超分前需要先下载模型'),
      trailing: ElevatedButton(
        onPressed: _downloadModel,
        child: const Text('下载模型'),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
