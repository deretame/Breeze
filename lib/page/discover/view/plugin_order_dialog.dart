import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';

Future<void> showPluginOrderDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) => PluginOrderDialog(
      initialPlugins: PluginRegistryService.I.orderedPlugins(),
    ),
  );
}

class PluginOrderDialog extends StatefulWidget {
  const PluginOrderDialog({super.key, required this.initialPlugins});

  final List<PluginRuntimeState> initialPlugins;

  @override
  State<PluginOrderDialog> createState() => _PluginOrderDialogState();
}

class _PluginOrderDialogState extends State<PluginOrderDialog> {
  late final List<PluginRuntimeState> _plugins = [...widget.initialPlugins];
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final maxHeight = (MediaQuery.sizeOf(context).height - 220)
        .clamp(220.0, 560.0)
        .toDouble();

    return AlertDialog(
      title: Text(t.discover.customOrder),
      content: SizedBox(
        width: 420,
        height: maxHeight,
        child: ReorderableListView.builder(
          buildDefaultDragHandles: false,
          itemCount: _plugins.length,
          itemBuilder: (context, index) {
            final plugin = _plugins[index];
            return _PluginOrderRow(
              key: ValueKey(plugin.uuid),
              plugin: plugin,
              index: index,
            );
          },
          onReorderItem: (oldIndex, newIndex) {
            setState(() {
              final plugin = _plugins.removeAt(oldIndex);
              _plugins.insert(newIndex, plugin);
            });
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : _reset,
          child: Text(t.discover.resetOrder),
        ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.common.apply),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await PluginRegistryService.I.reorderPlugins(
      _plugins.map((plugin) => plugin.uuid).toList(),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _reset() async {
    setState(() => _saving = true);
    await PluginRegistryService.I.resetPluginOrder();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// 排序单行：独立 widget 订阅自己的名字，热切换只重建该行。
/// 不能在 ReorderableListView itemBuilder 里用 select（sliver 上下文断言）。
class _PluginOrderRow extends StatelessWidget {
  const _PluginOrderRow({super.key, required this.plugin, required this.index});

  final PluginRuntimeState plugin;
  final int index;

  @override
  Widget build(BuildContext context) {
    final name = context.select<PluginRegistryCubit, String>(
      (cubit) => cubit.state.pluginName(plugin.uuid),
    );
    return ListTile(
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: plugin.isActive ? null : Text(t.discover.disabled),
      trailing: ReorderableDragStartListener(
        index: index,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.drag_handle),
        ),
      ),
    );
  }
}
