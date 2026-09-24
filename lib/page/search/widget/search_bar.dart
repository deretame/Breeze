import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search/method/on_search.dart';
import 'package:zephyr/page/search/widget/search_input_dialog.dart';
import 'package:zephyr/page/search/widget/source_select_dialog.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/util/debouncer.dart';
import 'package:zephyr/widgets/multi_choice_list_dialog.dart';
import 'package:zephyr/widgets/toast.dart';

class SearchBar extends StatefulWidget {
  const SearchBar({super.key, this.aggregateMode = true});

  final bool aggregateMode;

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  Map<String, bool> _aggregateSources = const {};
  // 输入时只同步 TextField 自身状态，cubit 的 keyword 用防抖延迟同步，
  // 避免每敲一个字母就触发上层 BlocBuilder 全量 rebuild。
  final _keywordDebouncer = Debouncer(milliseconds: 100);

  @override
  void dispose() {
    _keywordDebouncer.cancel();
    super.dispose();
  }

  List<({String pluginId, String title})> _sourceOptions(BuildContext context) {
    final pluginStates = context.read<PluginRegistryCubit>().state;
    final states = PluginRegistryService.I.sortPlugins(
      pluginStates.values.where((state) => !state.isDeleted),
    );
    return states.map((state) {
      final info = PluginRegistryService.I.getCachedPluginInfo(state.uuid);
      final title = info?['name']?.toString().trim().isNotEmpty == true
          ? info!['name'].toString().trim()
          : state.uuid;
      return (pluginId: state.uuid, title: title);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    final initialState = context.read<SearchCubit>().state;
    _aggregateSources = Map<String, bool>.from(initialState.aggregateSources);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchStates>(
      builder: (context, state) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.maybePop(),
            ),
            Expanded(
              child: SearchQueryField(
                query: state.searchKeyword,
                autoExpand: true,
                hintText: t.search.searchHint,
                semanticLabel: t.search.title,
                onChanged: (keyword) {
                  _keywordDebouncer.run(() {
                    if (!mounted) {
                      return;
                    }
                    final searchCubit = context.read<SearchCubit>();
                    if (searchCubit.state.searchKeyword == keyword) {
                      return;
                    }
                    searchCubit.update(
                      searchCubit.state.copyWith(searchKeyword: keyword),
                    );
                  });
                },
                onSubmitted: (keyword) => onSearch(
                  context,
                  keyword,
                  aggregateMode: widget.aggregateMode,
                  aggregateSources: _aggregateSources,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () async {
                final searchCubit = context.read<SearchCubit>();
                if (widget.aggregateMode) {
                  final options = _sourceOptions(context);
                  if (_aggregateSources.isEmpty) {
                    _aggregateSources = {
                      for (final source in options) source.pluginId: true,
                    };
                  }
                  final selected = await showSourceSelectDialog(
                    context,
                    initial: _aggregateSources,
                    sourceOptions: options,
                  );
                  if (selected != null && mounted) {
                    searchCubit.update(
                      searchCubit.state.copyWith(
                        aggregateSources: Map<String, bool>.from(selected),
                      ),
                    );
                    setState(() {
                      _aggregateSources = selected;
                    });
                  }
                  return;
                }
                await _showSingleSourceAdvancedSearch(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSingleSourceAdvancedSearch(BuildContext context) async {
    final searchCubit = context.read<SearchCubit>();
    final state = searchCubit.state;
    final source = state.from;

    if (source.trim().isEmpty) {
      showWarningToast(t.search.advancedSearchNotSupported);
      return;
    }
    final scheme = await _loadAdvancedSearchScheme(source, state.pluginExtern);
    if (!context.mounted) {
      return;
    }
    if (scheme == null) {
      showWarningToast(t.search.advancedSearchNotSupported);
      return;
    }

    final newStates = await showDialog<SearchStates>(
      context: context,
      builder: (context) =>
          _PluginAdvancedSearchDialog(initialState: state, scheme: scheme),
    );

    if (newStates != null && context.mounted) {
      searchCubit.update(newStates);
    }
  }

  Future<_AdvancedSearchScheme?> _loadAdvancedSearchScheme(
    String source,
    Map<String, dynamic> extern,
  ) async {
    try {
      final response = await callUnifiedComicPlugin(
        pluginId: source,
        fnPath: 'getAdvancedSearchScheme',
        core: const <String, dynamic>{},
        extern: extern,
      );
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
      _mergeExternValues(fields, extern, values);
      return _AdvancedSearchScheme(
        source: response['source']?.toString() ?? source,
        fields: fields,
        values: values,
      );
    } catch (_) {
      return null;
    }
  }

  void _mergeExternValues(
    List<Map<String, dynamic>> fields,
    Map<String, dynamic> extern,
    Map<String, dynamic> values,
  ) {
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
      title: Text(t.search.advancedSearchOptions),
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
          child: Text(t.common.cancel),
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
              } else if (kind == 'switch') {
                nextExtern[key] = _switchValue(key);
              } else if (kind == 'text') {
                nextExtern[key] = _textValue(key);
              }
            }
            Navigator.of(context).pop(
              widget.initialState.copyWith(
                sortBy: sortBy,
                pluginExtern: nextExtern,
              ),
            );
          },
          child: Text(t.common.apply),
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

    if (kind == 'switch') {
      final current = _switchValue(key);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SwitchListTile(
          value: current,
          title: Text(label),
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            setState(() {
              _values[key] = value;
            });
          },
        ),
      );
    }

    if (kind == 'text') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          initialValue: _textValue(key),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (value) {
            _values[key] = value;
          },
        ),
      );
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
                    selected.isEmpty
                        ? t.search.notSelected
                        : t.search.selectedCount(count: selected.length),
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
                      confirmText: t.common.apply,
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
                  child: Text(t.common.select),
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

  bool _switchValue(String key) {
    final value = _values[key];
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1';
  }

  String _textValue(String key) {
    final value = _values[key];
    return value == null ? '' : value.toString();
  }
}
