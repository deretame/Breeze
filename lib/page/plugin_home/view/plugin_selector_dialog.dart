import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/widgets/plugin_icon.dart';

/// 插件选择器：只列出标准位支持的已启用插件，不预调用探测。
Future<String?> showPluginHomeSelector(
  BuildContext context, {
  required List<String> candidates,
  required String selectedId,
  required String title,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PluginSelectorDialog(
      candidates: candidates,
      selectedId: selectedId,
      title: title,
    ),
  );
}

class _PluginSelectorDialog extends StatefulWidget {
  const _PluginSelectorDialog({
    required this.candidates,
    required this.selectedId,
    required this.title,
  });

  final List<String> candidates;
  final String selectedId;
  final String title;

  @override
  State<_PluginSelectorDialog> createState() => _PluginSelectorDialogState();
}

class _PluginSelectorDialogState extends State<_PluginSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 名字跟着全局 infos 热切换：这里 watch 整个 infos map，
    // 行级用独立 widget 读，避免整列表无意义重建（行数少，可接受）。
    final infos = context
        .select<PluginRegistryCubit, Map<String, Map<String, dynamic>>>(
          (cubit) => cubit.state.infos,
        );
    final query = _query.trim().toLowerCase();
    String nameOf(String uuid) {
      final name = infos[uuid]?['name']?.toString().trim() ?? '';
      return name.isNotEmpty ? name : uuid;
    }

    final visible = widget.candidates.where((uuid) {
      if (query.isEmpty) {
        return true;
      }
      final name = nameOf(uuid).toLowerCase();
      return name.contains(query) || uuid.toLowerCase().contains(query);
    }).toList();

    return AlertDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.only(top: 8),
      content: SizedBox(
        width: 420,
        height: 440,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: t.common.search,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: visible.isEmpty
                  ? Center(child: Text(t.discover.noPlugins))
                  : ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final uuid = visible[index];
                        return _PluginSelectorRow(
                          uuid: uuid,
                          selected: uuid == widget.selectedId,
                        );
                      },
                    ),
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

/// 选择器单行：独立 widget，用 watch 读自己的名字和图标，
/// 热切换时只重建受影响的行。不能在 sliver itemBuilder 里用 select。
class _PluginSelectorRow extends StatelessWidget {
  const _PluginSelectorRow({required this.uuid, required this.selected});

  final String uuid;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final registry = context.watch<PluginRegistryCubit>().state;
    // 搜索过滤用的是打开时的快照名，这里实时读，保证改名即时生效。
    final liveName = registry.pluginName(uuid);
    final iconUrl = registry.pluginIconUrl(uuid)?.trim() ?? '';
    return ListTile(
      leading: SizedBox(
        width: 40,
        height: 40,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: PluginIcon(
            url: iconUrl,
            placeholder: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(child: Icon(Icons.extension_outlined)),
            ),
          ),
        ),
      ),
      title: Text(liveName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: liveName == uuid
          ? null
          : Text(uuid, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: selected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () => Navigator.of(context).pop(uuid),
    );
  }
}
