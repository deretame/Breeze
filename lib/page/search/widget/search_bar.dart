import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search/method/on_search.dart';
import 'package:zephyr/page/search/widget/source_select_dialog.dart';
import 'package:zephyr/widgets/multi_choice_list_dialog.dart';
import 'package:zephyr/widgets/toast.dart';

class SearchBar extends StatefulWidget {
  const SearchBar({super.key, this.aggregateMode = true});

  final bool aggregateMode;

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Map<String, bool> _aggregateSources = const {};

  List<({String pluginId, String title})> _sourceOptions(BuildContext context) {
    final pluginStates = context.read<PluginRegistryCubit>().state;
    final states =
        pluginStates.values.where((state) => !state.isDeleted).toList()
          ..sort((a, b) => a.insertedAt.compareTo(b.insertedAt));
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
    final initialKeyword = context.read<SearchCubit>().state.searchKeyword;
    if (initialKeyword.isNotEmpty) {
      _controller.text = initialKeyword;
    }
    _controller.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      if (route is PageRoute && route.animation != null) {
        if (route.animation!.isCompleted) {
          _focusNode.requestFocus();
        } else {
          route.animation!.addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              _focusNode.requestFocus();
            }
          });
        }
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<SearchCubit, SearchStates>(
      listenWhen: (previous, current) =>
          previous.searchKeyword != current.searchKeyword,
      listener: (context, state) {
        if (_controller.text != state.searchKeyword) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _controller.text = state.searchKeyword;
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length),
              );
            }
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.maybePop(),
            ),
            Expanded(
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
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (keyword) => onSearch(
                          context,
                          keyword,
                          aggregateMode: widget.aggregateMode,
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: '搜索...',
                          border: InputBorder.none,
                          isDense: true,
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.cancel, size: 20),
                        onPressed: () => _controller.clear(),
                      ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () async {
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
                    setState(() {
                      _aggregateSources = selected;
                    });
                  }
                  return;
                }
                await _showSingleSourceAdvancedSearch(context);
              },
            ),
            TextButton(
              onPressed: () => onSearch(
                context,
                _controller.text,
                aggregateMode: widget.aggregateMode,
                aggregateSources: _aggregateSources,
              ),
              child: const Text("搜索"),
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
      showWarningToast('当前插件不支持高级搜索');
      return;
    }
    final scheme = await _loadAdvancedSearchScheme(source, state.pluginExtern);
    if (!context.mounted) {
      return;
    }
    if (scheme == null) {
      showWarningToast('当前插件不支持高级搜索');
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
