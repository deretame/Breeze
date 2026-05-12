import 'package:auto_route/annotations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:zephyr/util/font/font_profile.dart';
import 'package:zephyr/widgets/toast.dart';

@RoutePage()
class FontSettingPage extends StatelessWidget {
  const FontSettingPage({super.key});

  static const _weights = <int>[100, 200, 300, 400, 500, 600, 700, 800, 900];
  static const _sampleText = 'Innovation in China 中国智造，慧及全球 0123456789';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '字体设置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: '清空',
            onPressed: _clearAll,
            icon: const Icon(Icons.restart_alt_outlined),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: FontProfileController.instance,
        builder: (context, _) {
          final controller = FontProfileController.instance;
          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('按字重分别选择字体文件。'),
              ),
              ..._weights.map((weight) {
                final filePath = controller.pathForWeight(weight) ?? '';
                return _FontWeightTile(
                  weight: weight,
                  label: fontWeightLabels[weight]!,
                  filePath: filePath,
                  sampleText: _sampleText,
                  onPick: () => _pickWeight(weight),
                  onClear: filePath.isEmpty
                      ? null
                      : () => _saveWeight(weight, ''),
                );
              }),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickWeight(int weight) async {
    const typeGroup = XTypeGroup(
      label: 'font',
      extensions: ['ttf', 'otf', 'ttc'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    await _saveWeight(weight, file.path);
  }

  Future<void> _saveWeight(int weight, String filePath) async {
    final ok = await FontProfileController.instance.setPath(weight, filePath);
    if (!ok) {
      showErrorToast('字体加载失败');
      return;
    }
    showSuccessToast(filePath.isEmpty ? '已清除' : '已保存');
  }

  Future<void> _clearAll() async {
    await FontProfileController.instance.clearAll();
    showSuccessToast('已清空');
  }
}

class _FontWeightTile extends StatelessWidget {
  const _FontWeightTile({
    required this.weight,
    required this.label,
    required this.filePath,
    required this.sampleText,
    required this.onPick,
    required this.onClear,
  });

  final int weight;
  final String label;
  final String filePath;
  final String sampleText;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fontWeight = _toFontWeight(weight);
    final previewStyle = FontProfileController.instance.applyStyleForWeight(
      TextStyle(fontWeight: fontWeight, fontSize: 16),
      weight,
    );

    return ListTile(
      leading: SizedBox(
        width: 86,
        child: Text(
          'w$weight\n$label',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(
        filePath.isEmpty ? '未选择文件' : path.basename(filePath),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (filePath.isNotEmpty)
              Text(
                filePath,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            Text(sampleText, style: previewStyle),
          ],
        ),
      ),
      trailing: Wrap(
        spacing: 4,
        children: [
          if (onClear != null)
            IconButton(
              tooltip: '清除',
              onPressed: onClear,
              icon: const Icon(Icons.close_outlined),
            ),
          IconButton(
            tooltip: '选择文件',
            onPressed: onPick,
            icon: const Icon(Icons.folder_open_outlined),
          ),
        ],
      ),
    );
  }

  FontWeight _toFontWeight(int weight) {
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
      default:
        return FontWeight.w900;
    }
  }
}
