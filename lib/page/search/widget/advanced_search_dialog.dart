import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/sundry.dart';

class AdvancedSearchDialog extends StatefulWidget {
  final SearchStates initialState;
  final bool allowSourceSwitch;

  const AdvancedSearchDialog({
    super.key,
    required this.initialState,
    this.allowSourceSwitch = true,
  });

  @override
  State<AdvancedSearchDialog> createState() => _AdvancedSearchDialogState();
}

class _AdvancedSearchDialogState extends State<AdvancedSearchDialog> {
  late SearchStates _tempState;

  @override
  void initState() {
    super.initState();
    _tempState = widget.initialState.copyWith();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('高级搜索选项'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.allowSourceSwitch) ...[
            _buildSectionTitle('数据来源'),
            _buildSourceRow(),
          ],

          const SizedBox(height: 16),
          _buildSectionTitle('排序方式'),
          _buildSortRow(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_tempState),
          child: const Text('应用'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSourceRow() {
    final pluginStates = context.watch<PluginRegistryCubit>().state;
    final sources =
        pluginStates.values
            .where((plugin) => plugin.isEnabled && !plugin.isDeleted)
            .toList()
          ..sort((a, b) => a.insertedAt.compareTo(b.insertedAt));

    return Wrap(
      spacing: 8,
      children: sources.map((plugin) {
        final info = PluginRegistryService.I.getCachedPluginInfo(plugin.uuid);
        final name = info?['name']?.toString().trim();
        return ChoiceChip(
          label: Text(
            (name?.isNotEmpty == true ? name! : plugin.uuid).let(t2s),
          ),
          selected: _tempState.from == plugin.uuid,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _tempState = _tempState.copyWith(from: plugin.uuid);
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildSortRow() {
    const Map<int, String> sortOptions = {
      1: '从新到旧',
      2: '从旧到新',
      3: '最多点赞',
      4: '最多观看',
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sortOptions.entries.map((entry) {
        return ChoiceChip(
          label: Text(entry.value.let(t2s)),
          selected: _tempState.sortBy == entry.key,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _tempState = _tempState.copyWith(sortBy: entry.key);
              });
            }
          },
        );
      }).toList(),
    );
  }
}
