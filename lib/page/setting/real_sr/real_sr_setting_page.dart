import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/type/enum.dart';
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
  RealSrNoiseLevel _noiseLevel = RealSrNoiseLevel.conservative;

  bool _isAvailable = false;
  bool _downloading = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final results = await Future.wait([
      RealSrSettings.loadAutoUpscale(),
      RealSrSettings.loadResolutionThreshold(),
      RealSrSettings.loadConcurrency(),
      RealSrSettings.loadTileSize(),
      RealSrSettings.loadNoiseLevel(),
      RealSrSuperResolution.isAvailable,
    ]);

    if (!mounted) return;

    setState(() {
      _autoUpscale = results[0] as bool;
      _resolutionThreshold = results[1] as RealSrResolutionThreshold;
      _concurrency = results[2] as int;
      _tileSize = results[3] as int;
      _noiseLevel = results[4] as RealSrNoiseLevel;
      _isAvailable = results[5] as bool;
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

  Future<void> _setNoiseLevel(RealSrNoiseLevel value) async {
    await RealSrSettings.saveNoiseLevel(value);
    setState(() => _noiseLevel = value);
  }

  Future<void> _downloadModel() async {
    setState(() {
      _downloading = true;
      _downloadProgress = 0;
    });

    try {
      await RealSrSuperResolution.downloadModel(
        onProgress: (received, total) {
          if (!mounted || total <= 0) return;
          setState(() => _downloadProgress = received / total);
        },
      );
    } catch (e, s) {
      logger.e('RealSR 模型下载失败', error: e, stackTrace: s);
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

  bool get _isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  Widget _buildContent(BuildContext context) {
    return ListView(
      children: [
        _buildSectionTitle(context, '自动超分'),
        SwitchListTile(
          secondary: const Icon(Icons.auto_fix_high_outlined),
          title: const Text('自动超分'),
          subtitle: Text(
            _isDesktop && !_isAvailable
                ? '模型未下载，开启后无法自动超分'
                : '下载或加载图片时自动调用 Real-CUGAN 超分',
          ),
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
        ListTile(
          leading: const Icon(Icons.grid_on_outlined),
          title: const Text('分块大小'),
          subtitle: const Text('遇到崩溃可设置较小值，0为不分块，桌面端可尝试设置为0'),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _realSrTileSizeOptions.contains(_tileSize) ? _tileSize : 0,
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
        ListTile(
          leading: const Icon(Icons.healing_outlined),
          title: const Text('降噪级别'),
          subtitle: const Text('保守适合普通漫画，降噪级别越高涂抹感越强'),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<RealSrNoiseLevel>(
              value: _noiseLevel,
              icon: const Icon(Icons.expand_more),
              onChanged: (RealSrNoiseLevel? value) {
                if (value != null) _setNoiseLevel(value);
              },
              items: RealSrNoiseLevel.values
                  .map(
                    (value) => DropdownMenuItem<RealSrNoiseLevel>(
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

        if (_isDesktop) ...[
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 0.3),
          _buildSectionTitle(context, '模型管理'),
          _buildModelManagementTile(context),
        ],

        const SizedBox(height: 32),
      ],
    );
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
      subtitle: const Text('使用桌面端超分前需要先下载模型'),
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
