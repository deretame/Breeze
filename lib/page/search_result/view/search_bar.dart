import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search/widget/advanced_search_dialog.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/widgets/multi_choice_list_dialog.dart';

class SearchResultBar extends StatelessWidget implements PreferredSizeWidget {
  final SearchEvent searchEvent;

  const SearchResultBar({super.key, required this.searchEvent});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface,
      titleSpacing: 0, // 清除默认边距，完全自定义
      automaticallyImplyLeading: false, // 禁用默认返回键，我们自己画
      // 2. 核心内容区域
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            // 左侧返回按钮
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.maybePop(),
            ),

            // 中间伪装的搜索框 (点击返回上一页)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  final stack = context.router.stack;

                  if (stack.length > 1) {
                    final previousRoute = stack[stack.length - 2];
                    if (previousRoute.name == SearchRoute.name) {
                      context.maybePop();
                    } else {
                      context.replaceRoute(
                        SearchRoute(
                          key: ValueKey(const Uuid().v4()),
                          searchState: searchEvent.searchStates,
                          aggregateMode: false,
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          searchEvent.searchStates.searchKeyword,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
            ),

            // 右侧高级搜索按钮
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () {
                _search(context);
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),

      // 3. 底部分割线
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.5), // 淡淡的分割线
        ),
      ),
    );
  }

  Future<void> _search(BuildContext context) async {
    final searchCubit = context.read<SearchCubit>();
    final source = searchCubit.state.from;
    final scheme = await _loadAdvancedSearchScheme(
      source,
      searchCubit.state.pluginExtern,
    );
    if (!context.mounted) {
      return;
    }
    final newStates = await showDialog<SearchStates>(
      context: context,
      builder: (context) {
        if (scheme == null) {
          return AdvancedSearchDialog(
            initialState: searchCubit.state,
            allowSourceSwitch: false,
          );
        }
        return _PluginAdvancedSearchDialog(
          initialState: searchCubit.state,
          scheme: scheme,
        );
      },
    );

    if (newStates == null) return;
    searchCubit.update(newStates);
    if (!context.mounted) return;

    final searchBloc = context.read<SearchBloc>();
    searchBloc.add(SearchEvent().copyWith(searchStates: searchCubit.state));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1); // 高度要加上分割线

  Future<_AdvancedSearchScheme?> _loadAdvancedSearchScheme(
    String from,
    Map<String, dynamic> extern,
  ) async {
    Map<String, dynamic> response;
    try {
      response = await callUnifiedComicPlugin(
        from: from,
        fnPath: 'get_advanced_search_scheme',
        core: const <String, dynamic>{},
        extern: extern,
      );
    } catch (_) {
      try {
        response = await callUnifiedComicPlugin(
          from: from,
          fnPath: 'getAdvancedSearchScheme',
          core: const <String, dynamic>{},
          extern: extern,
        );
      } catch (_) {
        return null;
      }
    }

    final scheme = Map<String, dynamic>.from(
      (response['scheme'] as Map?) ?? const <String, dynamic>{},
    );
    final data = Map<String, dynamic>.from(
      (response['data'] as Map?) ?? const <String, dynamic>{},
    );
    final fields = ((scheme['fields'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    if (fields.isEmpty) {
      return null;
    }

    final values = Map<String, dynamic>.from(
      (data['values'] as Map?) ?? const <String, dynamic>{},
    );
    for (final field in fields) {
      final key = field['key']?.toString() ?? '';
      if (key.isEmpty || !extern.containsKey(key)) {
        continue;
      }
      final externValue = extern[key];
      if (externValue is Map) {
        values[key] = externValue.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key.toString())
            .toList();
      } else {
        values[key] = externValue;
      }
    }
    return _AdvancedSearchScheme(
      source: response['source']?.toString() ?? from,
      fields: fields,
      values: values,
    );
  }
}

class _AdvancedSearchScheme {
  const _AdvancedSearchScheme({
    required this.source,
    required this.fields,
    required this.values,
  });

  final String source;
  final List<Map<String, dynamic>> fields;
  final Map<String, dynamic> values;
}

class _PluginAdvancedSearchDialog extends StatefulWidget {
  const _PluginAdvancedSearchDialog({
    required this.initialState,
    required this.scheme,
  });

  final SearchStates initialState;
  final _AdvancedSearchScheme scheme;

  @override
  State<_PluginAdvancedSearchDialog> createState() =>
      _PluginAdvancedSearchDialogState();
}

class _PluginAdvancedSearchDialogState
    extends State<_PluginAdvancedSearchDialog> {
  late final Map<String, dynamic> _values;

  @override
  void initState() {
    super.initState();
    _values = Map<String, dynamic>.from(widget.scheme.values);
    _values['sortBy'] = _values['sortBy'] ?? widget.initialState.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('高级搜索选项'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.scheme.fields
            .map((field) => _buildField(context, field))
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final sortBy =
                int.tryParse(_values['sortBy']?.toString() ?? '') ??
                widget.initialState.sortBy;
            final nextExtern = <String, dynamic>{
              ...widget.initialState.pluginExtern,
            };
            for (final field in widget.scheme.fields) {
              final key = field['key']?.toString() ?? '';
              final kind = field['kind']?.toString() ?? '';
              if (key.isEmpty) continue;
              if (kind == 'choice') {
                nextExtern[key] = _values[key];
              } else if (kind == 'multiChoice') {
                nextExtern[key] = _multiValues(key);
              }
            }
            Navigator.of(context).pop(
              widget.initialState.copyWith(
                sortBy: sortBy,
                pluginExtern: nextExtern,
              ),
            );
          },
          child: const Text('应用'),
        ),
      ],
    );
  }

  Widget _buildField(BuildContext context, Map<String, dynamic> field) {
    final key = field['key']?.toString() ?? '';
    final label = field['label']?.toString() ?? key;
    final kind = field['kind']?.toString() ?? 'choice';
    if (key.isEmpty) {
      return const SizedBox.shrink();
    }

    final options = ((field['options'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }
    if (kind == 'multiChoice') {
      final selected = _multiValues(key);
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selected.isEmpty ? '未选择' : '已选择 ${selected.length} 项',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () async {
                    final values = await showMultiChoiceListDialog(
                      context,
                      title: label,
                      options: options
                          .map(
                            (option) => MultiChoiceDialogOption(
                              label:
                                  option['label']?.toString() ??
                                  option['value']?.toString() ??
                                  '',
                              value: option['value']?.toString() ?? '',
                            ),
                          )
                          .toList(),
                      initialSelected: selected,
                      confirmText: '应用',
                      useFilledConfirmButton: true,
                      width: 420,
                      height: 420,
                    );
                    if (values == null) {
                      return;
                    }
                    setState(() {
                      _values[key] = values.toList();
                    });
                  },
                  child: const Text('选择'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (kind != 'choice') {
      return const SizedBox.shrink();
    }

    final current = _values[key]?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final value = option['value']?.toString() ?? '';
              final text = option['label']?.toString() ?? value;
              return ChoiceChip(
                showCheckmark: false,
                label: Text(text),
                selected: current == value,
                onSelected: (selected) {
                  if (!selected) {
                    return;
                  }
                  setState(() {
                    _values[key] = option['value'];
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<String> _multiValues(String key) {
    final value = _values[key];
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (value is Map) {
      return value.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }
}
