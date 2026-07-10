import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/coreml_model_config.dart';
import 'package:zephyr/page/setting/real_sr/service/android_ncnn_model_config.dart';
import 'package:zephyr/page/setting/real_sr/service/desktop_ncnn_model_config.dart';
import 'package:zephyr/page/setting/real_sr/service/real_sr_settings.dart';
import 'package:zephyr/page/setting/real_sr/service/real_sr_super_resolution.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/widgets/toast.dart';

import '../common/setting_ui.dart';

final Map<int, String> _realSrConcurrencyLabels = {
  1: '1',
  2: '2',
  4: '4',
  6: '6',
  8: '8',
  0: t.realSr.unlimited,
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
      showErrorToast('${t.realSr.modelDownloadFailed}: $e');
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
        title: Text(
          t.realSr.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
        _buildSectionTitle(context, t.realSr.autoUpscaleSection),
        SwitchListTile(
          secondary: const Icon(Icons.auto_fix_high_outlined),
          title: Text(t.realSr.autoUpscale),
          subtitle: Text(
            !_isAvailable
                ? t.realSr.autoUpscaleSubtitleUnavailable
                : t.realSr.autoUpscaleSubtitleAvailable,
          ),
          thumbIcon: kSettingSwitchThumbIcon,
          value: _autoUpscale,
          onChanged: _setAutoUpscale,
        ),

        const SizedBox(height: 8),
        const Divider(height: 1, thickness: 0.3),
        _buildSectionTitle(context, t.realSr.conditionSection),
        ListTile(
          leading: const Icon(Icons.hd_outlined),
          title: Text(t.realSr.resolutionThreshold),
          subtitle: Text(t.realSr.resolutionThresholdSubtitle),
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
        _buildSectionTitle(context, t.realSr.performanceSection),
        ListTile(
          leading: const Icon(Icons.speed_outlined),
          title: Text(t.realSr.concurrency),
          subtitle: Text(t.realSr.concurrencySubtitle),
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
            title: Text(t.realSr.tileSize),
            subtitle: Text(t.realSr.tileSizeSubtitle),
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
        _buildSectionTitle(context, t.realSr.modelSection),

        // iOS / macOS：使用 CoreML，模型族 + 变体 + 分块信息。
        if (_usesCoreML) ...[
          ListTile(
            leading: const Icon(Icons.speed_outlined),
            title: Text(t.realSr.model),
            subtitle: Text(t.realSr.modelSubtitle),
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
                        child: Text(value.localizedLabel),
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
            title: Text(t.realSr.noiseLevel),
            subtitle: Text(t.realSr.noiseLevelSubtitle),
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
                        child: Text(value.localizedDisplayName),
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
            title: Text(t.realSr.blockInfo),
            subtitle: Text(_coreMLBlockInfo),
            trailing: Tooltip(
              triggerMode: TooltipTriggerMode.tap,
              showDuration: const Duration(seconds: 5),
              message: t.realSr.blockInfoTooltip,
              child: const Icon(Icons.help_outline),
            ),
          ),
        ] else if (Platform.isAndroid) ...[
          // Android：固定使用 waifu2x upconv CLI，不暴露策略/降噪选项。
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(t.realSr.androidSuperResolution),
            subtitle: Text(t.realSr.androidSuperResolutionSubtitle),
          ),
        ] else ...[
          // Windows / Linux：与 Android 保持一致的策略 + 降噪档位。
          ListTile(
            leading: const Icon(Icons.speed_outlined),
            title: Text(t.realSr.desktopStrategy),
            subtitle: Text(t.realSr.desktopStrategySubtitle),
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
            title: Text(t.realSr.desktopNoiseLevel),
            subtitle: Text(t.realSr.desktopNoiseLevelSubtitle),
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
        _buildSectionTitle(context, t.realSr.modelManagementSection),
        _buildModelManagementTile(context),

        const SizedBox(height: 32),
      ],
    );
  }

  String get _coreMLBlockInfo {
    final blockSize = _coreMLVariant.config['blockSize'] as int? ?? 0;
    final shrinkSize = _coreMLVariant.config['shrinkSize'] as int? ?? 0;
    final contentSize = CoreMLModelConfig.contentBlockSize(_coreMLVariant);
    return t.realSr.blockInfoFormat(
      contentSize: contentSize,
      blockSize: blockSize,
      shrinkSize: shrinkSize,
    );
  }

  Widget _buildModelManagementTile(BuildContext context) {
    if (_downloading) {
      return ListTile(
        leading: const Icon(Icons.downloading_outlined),
        title: Text(t.realSr.downloadingModel),
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
        title: Text(t.realSr.modelReady),
        trailing: TextButton(
          onPressed: _downloadModel,
          child: Text(t.realSr.redownload),
        ),
      );
    }

    return ListTile(
      leading: const Icon(Icons.warning_amber_rounded),
      title: Text(t.realSr.modelNotDownloaded),
      subtitle: Text(t.realSr.modelNotDownloadedSubtitle),
      trailing: ElevatedButton(
        onPressed: _downloadModel,
        child: Text(t.realSr.downloadModel),
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
