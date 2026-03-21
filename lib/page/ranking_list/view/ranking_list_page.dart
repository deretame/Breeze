import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/bookshelf/models/events.dart';
import 'package:zephyr/page/ranking_list/models/plugin_ranking_filter_schema.dart';
import 'package:zephyr/page/ranking_list/view/plugin_paged_comic_list_view.dart';
import 'package:zephyr/page/ranking_list/widgets/plugin_ranking_filter_dialog.dart';
import 'package:zephyr/type/enum.dart';

import 'ranking_scheme_renderer.dart';

class _RankingFilterBundle {
  const _RankingFilterBundle({
    required this.scheme,
    required this.defaultSelections,
  });

  final PluginRankingFilterSchema scheme;
  final Map<String, String> defaultSelections;
}

enum RankingListMode { standard, weekRanking, timeRanking }

@RoutePage()
class RankingListPage extends StatefulWidget {
  const RankingListPage({
    super.key,
    this.title,
    this.mode = RankingListMode.standard,
    this.contextTag,
  });

  final String? title;
  final RankingListMode mode;
  final String? contextTag;

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
    return HotTabBar(
      title: widget.title,
      mode: widget.mode,
      contextTag: widget.contextTag,
    );
  }
}

class HotTabBar extends StatefulWidget {
  const HotTabBar({super.key, this.title, required this.mode, this.contextTag});

  final String? title;
  final RankingListMode mode;
  final String? contextTag;

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
    final currentFrom =
        widget.mode == RankingListMode.weekRanking ||
            widget.mode == RankingListMode.timeRanking
        ? From.jm
        : (globalSettingState.comicChoice == 1 ? From.bika : From.jm);

    _ensureFilterLoaded(currentFrom);

    final title =
        widget.title ??
        (widget.mode == RankingListMode.weekRanking
            ? '每周连载更新'
            : widget.mode == RankingListMode.timeRanking
            ? '排行榜'
            : _renderer.title(globalSettingState.comicChoice));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_showFilter(globalSettingState.comicChoice))
            IconButton(
              icon: const Icon(Icons.filter_alt),
              onPressed: () => _openFilterDialog(currentFrom),
            ),
        ],
      ),
      body: _buildBody(globalSettingState.comicChoice, currentFrom),
      floatingActionButton:
          (widget.mode == RankingListMode.weekRanking ||
              widget.mode == RankingListMode.timeRanking ||
              globalSettingState.disableBika ||
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

    final currentFilter =
        _filterParams[currentFrom] ?? const <String, dynamic>{};
    if (widget.mode == RankingListMode.weekRanking) {
      final week = _toInt(currentFilter['date'], 1);
      final type = currentFilter['type']?.toString() ?? 'all';
      return PluginPagedComicListView(
        key: ValueKey('week_ranking_${week}_$type'),
        from: From.jm,
        fnPath: 'getWeekRankingData',
        coreBuilder: (page) => {'date': week, 'type': type, 'page': page},
        externBuilder: (_) => const {'source': 'weekRanking'},
        itemMapper: (item) => item,
      );
    }

    if (widget.mode == RankingListMode.timeRanking) {
      final type = currentFilter['type']?.toString() ?? 'all';
      final order = currentFilter['order']?.toString() ?? 'new';
      return PluginPagedComicListView(
        key: ValueKey('time_ranking_${type}_$order'),
        from: From.jm,
        fnPath: 'getRankingData',
        coreBuilder: (page) => {'page': page},
        externBuilder: (_) => {
          'type': type,
          'order': order,
          'source': 'ranking',
        },
        itemMapper: (item) => item,
      );
    }

    return _renderer.body(
      comicChoice: comicChoice,
      currentFilter: currentFilter,
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
        fnPath: _filterBundleFnPath,
        core: {
          if (widget.mode == RankingListMode.timeRanking)
            'tag': widget.contextTag ?? '',
        },
        extern: {
          'source': widget.mode == RankingListMode.weekRanking
              ? 'weekRanking'
              : widget.mode == RankingListMode.timeRanking
              ? 'timeRanking'
              : 'ranking',
        },
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
        initialSelections: _filterSelections[from] ?? bundle.defaultSelections,
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
      scheme: PluginRankingFilterSchema.fromMap(envelope.scheme),
      defaultSelections: defaults,
    );
  }

  PluginResolvedRankingFilter _resolveRankingFilter(
    _RankingFilterBundle bundle,
    Map<String, String> requestedSelections,
  ) {
    return bundle.scheme.resolve(
      requestedSelections: requestedSelections,
      defaultSelections: bundle.defaultSelections,
    );
  }

  bool _showFilter(int comicChoice) {
    if (widget.mode == RankingListMode.weekRanking) {
      return true;
    }
    if (widget.mode == RankingListMode.timeRanking) {
      return true;
    }
    return _renderer.showFilter(comicChoice);
  }

  String get _filterBundleFnPath {
    return switch (widget.mode) {
      RankingListMode.weekRanking => 'getWeekRankingFilterBundle',
      RankingListMode.timeRanking => 'getTimeRankingFilterBundle',
      _ => 'getRankingFilterBundle',
    };
  }

  int _toInt(dynamic value, int fallback) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
