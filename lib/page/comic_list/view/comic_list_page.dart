import 'package:auto_route/annotations.dart';
import 'package:zephyr/plugin/plugin_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/comic_list/models/comic_list_scene.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/comic_list/scene_filter/plugin_list_filter_dialog.dart';
import 'package:zephyr/page/comic_list/scene_filter/plugin_list_filter_schema.dart';
import 'package:zephyr/page/comic_list/view/plugin_paged_comic_list_view.dart';
import 'package:zephyr/page/comic_list/view/plugin_paged_creator_list_view.dart';
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
  const ComicListPage({
    super.key,
    this.title,
    this.scene,
    this.sceneSource,
    this.sceneBundleFnPath,
    this.sceneBundleFnPathFallback,
  });

  final String? title;
  final ComicListScene? scene;
  final String? sceneSource;
  final String? sceneBundleFnPath;
  final String? sceneBundleFnPathFallback;

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
    return ComicListScaffold(
      title: widget.title,
      scene: widget.scene,
      sceneSource: widget.sceneSource,
      sceneBundleFnPath: widget.sceneBundleFnPath,
      sceneBundleFnPathFallback: widget.sceneBundleFnPathFallback,
    );
  }
}

class ComicListScaffold extends StatefulWidget {
  const ComicListScaffold({
    super.key,
    this.title,
    this.scene,
    this.sceneSource,
    this.sceneBundleFnPath,
    this.sceneBundleFnPathFallback,
  });

  final String? title;
  final ComicListScene? scene;
  final String? sceneSource;
  final String? sceneBundleFnPath;
  final String? sceneBundleFnPathFallback;

  @override
  State<ComicListScaffold> createState() => _ComicListScaffoldState();
}

class _ComicListScaffoldState extends State<ComicListScaffold> {
  final Map<String, ComicListScene> _defaultScenes = {};
  final Map<String, _ListFilterBundle> _filterBundles = {};
  final Map<String, Map<String, String>> _filterSelections = {};
  final Map<String, Map<String, dynamic>> _resolvedUiParams = {};
  final Map<String, Map<String, dynamic>> _resolvedFilterCore = {};
  final Map<String, Map<String, dynamic>> _resolvedFilterExtern = {};
  final Map<String, String> _sceneErrors = {};
  final Map<String, String> _filterErrors = {};
  final Set<String> _loadingScenes = <String>{};
  final Set<String> _loadingFilters = <String>{};

  bool get _usesPluginScene => widget.scene != null;

  ComicListScene? _resolvedScene(String from) {
    return widget.scene ?? _defaultScenes[from];
  }

  ComicListRequestConfig? _sceneFilterRequest(String from) {
    return _resolvedScene(from)?.filter;
  }

  bool _requiresFilterBundle(String from) {
    return _sceneFilterRequest(from) != null;
  }

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final currentFrom = _usesPluginScene
        ? widget.scene!.from
        : (widget.sceneSource ??
              (globalSettingState.comicChoice == 1
                  ? kBikaPluginUuid
                  : kJmPluginUuid));

    if (!_usesPluginScene) {
      _ensureSceneLoaded(currentFrom);
    }
    if (_requiresFilterBundle(currentFrom)) {
      _ensureFilterLoaded(currentFrom);
    }

    final scene = _resolvedScene(currentFrom);
    final title =
        widget.title ??
        (scene?.title ?? (currentFrom == kBikaPluginUuid ? '哔咔排行榜' : '禁漫排行榜'));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_showFilter(currentFrom))
            IconButton(
              icon: const Icon(Icons.filter_alt),
              onPressed: () => _openFilterDialog(currentFrom),
            ),
        ],
      ),
      body: _buildBody(globalSettingState.comicChoice, currentFrom),
      floatingActionButton: null,
    );
  }

  Widget _buildBody(int comicChoice, String currentFrom) {
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
        !_resolvedUiParams.containsKey(currentFrom)) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _requiresFilterBundle(currentFrom)
        ? _filterErrors[currentFrom]
        : null;
    if (error != null && !_resolvedUiParams.containsKey(currentFrom)) {
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

  Widget _buildSceneBody(String currentFrom, ComicListScene scene) {
    final filterCore =
        _resolvedFilterCore[currentFrom] ?? const <String, dynamic>{};
    final filterExtern =
        _resolvedFilterExtern[currentFrom] ?? const <String, dynamic>{};
    final uiParams =
        _resolvedUiParams[currentFrom] ?? const <String, dynamic>{};
    final effectiveBodyType = switch (uiParams['bodyType']?.toString()) {
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
        final listExtern = _buildListExtern(request.extern, filterExtern);
        return PluginPagedCreatorListView(
          key: ValueKey('${request.fnPath}_${listCore}_$listExtern'),
          pluginId: currentFrom,
          fnPath: request.fnPath,
          coreBuilder: (page) => {'page': page, ...listCore},
          externBuilder: (_) => listExtern,
        );
      case ComicListBodyType.pluginPagedComicList:
        final listCore = <String, dynamic>{...request.core, ...filterCore};
        final listExtern = _buildListExtern(request.extern, filterExtern);
        return PluginPagedComicListView(
          key: ValueKey('${request.fnPath}_${listCore}_$listExtern'),
          pluginId: currentFrom,
          fnPath: request.fnPath,
          coreBuilder: (page) => {'page': page, ...listCore},
          externBuilder: (_) => listExtern,
        );
    }
  }

  void _ensureSceneLoaded(String from) {
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

  Future<void> _reloadScene(String from) async {
    _defaultScenes.remove(from);
    _sceneErrors.remove(from);
    _filterBundles.remove(from);
    _filterSelections.remove(from);
    _resolvedUiParams.remove(from);
    _resolvedFilterCore.remove(from);
    _resolvedFilterExtern.remove(from);
    await _loadScene(from);
  }

  Future<void> _loadScene(String from) async {
    if (_loadingScenes.contains(from)) {
      return;
    }

    setState(() {
      _loadingScenes.add(from);
      _sceneErrors.remove(from);
    });

    try {
      final sceneFnPath = widget.sceneBundleFnPath?.trim().isNotEmpty == true
          ? widget.sceneBundleFnPath!.trim()
          : 'getComicListSceneBundle';
      Map<String, dynamic> response;
      try {
        response = await callUnifiedComicPlugin(
          from: from,
          fnPath: sceneFnPath,
          core: const <String, dynamic>{},
          extern: const <String, dynamic>{},
        );
      } catch (_) {
        final fallback = widget.sceneBundleFnPathFallback?.trim() ?? '';
        if (fallback.isEmpty || fallback == sceneFnPath) {
          rethrow;
        }
        response = await callUnifiedComicPlugin(
          from: from,
          fnPath: fallback,
          core: const <String, dynamic>{},
          extern: const <String, dynamic>{},
        );
      }
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

  void _ensureFilterLoaded(String from) {
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

  Future<void> _reloadFilter(String from) async {
    _filterBundles.remove(from);
    _filterSelections.remove(from);
    _resolvedUiParams.remove(from);
    _resolvedFilterCore.remove(from);
    _resolvedFilterExtern.remove(from);
    _filterErrors.remove(from);
    await _loadFilterBundle(from);
  }

  Future<void> _loadFilterBundle(String from) async {
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
        _resolvedUiParams[from] = resolved.params;
        _resolvedFilterCore[from] = resolved.core;
        _resolvedFilterExtern[from] = resolved.extern;
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

  Future<void> _openFilterDialog(String from) async {
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
      _resolvedUiParams[from] = resolved.params;
      _resolvedFilterCore[from] = resolved.core;
      _resolvedFilterExtern[from] = resolved.extern;
    });
  }

  Map<String, dynamic> _buildListExtern(
    Map<String, dynamic> requestExtern,
    Map<String, dynamic> resolvedFilterExtern,
  ) {
    return <String, dynamic>{...requestExtern, ...resolvedFilterExtern};
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

  bool _showFilter(String from) {
    return _sceneFilterRequest(from) != null;
  }
}
