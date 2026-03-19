import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/bookshelf/models/events.dart';
import 'package:zephyr/page/ranking_list/widgets/plugin_ranking_filter_dialog.dart';
import 'package:zephyr/type/enum.dart';

import 'ranking_scheme_renderer.dart';

class _RankingFilterBundle {
  const _RankingFilterBundle({
    required this.scheme,
    required this.defaultSelections,
  });

  final Map<String, dynamic> scheme;
  final Map<String, String> defaultSelections;
}

class _ResolvedRankingFilter {
  const _ResolvedRankingFilter({
    required this.selections,
    required this.params,
  });

  final Map<String, String> selections;
  final Map<String, dynamic> params;
}

@RoutePage()
class RankingListPage extends StatefulWidget {
  const RankingListPage({super.key});

  @override
  State<RankingListPage> createState() => _RankingListPageState();
}

class _RankingListPageState extends State<RankingListPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const HotTabBar();
  }
}

class HotTabBar extends StatefulWidget {
  const HotTabBar({super.key});

  @override
  State<HotTabBar> createState() => _HotTabBarState();
}

class _HotTabBarState extends State<HotTabBar> {
  final RankingSchemeRenderer _renderer = RankingSchemeRenderer();
  final Map<From, _RankingFilterBundle> _filterBundles = {};
  final Map<From, Map<String, String>> _filterSelections = {};
  final Map<From, Map<String, dynamic>> _filterParams = {};
  final Map<From, String> _filterErrors = {};
  final Set<From> _loadingFilters = <From>{};

  @override
  Widget build(BuildContext context) {
    final globlalSettingCubit = context.read<GlobalSettingCubit>();
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final currentFrom = globalSettingState.comicChoice == 1 ? From.bika : From.jm;

    _ensureFilterLoaded(currentFrom);

    return Scaffold(
      appBar: AppBar(
        title: Text(_renderer.title(globalSettingState.comicChoice)),
        actions: [
          if (_renderer.showFilter(globalSettingState.comicChoice))
            IconButton(
              icon: const Icon(Icons.filter_alt),
              onPressed: () => _openFilterDialog(currentFrom),
            ),
        ],
      ),
      body: _buildBody(globalSettingState.comicChoice, currentFrom),
      floatingActionButton: (globalSettingState.disableBika ||
              !_renderer.showSwitchFab(globalSettingState.comicChoice))
          ? null
          : FloatingActionButton(
              heroTag: Uuid().v4(),
              child: const Icon(Icons.compare_arrows),
              onPressed: () {
                if (globalSettingState.comicChoice == 1) {
                  globlalSettingCubit.updateState(
                    (current) => current.copyWith(comicChoice: 2),
                  );
                } else {
                  globlalSettingCubit.updateState(
                    (current) => current.copyWith(comicChoice: 1),
                  );
                }

                eventBus.fire(BookShelfEvent());
              },
            ),
    );
  }

  Widget _buildBody(int comicChoice, From currentFrom) {
    if (_loadingFilters.contains(currentFrom) &&
        !_filterParams.containsKey(currentFrom)) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _filterErrors[currentFrom];
    if (error != null && !_filterParams.containsKey(currentFrom)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _reloadFilter(currentFrom),
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    return _renderer.body(
      comicChoice: comicChoice,
      currentFilter: _filterParams[currentFrom] ?? const <String, dynamic>{},
    );
  }

  void _ensureFilterLoaded(From from) {
    if (_filterBundles.containsKey(from) || _loadingFilters.contains(from)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadFilterBundle(from);
      }
    });
  }

  Future<void> _reloadFilter(From from) async {
    _filterBundles.remove(from);
    _filterSelections.remove(from);
    _filterParams.remove(from);
    _filterErrors.remove(from);
    await _loadFilterBundle(from);
  }

  Future<void> _loadFilterBundle(From from) async {
    if (_loadingFilters.contains(from)) {
      return;
    }

    setState(() {
      _loadingFilters.add(from);
      _filterErrors.remove(from);
    });

    try {
      final response = await callUnifiedComicPlugin(
        from: from,
        fnPath: 'getRankingFilterBundle',
        core: const <String, dynamic>{},
        extern: const <String, dynamic>{'source': 'ranking'},
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      final bundle = _parseFilterBundle(envelope);
      final resolved = _resolveRankingFilter(
        bundle,
        _filterSelections[from] ?? const <String, String>{},
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _filterBundles[from] = bundle;
        _filterSelections[from] = resolved.selections;
        _filterParams[from] = resolved.params;
        _loadingFilters.remove(from);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _filterErrors[from] = e.toString();
        _loadingFilters.remove(from);
      });
    }
  }

  Future<void> _openFilterDialog(From from) async {
    if (!_filterBundles.containsKey(from)) {
      await _loadFilterBundle(from);
    }

    final bundle = _filterBundles[from];
    if (!mounted || bundle == null) {
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => PluginRankingFilterDialog(
        scheme: bundle.scheme,
        initialSelections:
            _filterSelections[from] ?? bundle.defaultSelections,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    final resolved = _resolveRankingFilter(bundle, result);
    setState(() {
      _filterSelections[from] = resolved.selections;
      _filterParams[from] = resolved.params;
    });
  }

  _RankingFilterBundle _parseFilterBundle(UnifiedPluginEnvelope envelope) {
    final values = asMap(envelope.data['values']);
    final defaults = <String, String>{};
    values.forEach((key, value) {
      defaults[key] = value?.toString() ?? '';
    });

    return _RankingFilterBundle(
      scheme: envelope.scheme,
      defaultSelections: defaults,
    );
  }

  _ResolvedRankingFilter _resolveRankingFilter(
    _RankingFilterBundle bundle,
    Map<String, String> requestedSelections,
  ) {
    final selections = <String, String>{};
    final params = <String, dynamic>{};
    final fields = asList(bundle.scheme['fields']).map((item) => asMap(item));

    for (final field in fields) {
      if (field['kind']?.toString() != 'choice') {
        continue;
      }

      final key = field['key']?.toString() ?? '';
      if (key.isEmpty) {
        continue;
      }

      final options = asList(field['options']).map((item) => asMap(item)).toList();
      if (options.isEmpty) {
        continue;
      }

      final requestedValue = requestedSelections[key]?.trim() ?? '';
      final fallbackValue = bundle.defaultSelections[key]?.trim() ?? '';
      final selected = _findOptionByValue(
            options,
            requestedValue.isNotEmpty ? requestedValue : fallbackValue,
          ) ??
          options.first;

      final selectedValue = selected['value']?.toString() ?? '';
      selections[key] = selectedValue;
      params.addAll(asMap(selected['result']));
    }

    return _ResolvedRankingFilter(selections: selections, params: params);
  }

  Map<String, dynamic>? _findOptionByValue(
    List<Map<String, dynamic>> options,
    String value,
  ) {
    for (final option in options) {
      if (option['value']?.toString() == value) {
        return option;
      }
    }
    return null;
  }
}
