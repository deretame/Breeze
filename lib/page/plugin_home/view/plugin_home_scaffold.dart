import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/comic_list/cubit/comic_list_cubit.dart';
import 'package:zephyr/page/discover/service/discover_router.dart';
import 'package:zephyr/page/plugin_home/cubit/plugin_home_cubit.dart';
import 'package:zephyr/page/plugin_home/plugin_home_bundle.dart';
import 'package:zephyr/page/plugin_home/view/plugin_home_tab_body.dart';
import 'package:zephyr/page/plugin_home/view/plugin_selector_dialog.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/widgets/toast.dart';

/// 插件通用 TabView 骨架：标题位即 TabBar（可横滑）+ 右上随 tab 切换 + 左侧图标切插件。
///
/// [pageTitle] 为无 tab 时的标题；左侧图标为切换入口 + 当前插件定位。
/// 内容每次重进重载，不保活。
class PluginHomeScaffold extends StatefulWidget {
  const PluginHomeScaffold({
    super.key,
    required this.pageTitle,
    required this.selectorTitle,
    required this.createCubit,
  });

  final String pageTitle;
  final String selectorTitle;
  final PluginHomeCubit Function() createCubit;

  @override
  State<PluginHomeScaffold> createState() => _PluginHomeScaffoldState();
}

class _PluginHomeScaffoldState extends State<PluginHomeScaffold>
    with TickerProviderStateMixin {
  late final PluginHomeCubit _cubit;
  final Map<String, ComicListCubit> _sceneCubits = {};
  TabController? _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _cubit = widget.createCubit();
    // init 结束后直接加载，无延迟 hack。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _cubit.load();
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    for (final cubit in _sceneCubits.values) {
      cubit.close();
    }
    _cubit.close();
    super.dispose();
  }

  void _syncSceneCubits(PluginHomeState state) {
    final bundle = state.bundle;
    if (bundle == null) {
      _disposeSceneCubits();
      return;
    }
    final wanted = <String>{};
    for (var i = 0; i < bundle.tabs.length; i++) {
      final tab = bundle.tabs[i];
      if (tab.scene == null) {
        continue;
      }
      final key = '${tab.id}#$i';
      wanted.add(key);
      _sceneCubits.putIfAbsent(
        key,
        // 新两页内的 scene：登录错误不出全局弹窗，由 tab 错误体出登录/刷新。
        () => ComicListCubit(
          initialScene: tab.scene,
          suppressNeedLoginEvent: true,
        ),
      );
    }
    final stale = _sceneCubits.keys
        .where((key) => !wanted.contains(key))
        .toList();
    for (final key in stale) {
      _sceneCubits.remove(key)?.close();
    }
    _syncTabController(bundle.tabs.length);
  }

  void _disposeSceneCubits() {
    _tabController?.dispose();
    _tabController = null;
    _tabIndex = 0;
    for (final cubit in _sceneCubits.values) {
      cubit.close();
    }
    _sceneCubits.clear();
  }

  void _syncTabController(int tabCount) {
    if (tabCount <= 1) {
      _tabController?.dispose();
      _tabController = null;
      _tabIndex = 0;
      return;
    }
    if (_tabController == null || _tabController!.length != tabCount) {
      final previousIndex = _tabIndex.clamp(0, tabCount - 1);
      _tabController?.dispose();
      _tabController = TabController(
        length: tabCount,
        vsync: this,
        initialIndex: previousIndex,
      );
      _tabController!.addListener(_onTabChanged);
      _tabIndex = previousIndex;
    }
  }

  void _onTabChanged() {
    final controller = _tabController;
    if (controller == null || controller.indexIsChanging) {
      return;
    }
    if (_tabIndex != controller.index) {
      setState(() => _tabIndex = controller.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<PluginHomeCubit, PluginHomeState>(
        listenWhen: (previous, current) =>
            previous.pluginId != current.pluginId ||
            previous.bundle != current.bundle ||
            previous.reloadSignal != current.reloadSignal,
        listener: (context, state) => _syncSceneCubits(state),
        builder: (context, state) {
          final bundle = state.bundle;
          final tabs = bundle?.tabs ?? const <PluginHomeTab>[];
          final activeIndex = tabs.isEmpty
              ? 0
              : _tabIndex.clamp(0, tabs.length - 1);
          final activeTab = tabs.isEmpty ? null : tabs[activeIndex];
          // 多 tab：标题位直接放 TabBar（isScrollable 横向可滚），右上 actions 常驻。
          // 单 tab / 无 tab：显示插件名（可点切换），没插件显示页标题。
          final hasTabBar = tabs.length > 1 && _tabController != null;
          final pluginName = state.pluginId.isEmpty
              ? ''
              : context.select<PluginRegistryCubit, String>(
                  (cubit) => cubit.state.pluginName(state.pluginId),
                );
          return Scaffold(
            appBar: AppBar(
              titleSpacing: hasTabBar ? 0 : null,
              title: hasTabBar
                  ? TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [for (final tab in tabs) Tab(text: tab.title)],
                    )
                  : InkWell(
                      onTap: () => _openSelector(context, state),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              pluginName.isNotEmpty
                                  ? pluginName
                                  : widget.pageTitle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
              actions: [
                if (activeTab != null)
                  ..._buildActions(context, state, activeTab, activeIndex),
                IconButton(
                  tooltip: t.discover.search,
                  icon: const Icon(Icons.search),
                  onPressed: () => _search(context, state),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: _buildBody(context, state),
            floatingActionButton: FloatingActionButton(
              heroTag: null,
              tooltip: widget.selectorTitle,
              onPressed: () => _openSelector(context, state),
              child: const Icon(Icons.extension_outlined),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    PluginHomeState state,
    PluginHomeTab activeTab,
    int activeIndex,
  ) {
    if (activeTab.scene != null) {
      final sceneCubit = _sceneCubits['${activeTab.id}#$activeIndex'];
      if (sceneCubit == null) {
        return const [];
      }
      return [
        BlocProvider.value(
          value: sceneCubit,
          child: BlocBuilder<ComicListCubit, ComicListState>(
            builder: (context, sceneState) {
              if (sceneState.scene?.filter == null) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: t.comicList.filter,
                icon: const Icon(Icons.filter_alt),
                onPressed: () =>
                    openPluginHomeFilterDialog(context, sceneCubit),
              );
            },
          ),
        ),
      ];
    }
    if (activeTab.headerActions.isEmpty) {
      return const [];
    }
    return [
      for (final action in activeTab.headerActions)
        IconButton(
          tooltip: action['title']?.toString() ?? t.oldHome.function,
          icon: Icon(_iconForAction(action)),
          onPressed: () => DiscoverRouter.route(
            context,
            action: DiscoverRouter.attachSource(action, state.pluginId),
            currentFrom: state.pluginId,
          ),
        ),
    ];
  }

  void _search(BuildContext context, PluginHomeState state) {
    final source = state.pluginId;
    if (source.isEmpty) {
      showErrorToast(t.discover.noPluginForSearch);
      return;
    }
    context.pushRoute(
      SearchRoute(
        searchState: SearchStates.initial().copyWith(from: source),
        aggregateMode: true,
      ),
    );
  }

  IconData _iconForAction(Map<String, dynamic> action) {
    final icon = action['icon']?.toString().trim() ?? '';
    if (icon.isNotEmpty) {
      return switch (icon) {
        'search' => Icons.search,
        'filter' => Icons.filter_alt,
        'settings' => Icons.settings_outlined,
        'refresh' => Icons.refresh,
        _ => Icons.play_arrow_outlined,
      };
    }
    return switch (action['type']?.toString().trim() ?? '') {
      'openSearch' => Icons.search,
      'openComicList' => Icons.view_list_outlined,
      'openPluginFunction' => Icons.extension_outlined,
      'openCloudFavorite' => Icons.cloud_outlined,
      'openWeb' => Icons.open_in_browser_outlined,
      'openComicInfo' => Icons.menu_book_outlined,
      _ => Icons.play_arrow_outlined,
    };
  }

  Widget _buildBody(BuildContext context, PluginHomeState state) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error.isNotEmpty) {
      final loginPluginId = state.loginPluginId;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(state.error, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            if (loginPluginId.isNotEmpty)
              Wrap(
                spacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => _openLogin(context, loginPluginId),
                    icon: const Icon(Icons.login_outlined),
                    label: Text(t.login.loginButton),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _cubit.retry(),
                    icon: const Icon(Icons.refresh),
                    label: Text(t.common.retry),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: () => _cubit.retry(),
                child: Text(t.common.retry),
              ),
          ],
        ),
      );
    }
    final bundle = state.bundle;
    if (bundle == null || bundle.tabs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.common.empty),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _openSelector(context, state),
              child: Text(widget.selectorTitle),
            ),
          ],
        ),
      );
    }
    final tabs = bundle.tabs;
    if (tabs.length <= 1 || _tabController == null) {
      final index = _tabIndex.clamp(0, tabs.length - 1);
      final tab = tabs[index];
      return PluginHomeTabBody(
        key: ValueKey('${state.pluginId}_${tab.id}_$index'),
        pluginId: state.pluginId,
        tab: tab,
        sceneCubit: tab.scene == null ? null : _sceneCubits['${tab.id}#$index'],
      );
    }
    // 多 tab：TabBarView 支持左右滑动切换，controller 与 TabBar 共用。
    // page tab（scheme 渲染）是 ListView，scene tab 是分页列表，
    // TabBarView 的横向手势与纵向滚动不冲突。
    return TabBarView(
      controller: _tabController,
      children: [
        for (var i = 0; i < tabs.length; i++)
          PluginHomeTabBody(
            key: ValueKey('${state.pluginId}_${tabs[i].id}_$i'),
            pluginId: state.pluginId,
            tab: tabs[i],
            sceneCubit: tabs[i].scene == null
                ? null
                : _sceneCubits['${tabs[i].id}#$i'],
          ),
      ],
    );
  }

  Future<void> _openSelector(
    BuildContext context,
    PluginHomeState state,
  ) async {
    final picked = await showPluginHomeSelector(
      context,
      candidates: state.candidates,
      selectedId: state.pluginId,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _tabIndex = 0);
    await _cubit.switchPlugin(picked);
    if (!mounted) {
      return;
    }
    if (_cubit.state.error.isNotEmpty) {
      showErrorToast(_cubit.state.error);
    }
  }

  /// 登录错误页的登录按钮：进登录页，回来后重试拉 bundle。
  /// 登录成功会触发全局 initOk/插件状态变化，retry 即能拿到数据。
  Future<void> _openLogin(BuildContext context, String pluginId) async {
    await context.pushRoute(LoginRoute(from: pluginId));
    if (!mounted) {
      return;
    }
    await _cubit.retry();
  }
}
