import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/comic_list/models/comic_list_scene.dart';
import 'package:zephyr/page/comic_list/view/plugin_paged_comic_list_view.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/page/home/view/home_scheme_renderer.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_grid.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_mapper.dart';
import 'package:zephyr/widgets/toast.dart';

@RoutePage()
class OldHomePage extends StatefulWidget {
  const OldHomePage({super.key});

  @override
  State<OldHomePage> createState() => _OldHomePageState();
}

class _OldHomePageState extends State<OldHomePage> {
  static const String _pluginA = '0a0e5858-a467-4702-994a-79e608a4589d';
  static const String _pluginB = 'bf99008d-010b-4f17-ac7c-61a9b57dc3d9';

  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pluginStates = context.watch<PluginRegistryCubit>().state;
    final hasPluginA = pluginStates[_pluginA]?.isActive == true;
    final hasPluginB = pluginStates[_pluginB]?.isActive == true;

    final panels = <Widget>[
      if (hasPluginB) _OldHomePanelB(onAction: _handleAction),
      if (hasPluginA) _OldHomePanelA(onAction: _handleAction),
    ];
    final hasAnyPanel = panels.isNotEmpty;
    final effectiveIndex = panels.length <= 1
        ? 0
        : _tabIndex.clamp(0, panels.length - 1);

    return Scaffold(
      appBar: hasAnyPanel ? AppBar(title: const Text('首页')) : null,
      body: hasAnyPanel
          ? IndexedStack(index: effectiveIndex, children: panels)
          : const SizedBox.expand(),
      floatingActionButton: panels.length > 1
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _tabIndex = effectiveIndex == 0 ? 1 : 0;
                });
              },
              child: const Icon(Icons.swap_horiz),
            )
          : null,
    );
  }

  Future<void> _handleAction(Map<String, dynamic> action) async {
    final type = action['type']?.toString().trim() ?? '';
    final payload = asJsonMap(action['payload']);

    if (type.isEmpty || type == 'none') {
      return;
    }

    if (type == 'openSearch') {
      final source = _sourceFromString(payload['source']?.toString());
      if (source.isEmpty) {
        showErrorToast('缺少插件来源，无法搜索');
        return;
      }
      final keyword = payload['keyword']?.toString() ?? '';
      final extern = asJsonMap(payload['extern']);
      final searchStates = SearchStates.initial().copyWith(
        from: source,
        searchKeyword: keyword,
        pluginExtern: extern,
      );
      context.pushRoute(
        SearchResultRoute(
          searchEvent: SearchEvent().copyWith(searchStates: searchStates),
        ),
      );
      return;
    }

    if (type == 'openWeb') {
      final title = payload['title']?.toString() ?? '';
      final url = payload['url']?.toString() ?? '';
      if (url.isEmpty) {
        return;
      }

      context.pushRoute(WebViewRoute(info: [title, url]));

      return;
    }

    if (type == 'openPluginFunction') {
      final source = _sourceFromString(payload['source']?.toString());
      if (source.isEmpty) {
        showErrorToast('缺少插件来源，无法打开功能页');
        return;
      }
      await _openPluginFunction(source, payload);
      return;
    }

    if (type == 'openCloudFavorite') {
      final source = _sourceFromString(payload['source']?.toString());
      if (source.isEmpty) {
        showErrorToast('缺少插件来源，无法打开云端收藏');
        return;
      }
      final title = payload['title']?.toString();
      context.pushRoute(
        ComicListRoute(
          title: title ?? '云端收藏',
          sceneSource: source,
          sceneBundleFnPath: 'getCloudFavoriteSceneBundle',
          sceneBundleFnPathFallback: 'get_cloud_favorite_scene_bundle',
        ),
      );
      return;
    }

    if (type == 'openComicList') {
      final scene = asJsonMap(payload['scene']);
      final title = scene['title']?.toString().trim() ?? '列表';
      if (scene.isEmpty) {
        showErrorToast('缺少场景信息，无法打开列表');
        return;
      }
      context.pushRoute(
        ComicListRoute(title: title, scene: ComicListScene.fromMap(scene)),
      );
      return;
    }
  }

  String _sourceFromString(String? source) {
    return (source ?? '').trim();
  }

  Future<void> _openPluginFunction(
    String from,
    Map<String, dynamic> payload,
  ) async {
    final functionId = payload['id']?.toString().trim() ?? '';
    if (functionId.isEmpty) {
      return;
    }
    final title = payload['title']?.toString().trim() ?? '功能';
    final presentation = payload['presentation']?.toString().trim() ?? 'page';

    if (presentation != 'dialog') {
      await context.pushRoute(
        PluginFunctionRoute(
          from: from,
          functionId: functionId,
          title: title,
          onAction: _handleAction,
        ),
      );
      return;
    }

    final mediaSize = MediaQuery.sizeOf(context);
    final dialogWidth = (mediaSize.width * 0.9).clamp(280.0, 560.0).toDouble();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        contentPadding: const EdgeInsets.only(top: 8),
        content: SizedBox(
          width: dialogWidth,
          height: 320,
          child: _PluginFunctionDialogContent(
            from: from,
            functionId: functionId,
            onAction: _handleAction,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _OldHomePanelA extends StatefulWidget {
  const _OldHomePanelA({required this.onAction});

  final Future<void> Function(Map<String, dynamic> action) onAction;

  @override
  State<_OldHomePanelA> createState() => _OldHomePanelAState();
}

class _OldHomePanelAState extends State<_OldHomePanelA>
    with AutomaticKeepAliveClientMixin {
  static const String _pluginA = '0a0e5858-a467-4702-994a-79e608a4589d';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _FunctionSection(
            pluginId: _pluginA,
            functionId: 'hotSearch',
            title: '热搜',
            onAction: widget.onAction,
          ),
          const Divider(height: 1),
          _FunctionSection(
            pluginId: _pluginA,
            functionId: 'navigation',
            title: '导航',
            onAction: widget.onAction,
          ),
        ],
      ),
    );
  }
}

class _OldHomePanelB extends StatefulWidget {
  const _OldHomePanelB({required this.onAction});

  final Future<void> Function(Map<String, dynamic> action) onAction;

  @override
  State<_OldHomePanelB> createState() => _OldHomePanelBState();
}

class _OldHomePanelBState extends State<_OldHomePanelB>
    with AutomaticKeepAliveClientMixin {
  static const String _pluginB = 'bf99008d-010b-4f17-ac7c-61a9b57dc3d9';
  static const double _autoLoadExtentAfterThreshold = 280;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<_InlineLatestListState> _latestListKey =
      GlobalKey<_InlineLatestListState>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    _tryAutoLoadByMetrics(_scrollController.position);
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    _tryAutoLoadByMetrics(notification.metrics);
    return false;
  }

  void _tryAutoLoadByMetrics(ScrollMetrics metrics) {
    if (metrics.maxScrollExtent <= 0) {
      return;
    }
    if (metrics.extentAfter <= _autoLoadExtentAfterThreshold) {
      _latestListKey.currentState?.requestLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FunctionSection(
              pluginId: _pluginB,
              functionId: 'recommend',
              title: '推荐',
              onAction: widget.onAction,
            ),
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text('最新'),
            ),
            _InlineLatestList(key: _latestListKey, pluginId: _pluginB),
          ],
        ),
      ),
    );
  }
}

class _InlineLatestList extends StatefulWidget {
  const _InlineLatestList({super.key, required this.pluginId});

  final String pluginId;

  @override
  State<_InlineLatestList> createState() => _InlineLatestListState();
}

class _InlineLatestListState extends State<_InlineLatestList>
    with AutomaticKeepAliveClientMixin {
  late final PluginPagedComicListCubit _cubit;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = PluginPagedComicListCubit(
      pluginId: widget.pluginId,
      fnPath: 'getLatestData',
      coreBuilder: (page) => {'page': page},
      externBuilder: (_) => const {'source': 'latest'},
    )..loadInitial();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void requestLoadMore() {
    _cubit.loadMore();
  }

  void _ensureFillViewportAfterFrame(PluginPagedComicListState state) {
    if (state.hasReachedMax ||
        state.status == PluginPagedComicListStatus.loadingMore ||
        state.status == PluginPagedComicListStatus.loadingMoreFailure) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scrollable = Scrollable.maybeOf(context);
      final position = scrollable?.position;
      if (position == null) {
        return;
      }
      if (position.maxScrollExtent <= 0) {
        _cubit.loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<PluginPagedComicListCubit, PluginPagedComicListState>(
      bloc: _cubit,
      builder: (context, state) {
        switch (state.status) {
          case PluginPagedComicListStatus.initial:
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          case PluginPagedComicListStatus.failure:
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${state.result}\n加载失败，请重试。',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _cubit.loadInitial(),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            );
          case PluginPagedComicListStatus.loadingMore:
          case PluginPagedComicListStatus.loadingMoreFailure:
          case PluginPagedComicListStatus.success:
            _ensureFillViewportAfterFrame(state);
            return _buildContent(state);
        }
      },
    );
  }

  Widget _buildContent(PluginPagedComicListState state) {
    if (state.list.isEmpty &&
        state.status == PluginPagedComicListStatus.success) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('暂无内容')),
      );
    }

    final entries = mapToUnifiedComicSimplifyEntryInfoList(state.list);
    return Column(
      children: [
        ComicSimplifyEntryGridView(
          entries: entries,
          type: ComicEntryType.normal,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(10),
        ),
        if (state.status == PluginPagedComicListStatus.loadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: CircularProgressIndicator(),
          ),
        if (state.status == PluginPagedComicListStatus.loadingMoreFailure)
          Padding(
            padding: const EdgeInsets.only(bottom: 14, top: 6),
            child: TextButton(
              onPressed: () => _cubit.retryLoadMore(),
              child: const Text('加载更多失败，点击重试'),
            ),
          ),
        if (!state.hasReachedMax &&
            state.status != PluginPagedComicListStatus.loadingMore &&
            state.status != PluginPagedComicListStatus.loadingMoreFailure)
          Padding(
            padding: const EdgeInsets.only(bottom: 14, top: 6),
            child: TextButton.icon(
              onPressed: () => _cubit.loadMore(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              label: const Text('点击加载更多'),
            ),
          ),
        if (state.hasReachedMax)
          const Padding(padding: EdgeInsets.all(14), child: Text('没有更多了')),
      ],
    );
  }
}

class _FunctionSection extends StatefulWidget {
  const _FunctionSection({
    required this.pluginId,
    required this.functionId,
    required this.title,
    required this.onAction,
  });

  final String pluginId;
  final String functionId;
  final String title;
  final Future<void> Function(Map<String, dynamic> action) onAction;

  @override
  State<_FunctionSection> createState() => _FunctionSectionState();
}

class _FunctionSectionState extends State<_FunctionSection>
    with AutomaticKeepAliveClientMixin {
  static final Map<String, Future<UnifiedPluginEnvelope>> _futureCache = {};
  final HomeSchemeRenderer _renderer = const HomeSchemeRenderer();

  late Future<UnifiedPluginEnvelope> _future;

  String get _cacheKey => '${widget.pluginId}:${widget.functionId}';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _futureCache.putIfAbsent(_cacheKey, _loadEnvelope);
  }

  Future<UnifiedPluginEnvelope> _loadEnvelope() async {
    Map<String, dynamic> response;
    try {
      response = await callUnifiedComicPlugin(
        pluginId: widget.pluginId,
        fnPath: 'getFunctionPage',
        core: {'id': widget.functionId},
        extern: const <String, dynamic>{},
      );
    } catch (_) {
      response = await callUnifiedComicPlugin(
        pluginId: widget.pluginId,
        fnPath: 'get_function_page',
        core: {'id': widget.functionId},
        extern: const <String, dynamic>{},
      );
    }
    return UnifiedPluginEnvelope.fromMap(response);
  }

  void _retry() {
    _futureCache.remove(_cacheKey);
    setState(() {
      _future = _futureCache.putIfAbsent(_cacheKey, _loadEnvelope);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<UnifiedPluginEnvelope>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '加载 ${widget.title} 失败\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: _retry, child: const Text('重试')),
              ],
            ),
          );
        }

        final envelope = snapshot.data!;
        return RepaintBoundary(
          child: _renderer.buildPage(
            context,
            from: widget.pluginId,
            scheme: envelope.scheme,
            data: envelope.data,
            onReachBottom: () async {},
            onAction: (action) async {
              final next = _attachActionSource(action, widget.pluginId);
              await widget.onAction(next);
            },
            isLoadingMore: false,
            showLoadMoreRetry: false,
            onRetryLoadMore: () {},
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _attachActionSource(
    Map<String, dynamic> action,
    String from,
  ) {
    final type = action['type']?.toString().trim() ?? '';
    if (type != 'openPluginFunction' &&
        type != 'openCloudFavorite' &&
        type != 'openSearch' &&
        type != 'openComicList') {
      return action;
    }

    final payload = Map<String, dynamic>.from(asJsonMap(action['payload']));
    payload['source'] = from;
    if (type == 'openComicList') {
      final scene = Map<String, dynamic>.from(asJsonMap(payload['scene']));
      scene['source'] = from;
      payload['scene'] = scene;
    }
    return Map<String, dynamic>.from(action)..['payload'] = payload;
  }
}

class _PluginFunctionDialogContent extends StatefulWidget {
  const _PluginFunctionDialogContent({
    required this.from,
    required this.functionId,
    required this.onAction,
  });

  final String from;
  final String functionId;
  final Future<void> Function(Map<String, dynamic> action) onAction;

  @override
  State<_PluginFunctionDialogContent> createState() =>
      _PluginFunctionDialogContentState();
}

class _PluginFunctionDialogContentState
    extends State<_PluginFunctionDialogContent> {
  final HomeSchemeRenderer _renderer = const HomeSchemeRenderer();
  bool _loading = true;
  String _error = '';
  Map<String, dynamic> _scheme = const <String, dynamic>{};
  Map<String, dynamic> _data = const <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      Map<String, dynamic> response;
      try {
        response = await callUnifiedComicPlugin(
          from: widget.from,
          fnPath: 'getFunctionPage',
          core: {'id': widget.functionId},
          extern: const <String, dynamic>{},
        );
      } catch (_) {
        response = await callUnifiedComicPlugin(
          from: widget.from,
          fnPath: 'get_function_page',
          core: {'id': widget.functionId},
          extern: const <String, dynamic>{},
        );
      }

      if (!mounted) return;
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      setState(() {
        _scheme = envelope.scheme;
        _data = asMap(envelope.data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              TextButton(onPressed: _load, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    return _renderer.buildPage(
      context,
      from: widget.from,
      scheme: _scheme,
      data: _data,
      onReachBottom: () async {},
      onAction: widget.onAction,
      isLoadingMore: false,
      showLoadMoreRetry: false,
      onRetryLoadMore: () {},
    );
  }
}
