import 'package:auto_route/annotations.dart';
import 'package:zephyr/util/ui/fluent_compat.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/widgets/app_scaffold_page.dart';

@RoutePage()
class ShowColorPage extends StatelessWidget {
  const ShowColorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final allColors = context.theme.colorScheme;

    final screenWidth = MediaQuery.of(context).size.width;
    final colorBoxSize = screenWidth / 3;

    // 将所有颜色属性映射到一个列表中
    final colorEntries = [
      _ColorEntry('primary', allColors.primary),
      _ColorEntry('onPrimary', allColors.onPrimary),
      _ColorEntry('primaryContainer', allColors.primaryContainer),
      _ColorEntry('onPrimaryContainer', allColors.onPrimaryContainer),
      _ColorEntry('primaryFixedDim', allColors.primaryFixedDim),
      _ColorEntry('secondaryContainer', allColors.secondaryContainer),
      _ColorEntry('onSecondaryContainer', allColors.onSecondaryContainer),
      _ColorEntry('secondaryFixed', allColors.secondaryFixed),
      _ColorEntry('secondaryFixedDim', allColors.secondaryFixedDim),
      _ColorEntry('tertiary', allColors.tertiary),
      _ColorEntry('error', allColors.error),
      _ColorEntry('outline', allColors.outline),
      _ColorEntry('outlineVariant', allColors.outlineVariant),
      _ColorEntry('surface', allColors.surface),
      _ColorEntry('onSurface', allColors.onSurface),
      _ColorEntry('surfaceBright', allColors.surfaceBright),
      _ColorEntry('surfaceContainerLow', allColors.surfaceContainerLow),
      _ColorEntry('surfaceContainerHigh', allColors.surfaceContainerHigh),
      _ColorEntry('surfaceContainerHighest', allColors.surfaceContainerHighest),
      _ColorEntry('onSurfaceVariant', allColors.onSurfaceVariant),
      _ColorEntry('onInverseSurface', allColors.onInverseSurface),
      _ColorEntry('surfaceTint', allColors.surfaceTint),
    ];

    return AppScaffoldPage(
      title: const Text('Color Showcase'),
      content: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 每行显示 3 个颜色块
          childAspectRatio: 1, // 正方形
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
                  color: _getContrastColor(entry.color), // 根据背景色选择对比色
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }

  // 根据背景色选择对比色（黑色或白色）
  Color _getContrastColor(Color backgroundColor) {
    // 计算亮度
    final brightness = backgroundColor.computeLuminance();
    return brightness > 0.5 ? Colors.black : Colors.white;
  }
}

// 辅助类，用于存储颜色名称和颜色值
class _ColorEntry {
  final String name;
  final Color color;

  _ColorEntry(this.name, this.color);
}
