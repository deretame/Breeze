import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/comic_list/cubit/comic_list_cubit.dart';
import 'package:zephyr/page/comic_list/models/comic_list_scene.dart';
import 'package:zephyr/page/comic_list/scene_filter/plugin_list_filter_dialog.dart';
import 'package:zephyr/page/comic_list/view/plugin_paged_comic_list_view.dart';
import 'package:zephyr/page/discover/service/discover_router.dart';
import 'package:zephyr/page/discover/view/discover_scheme_renderer.dart';
import 'package:zephyr/page/plugin_home/plugin_home_bundle.dart';

/// tab 内容：scene 走 ComicList 现成渲染管线（无独立 Scaffold/AppBar），
/// page 走 DiscoverSchemeRenderer。
///
/// 同插件内切 tab 保活（`AutomaticKeepAliveClientMixin`）；
/// 切插件时外层 key 带 pluginId，整棵子树重建，保活状态一起扔掉。
class PluginHomeTabBody extends StatefulWidget {
  const PluginHomeTabBody({
    super.key,
    required this.pluginId,
    required this.tab,
    this.sceneCubit,
  });

  final String pluginId;
  final PluginHomeTab tab;
  final ComicListCubit? sceneCubit;

  @override
  State<PluginHomeTabBody> createState() => _PluginHomeTabBodyState();
}

class _PluginHomeTabBodyState extends State<PluginHomeTabBody>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scene = widget.tab.scene;
    final sceneCubit = widget.sceneCubit;
    if (scene != null && sceneCubit != null) {
      return _PluginHomeSceneBody(scene: scene, cubit: sceneCubit);
    }
    if (scene != null) {
      return const Center(child: CircularProgressIndicator());
    }
    return _PluginHomePageBody(pluginId: widget.pluginId, tab: widget.tab);
  }
}

class _PluginHomeSceneBody extends StatelessWidget {
  const _PluginHomeSceneBody({required this.scene, required this.cubit});

  final ComicListScene scene;
  final ComicListCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<ComicListCubit, ComicListState>(
        builder: (context, state) => _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ComicListState state) {
    final from = state.currentFrom;
    if (from.isEmpty) {
      return Center(child: Text(t.comicList.missingSource));
    }
    if (state.sceneLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.sceneError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.sceneError!),
            const SizedBox(height: 12),
            if (state.sceneLoginPluginId.isNotEmpty)
              Wrap(
                spacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      await context.pushRoute(
                        LoginRoute(from: state.sceneLoginPluginId),
                      );
                      cubit.reload();
                    },
                    icon: const Icon(Icons.login_outlined),
                    label: Text(t.login.loginButton),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => cubit.reload(),
                    icon: const Icon(Icons.refresh),
                    label: Text(t.comicList.reload),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: () => cubit.reload(),
                child: Text(t.comicList.reload),
              ),
          ],
        ),
      );
    }
    if (state.requiresFilter &&
        state.filterLoading &&
        !state.hasResolvedFilter) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.requiresFilter &&
        state.filterError != null &&
        !state.hasResolvedFilter) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.filterError!),
            const SizedBox(height: 12),
            if (state.filterLoginPluginId.isNotEmpty)
              Wrap(
                spacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      await context.pushRoute(
                        LoginRoute(from: state.filterLoginPluginId),
                      );
                      cubit.loadFilter();
                    },
                    icon: const Icon(Icons.login_outlined),
                    label: Text(t.login.loginButton),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => cubit.loadFilter(),
                    icon: const Icon(Icons.refresh),
                    label: Text(t.comicList.reload),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: () => cubit.loadFilter(),
                child: Text(t.comicList.reload),
              ),
          ],
        ),
      );
    }
    final loadedScene = state.scene;
    if (loadedScene == null) {
      return const SizedBox.shrink();
    }
    final request = loadedScene.body.request;
    if (request == null) {
      return Center(child: Text(t.comicList.missingSource));
    }
    final filterCore = state.resolvedFilterCore;
    final filterExtern = state.resolvedFilterExtern;
    final listCore = <String, dynamic>{...request.core, ...filterCore};
    final listExtern = <String, dynamic>{...request.extern, ...filterExtern};
    return PluginPagedComicListView(
      key: ValueKey('${request.fnPath}_${listCore}_$listExtern'),
      pluginId: from,
      fnPath: request.fnPath,
      coreBuilder: (page) => {'page': page, ...listCore},
      externBuilder: (_) => listExtern,
      suppressNeedLoginEvent: true,
      detailed: context
          .watch<GlobalSettingCubit>()
          .state
          .bookshelfSetting
          .detailLayout,
    );
  }
}

class _PluginHomePageBody extends StatelessWidget {
  const _PluginHomePageBody({required this.pluginId, required this.tab});

  final String pluginId;
  final PluginHomeTab tab;

  @override
  Widget build(BuildContext context) {
    const renderer = DiscoverSchemeRenderer();
    return renderer.buildPage(
      context,
      from: pluginId,
      scheme: tab.pageScheme,
      data: tab.pageData,
      onReachBottom: () async {},
      onAction: (action) => DiscoverRouter.route(
        context,
        action: DiscoverRouter.attachSource(action, pluginId),
        currentFrom: pluginId,
      ),
      isLoadingMore: false,
      showLoadMoreRetry: false,
      onRetryLoadMore: () {},
    );
  }
}

/// 打开 tab 对应 filter 对话框（每个 tab 独立 cubit，右上联动每个 tab 独立）。
Future<void> openPluginHomeFilterDialog(
  BuildContext context,
  ComicListCubit cubit,
) async {
  if (!cubit.state.hasResolvedFilter) {
    await cubit.loadFilter();
  }
  final bundle = cubit.state.filterBundle;
  if (!context.mounted || bundle == null) {
    return;
  }
  final result = await showDialog<Map<String, String>>(
    context: context,
    builder: (context) => PluginListFilterDialog(
      scheme: bundle.scheme,
      initialSelections: cubit.state.filterSelections.isNotEmpty
          ? cubit.state.filterSelections
          : bundle.defaultSelections,
    ),
  );
  if (result == null || !context.mounted) {
    return;
  }
  cubit.applyFilterSelections(result);
}
