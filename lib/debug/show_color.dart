import 'dart:io';
import 'dart:ui' as ui;

import 'package:auto_route/annotations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zephyr/util/context/context_extensions.dart';

const _defaultFontPath =
    r'C:\Users\windy\Downloads\zip\03_NotoSerifCJK-TTF-VF\Variable\TTF\Subset\NotoSerifSC-VF.ttf';

@RoutePage()
class ShowColorPage extends StatefulWidget {
  const ShowColorPage({super.key});

  @override
  State<ShowColorPage> createState() => _ShowColorPageState();
}

class _ShowColorPageState extends State<ShowColorPage> {
  static const _sampleText = '风急天高猿啸哀 ABC123 漫画信息 标题粗体';
  static const _weights = <int>[400, 500, 600, 700, 800, 900];

  String? _fontFamily;
  String? _fontPath;
  String? _status;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final allColors = context.theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final colorBoxSize = screenWidth / 3;

    final colorEntries = [
      _ColorEntry('primary', allColors.primary),
      _ColorEntry('onPrimary', allColors.onPrimary),
      _ColorEntry('primaryContainer', allColors.primaryContainer),
      _ColorEntry('onPrimaryContainer', allColors.onPrimaryContainer),
      _ColorEntry('primaryFixed', allColors.primaryFixed),
      _ColorEntry('primaryFixedDim', allColors.primaryFixedDim),
      _ColorEntry('onPrimaryFixed', allColors.onPrimaryFixed),
      _ColorEntry('onPrimaryFixedVariant', allColors.onPrimaryFixedVariant),
      _ColorEntry('secondary', allColors.secondary),
      _ColorEntry('onSecondary', allColors.onSecondary),
      _ColorEntry('secondaryContainer', allColors.secondaryContainer),
      _ColorEntry('onSecondaryContainer', allColors.onSecondaryContainer),
      _ColorEntry('secondaryFixed', allColors.secondaryFixed),
      _ColorEntry('secondaryFixedDim', allColors.secondaryFixedDim),
      _ColorEntry('onSecondaryFixed', allColors.onSecondaryFixed),
      _ColorEntry('onSecondaryFixedVariant', allColors.onSecondaryFixedVariant),
      _ColorEntry('tertiary', allColors.tertiary),
      _ColorEntry('onTertiary', allColors.onTertiary),
      _ColorEntry('tertiaryContainer', allColors.tertiaryContainer),
      _ColorEntry('onTertiaryContainer', allColors.onTertiaryContainer),
      _ColorEntry('tertiaryFixed', allColors.tertiaryFixed),
      _ColorEntry('tertiaryFixedDim', allColors.tertiaryFixedDim),
      _ColorEntry('onTertiaryFixed', allColors.onTertiaryFixed),
      _ColorEntry('onTertiaryFixedVariant', allColors.onTertiaryFixedVariant),
      _ColorEntry('error', allColors.error),
      _ColorEntry('onError', allColors.onError),
      _ColorEntry('errorContainer', allColors.errorContainer),
      _ColorEntry('onErrorContainer', allColors.onErrorContainer),
      _ColorEntry('outline', allColors.outline),
      _ColorEntry('outlineVariant', allColors.outlineVariant),
      _ColorEntry('surface', allColors.surface),
      _ColorEntry('onSurface', allColors.onSurface),
      _ColorEntry('surfaceDim', allColors.surfaceDim),
      _ColorEntry('surfaceBright', allColors.surfaceBright),
      _ColorEntry('surfaceContainerLowest', allColors.surfaceContainerLowest),
      _ColorEntry('surfaceContainerLow', allColors.surfaceContainerLow),
      _ColorEntry('surfaceContainer', allColors.surfaceContainer),
      _ColorEntry('surfaceContainerHigh', allColors.surfaceContainerHigh),
      _ColorEntry('surfaceContainerHighest', allColors.surfaceContainerHighest),
      _ColorEntry('onSurfaceVariant', allColors.onSurfaceVariant),
      _ColorEntry('inverseSurface', allColors.inverseSurface),
      _ColorEntry('onInverseSurface', allColors.onInverseSurface),
      _ColorEntry('inversePrimary', allColors.inversePrimary),
      _ColorEntry('shadow', allColors.shadow),
      _ColorEntry('scrim', allColors.scrim),
      _ColorEntry('surfaceTint', allColors.surfaceTint),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Color Showcase')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildFontTester(context),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
            ),
            itemCount: colorEntries.length,
            itemBuilder: (context, index) {
              final entry = colorEntries[index];
              return Container(
                width: colorBoxSize,
                height: colorBoxSize,
                color: entry.color,
                child: Center(
                  child: Text(
                    entry.name,
                    style: TextStyle(
                      color: _getContrastColor(entry.color),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFontTester(BuildContext context) {
    final theme = Theme.of(context);
    final hasFont = _fontFamily != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Variable Font 测试',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFont
                  ? '已加载: ${_fontPath ?? _fontFamily}'
                  : '还没加载字体，先试推荐样本或者手动选一个 TTF/OTF 文件。',
              style: theme.textTheme.bodySmall,
            ),
            if (_status != null) ...[
              const SizedBox(height: 8),
              Text(
                _status!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _loading
                      ? null
                      : () => _loadFontFromPath(_defaultFontPath),
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('加载推荐样本'),
                ),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _pickFontFile,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('选择字体文件'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDefaultWeightPreview(context),
            const SizedBox(height: 16),
            if (hasFont) ...[
              _buildWeightPreview(
                context,
                title: '按 fontWeight 渲染',
                builder: (weight) => TextStyle(
                  fontFamily: _fontFamily,
                  fontWeight: _asFontWeight(weight),
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 16),
              _buildWeightPreview(
                context,
                title: '按 variable axis 渲染',
                builder: (weight) => TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 24,
                  fontVariations: [ui.FontVariation('wght', weight.toDouble())],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultWeightPreview(BuildContext context) {
    return _buildWeightPreview(
      context,
      title: '系统默认字体对照',
      builder: (weight) =>
          TextStyle(fontWeight: _asFontWeight(weight), fontSize: 24),
    );
  }

  Widget _buildWeightPreview(
    BuildContext context, {
    required String title,
    required TextStyle Function(int weight) builder,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ..._weights.map(
          (weight) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    'w$weight',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'JetBrainsMonoNL-Regular',
                    ),
                  ),
                ),
                Expanded(child: Text(_sampleText, style: builder(weight))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFontFile() async {
    const typeGroup = XTypeGroup(
      label: 'font',
      extensions: ['ttf', 'otf', 'ttc'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    await _loadFontFromPath(file.path);
  }

  Future<void> _loadFontFromPath(String path) async {
    setState(() {
      _loading = true;
      _status = '正在加载字体...';
    });

    try {
      final bytes = await File(path).readAsBytes();
      final family = 'debug-font-${DateTime.now().millisecondsSinceEpoch}';
      final loader = FontLoader(family);
      loader.addFont(Future.value(_toByteData(bytes)));
      await loader.load();

      if (!mounted) return;
      setState(() {
        _fontFamily = family;
        _fontPath = path;
        _status = '加载成功，可以直接对比不同字重。';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = '加载失败: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  ByteData _toByteData(Uint8List bytes) {
    return ByteData.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
  }

  FontWeight _asFontWeight(int weight) {
    switch (weight) {
      case 100:
        return FontWeight.w100;
      case 200:
        return FontWeight.w200;
      case 300:
        return FontWeight.w300;
      case 400:
        return FontWeight.w400;
      case 500:
        return FontWeight.w500;
      case 600:
        return FontWeight.w600;
      case 700:
        return FontWeight.w700;
      case 800:
        return FontWeight.w800;
      case 900:
        return FontWeight.w900;
      default:
        return FontWeight.w400;
    }
  }

  Color _getContrastColor(Color backgroundColor) {
    final brightness = backgroundColor.computeLuminance();
    return brightness > 0.5 ? Colors.black : Colors.white;
  }
}

class _ColorEntry {
  final String name;
  final Color color;

  _ColorEntry(this.name, this.color);
}
