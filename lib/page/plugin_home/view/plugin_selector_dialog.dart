import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/i18n/strings.g.dart';

/// 插件选择器：只列出标准位支持的已启用插件，不预调用探测。
Future<String?> showPluginHomeSelector(
  BuildContext context, {
  required List<String> candidates,
  required String selectedId,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) =>
        _PluginSelectorDialog(candidates: candidates, selectedId: selectedId),
  );
}

/// Wrap + ChoiceChip 单选（对齐选择漫画源弹窗），标题直接用 t.search.selectSource，
/// 不再叠二级“漫画源”分组标题；桌面端 AlertDialog 自带限宽。
class _PluginSelectorDialog extends StatelessWidget {
  const _PluginSelectorDialog({
    required this.candidates,
    required this.selectedId,
  });

  final List<String> candidates;
  final String selectedId;

  @override
  Widget build(BuildContext context) {
    // 名字跟着全局 infos 热切换。
    final infos = context
        .select<PluginRegistryCubit, Map<String, Map<String, dynamic>>>(
          (cubit) => cubit.state.infos,
        );
    String nameOf(String uuid) {
      final name = infos[uuid]?['name']?.toString().trim() ?? '';
      return name.isNotEmpty ? name : t.common.loading;
    }

    return AlertDialog(
      title: Text(t.search.selectSource),
      content: SizedBox(
        width: 320,
        child: Wrap(
          alignment: WrapAlignment.start,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final uuid in candidates)
              ChoiceChip(
                label: Text(nameOf(uuid)),
                selected: uuid == selectedId,
                showCheckmark: false,
                onSelected: (_) => Navigator.of(context).pop(uuid),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
      ],
    );
  }
}
