import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/comic_list/cubit/comic_list_cubit.dart';
import 'package:zephyr/page/comic_list/models/comic_list_scene.dart';
import 'package:zephyr/page/comic_list/scene_filter/plugin_list_filter_dialog.dart';
import 'package:zephyr/page/comic_list/view/plugin_paged_comic_list_view.dart';

@RoutePage()
class ComicListPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ComicListCubit(
        initialScene: scene,
        sceneSource: sceneSource,
        sceneBundleFnPath: sceneBundleFnPath,
        sceneBundleFnPathFallback: sceneBundleFnPathFallback,
      ),
      child: _ComicListView(title: title),
    );
  }
}

class _ComicListView extends StatefulWidget {
  const _ComicListView({this.title});

  final String? title;

  @override
  State<_ComicListView> createState() => _ComicListViewState();
}

class _ComicListViewState extends State<_ComicListView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<ComicListCubit, ComicListState>(
      builder: (context, state) {
        final title = widget.title ?? (state.scene?.title ?? '漫画列表');

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              if (state.requiresFilter)
                IconButton(
                  icon: const Icon(Icons.filter_alt),
                  onPressed: () => _openFilterDialog(context),
                ),
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ComicListState state) {
    final currentFrom = state.currentFrom;

    if (currentFrom.isEmpty) {
      return const Center(child: Text('缺少插件来源，无法加载列表'));
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
            ElevatedButton(
              onPressed: () => context.read<ComicListCubit>().reload(),
              child: const Text('重新加载'),
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
            ElevatedButton(
              onPressed: () => context.read<ComicListCubit>().loadFilter(),
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    final scene = state.scene;
    if (scene != null) {
      return _buildSceneBody(state, scene);
    }

    return const SizedBox.shrink();
  }

  Widget _buildSceneBody(ComicListState state, ComicListScene scene) {
    final request = scene.body.request!;
    final filterCore = state.resolvedFilterCore;
    final filterExtern = state.resolvedFilterExtern;
    final listCore = <String, dynamic>{...request.core, ...filterCore};
    final listExtern = <String, dynamic>{...request.extern, ...filterExtern};

    return PluginPagedComicListView(
      key: ValueKey('${request.fnPath}_${listCore}_$listExtern'),
      pluginId: state.currentFrom,
      fnPath: request.fnPath,
      coreBuilder: (page) => {'page': page, ...listCore},
      externBuilder: (_) => listExtern,
    );
  }

  Future<void> _openFilterDialog(BuildContext context) async {
    final cubit = context.read<ComicListCubit>();

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
}
