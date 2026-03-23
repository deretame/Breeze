import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_list/models/comic_list_scene.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/bookshelf/models/events.dart';
import 'package:zephyr/page/comic_list/scene_filter/plugin_list_filter_dialog.dart';
import 'package:zephyr/page/comic_list/scene_filter/plugin_list_filter_schema.dart';
import 'package:zephyr/page/comic_list/view/plugin_paged_comic_list_view.dart';
import 'package:zephyr/page/comic_list/view/plugin_paged_creator_list_view.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/json/json_value.dart';

class _ListFilterBundle {
  const _ListFilterBundle({
    required this.scheme,
    required this.defaultSelections,
  });

  final PluginListFilterSchema scheme;
  final Map<String, String> defaultSelections;
}

@RoutePage()
class ComicListPage extends StatefulWidget {
  const ComicListPage({super.key, this.title, this.scene});

  final String? title;
  final ComicListScene? scene;

  @override
  State<ComicListPage> createState() => _ComicListPageState();
}

class _ComicListPageState extends State<ComicListPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ComicListScaffold(title: widget.title, scene: widget.scene);
  }
}

class ComicListScaffold extends StatefulWidget {
  const ComicListScaffold({super.key, this.title, this.scene});

  final String? title;
  final ComicListScene? scene;

  @override
  State<ComicListScaffold> createState() => _ComicListScaffoldState();
}

class _ComicListScaffoldState extends State<ComicListScaffold> {
  final Map<From, ComicListScene> _defaultScenes = {};
  final Map<From, _ListFilterBundle> _filterBundles = {};
  final Map<From, Map<String, String>> _filterSelections = {};
  final Map<From, Map<String, dynamic>> _filterParams = {};
  final Map<From, Map<String, dynamic>> _filterCoreParams = {};
  final Map<From, Map<String, dynamic>> _filterExternParams = {};
  final Map<From, String> _sceneErrors = {};
  final Map<From, String> _filterErrors = {};
  final Set<From> _loadingScenes = <From>{};
  final Set<From> _loadingFilters = <From>{};

  bool get _usesPluginScene => widget.scene != null;

  ComicListScene? _resolvedScene(From from) {
    return widget.scene ?? _defaultScenes[from];
  }

  ComicListRequestConfig? _sceneFilterRequest(From from) {
    return _resolvedScene(from)?.filter;
  }

  bool _requiresFilterBundle(From from) {
    return _sceneFilterRequest(from) != null;
  }

  @override
  Widget build(BuildContext context) {
    final globlalSettingCubit = context.read<GlobalSettingCubit>();
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final currentFrom = _usesPluginScene
        ? widget.scene!.from
        : (globalSettingState.comicChoice == 1 ? From.bika : From.jm);

    if (!_usesPluginScene) {
      _ensureSceneLoaded(currentFrom);
    }
    if (_requiresFilterBundle(currentFrom)) {
      _ensureFilterLoaded(currentFrom);
    }

    final scene = _resolvedScene(currentFrom);
    final title =
        widget.title ??
        (scene?.title ?? (currentFrom == From.bika ? '哔咔排行榜' : '禁漫排行榜'));

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
      floatingActionButton: (_usesPluginScene || globalSettingState.disableBika)
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
    final scene = _resolvedScene(currentFrom);
    if (scene == null) {
      if (_loadingScenes.contains(currentFrom)) {
        return const Center(child: CircularProgressIndicator());
      }

      final sceneError = _sceneErrors[currentFrom];
      if (sceneError != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(sceneError),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _reloadScene(currentFrom),
                child: const Text('重新加载'),
              ),
            ],
          ),
        );
      }
    }

    if (_requiresFilterBundle(currentFrom) &&
        _loadingFilters.contains(currentFrom) &&
        !_filterParams.containsKey(currentFrom)) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _requiresFilterBundle(currentFrom)
        ? _filterErrors[currentFrom]
        : null;
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

    if (scene != null) {
      return _buildSceneBody(currentFrom, scene);
    }
    return const SizedBox.shrink();
  }

  Widget _buildSceneBody(From currentFrom, ComicListScene scene) {
    final filterCore =
        _filterCoreParams[currentFrom] ?? const <String, dynamic>{};
    final filterExtern =
        _filterExternParams[currentFrom] ?? const <String, dynamic>{};
    final filterParams =
        _filterParams[currentFrom] ?? const <String, dynamic>{};
    final effectiveBodyType = switch (filterParams['bodyType']?.toString()) {
      'pluginPagedCreatorList' => ComicListBodyType.pluginPagedCreatorList,
      'pluginPagedComicList' => ComicListBodyType.pluginPagedComicList,
      _ => scene.body.type,
    };
    final request = scene.body.request;
    if (request == null) {
      return const Center(child: Text('缺少列表请求配置'));
    }

    switch (effectiveBodyType) {
      case ComicListBodyType.pluginPagedCreatorList:
        final listCore = <String, dynamic>{...request.core, ...filterCore};
        final listExtern = <String, dynamic>{
          ...request.extern,
          ...filterExtern,
        };
        return PluginPagedCreatorListView(
          key: ValueKey('${request.fnPath}_${listCore}_$listExtern'),
          from: currentFrom,
          fnPath: request.fnPath,
          coreBuilder: (page) => {'page': page, ...listCore},
          externBuilder: (_) => listExtern,
        );
      case ComicListBodyType.pluginPagedComicList:
        final listCore = <String, dynamic>{...request.core, ...filterCore};
        final listExtern = <String, dynamic>{
          ...request.extern,
          ...filterExtern,
        };
        return PluginPagedComicListView(
          key: ValueKey('${request.fnPath}_${listCore}_$listExtern'),
          from: currentFrom,
          fnPath: request.fnPath,
          coreBuilder: (page) => {'page': page, ...listCore},
          externBuilder: (_) => listExtern,
        );
    }
  }

  void _ensureSceneLoaded(From from) {
    if (widget.scene != null ||
        _defaultScenes.containsKey(from) ||
        _loadingScenes.contains(from)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadScene(from);
      }
    });
  }

  Future<void> _reloadScene(From from) async {
    _defaultScenes.remove(from);
    _sceneErrors.remove(from);
    _filterBundles.remove(from);
    _filterSelections.remove(from);
    _filterParams.remove(from);
    _filterCoreParams.remove(from);
    _filterExternParams.remove(from);
    await _loadScene(from);
  }

  Future<void> _loadScene(From from) async {
    if (_loadingScenes.contains(from)) {
      return;
    }

    setState(() {
      _loadingScenes.add(from);
      _sceneErrors.remove(from);
    });

    try {
      final response = await callUnifiedComicPlugin(
        from: from,
        fnPath: 'getComicListSceneBundle',
        core: const <String, dynamic>{},
        extern: const <String, dynamic>{'source': 'comicList'},
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      final sceneMap = asJsonMap(envelope.data['scene']);
      final scene = ComicListScene.fromMap(
        sceneMap.isNotEmpty ? sceneMap : envelope.data,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _defaultScenes[from] = scene;
        _loadingScenes.remove(from);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _sceneErrors[from] = e.toString();
        _loadingScenes.remove(from);
      });
    }
  }

  void _ensureFilterLoaded(From from) {
    final filterRequest = _sceneFilterRequest(from);
    if (filterRequest == null) {
      return;
    }
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
    _filterCoreParams.remove(from);
    _filterExternParams.remove(from);
    _filterErrors.remove(from);
    await _loadFilterBundle(from);
  }

  Future<void> _loadFilterBundle(From from) async {
    if (_loadingFilters.contains(from)) {
      return;
    }

    final filterRequest = _sceneFilterRequest(from);
    if (filterRequest == null) {
      return;
    }
    final fnPath = filterRequest.fnPath;
    final core = filterRequest.core;
    final extern = filterRequest.extern;

    setState(() {
      _loadingFilters.add(from);
      _filterErrors.remove(from);
    });

    try {
      final response = await callUnifiedComicPlugin(
        from: from,
        fnPath: fnPath,
        core: core,
        extern: extern,
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
        _filterCoreParams[from] = resolved.core;
        _filterExternParams[from] = resolved.extern;
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
      builder: (context) => PluginListFilterDialog(
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
      _filterCoreParams[from] = resolved.core;
      _filterExternParams[from] = resolved.extern;
    });
  }

  _ListFilterBundle _parseFilterBundle(UnifiedPluginEnvelope envelope) {
    final values = asMap(envelope.data['values']);
    final defaults = <String, String>{};
    values.forEach((key, value) {
      defaults[key] = value?.toString() ?? '';
    });

    return _ListFilterBundle(
      scheme: PluginListFilterSchema.fromMap(envelope.scheme),
      defaultSelections: defaults,
    );
  }

  PluginResolvedListFilter _resolveRankingFilter(
    _ListFilterBundle bundle,
    Map<String, String> requestedSelections,
  ) {
    return bundle.scheme.resolve(
      requestedSelections: requestedSelections,
      defaultSelections: bundle.defaultSelections,
    );
  }

  bool _showFilter(int comicChoice) {
    return _sceneFilterRequest(
          _usesPluginScene
              ? widget.scene!.from
              : (comicChoice == 1 ? From.bika : From.jm),
        ) !=
        null;
  }
}
