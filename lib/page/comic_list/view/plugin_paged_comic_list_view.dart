import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/comic_list/cubit/plugin_paged_comic_list_cubit.dart';
import 'package:zephyr/page/comic_list/cubit/plugin_paged_comic_list_state.dart';
import 'package:zephyr/page/comic_list/view/plugin_comic_grid_sliver.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_mapper.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/widgets/error_view.dart';

export 'package:zephyr/page/comic_list/cubit/plugin_paged_comic_list_cubit.dart';
export 'package:zephyr/page/comic_list/cubit/plugin_paged_comic_list_state.dart';

class PluginPagedComicListView extends StatelessWidget {
  const PluginPagedComicListView({
    super.key,
    required this.pluginId,
    required this.fnPath,
    required this.coreBuilder,
    required this.externBuilder,
    this.shrinkWrap = false,
    this.physics,
    this.collectionTargetId,
    this.collectionTargetName,
    this.suppressNeedLoginEvent = false,
    this.detailed = false,
  });

  final String pluginId;
  final String fnPath;
  final PluginPageCoreBuilder coreBuilder;
  final PluginPageExternBuilder externBuilder;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final String? collectionTargetId;
  final String? collectionTargetName;
  final bool suppressNeedLoginEvent;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PluginPagedComicListCubit(
        pluginId: pluginId,
        fnPath: fnPath,
        coreBuilder: coreBuilder,
        externBuilder: externBuilder,
        suppressNeedLoginEvent: suppressNeedLoginEvent,
      )..loadInitial(),
      child: _PluginPagedComicListBody(
        shrinkWrap: shrinkWrap,
        physics: physics,
        collectionTargetId: collectionTargetId,
        collectionTargetName: collectionTargetName,
        detailed: detailed,
      ),
    );
  }
}

class _PluginPagedComicListBody extends StatefulWidget {
  const _PluginPagedComicListBody({
    required this.shrinkWrap,
    required this.physics,
    this.collectionTargetId,
    this.collectionTargetName,
    this.detailed = false,
  });

  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final String? collectionTargetId;
  final String? collectionTargetName;
  final bool detailed;

  @override
  State<_PluginPagedComicListBody> createState() =>
      _PluginPagedComicListBodyState();
}

class _PluginPagedComicListBodyState extends State<_PluginPagedComicListBody>
    with AutomaticKeepAliveClientMixin {
  final ScrollController scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () => context.read<PluginPagedComicListCubit>().loadInitial(),
      child: BlocBuilder<PluginPagedComicListCubit, PluginPagedComicListState>(
        builder: (context, state) {
          switch (state.status) {
            case PluginPagedComicListStatus.initial:
              return const CustomScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            case PluginPagedComicListStatus.failure:
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorView(
                      errorMessage:
                          '${state.result}\n${t.comicList.loadFailedRetry}',
                      loginPluginId: state.loginPluginId,
                      onRetry: () => context
                          .read<PluginPagedComicListCubit>()
                          .loadInitial(),
                    ),
                  ),
                ],
              );
            case PluginPagedComicListStatus.loadingMore:
            case PluginPagedComicListStatus.loadingMoreFailure:
            case PluginPagedComicListStatus.success:
              return _buildContent(context, state);
          }
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PluginPagedComicListState state) {
    if (state.list.isEmpty &&
        state.status == PluginPagedComicListStatus.success) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                t.comicList.nothingHere,
                style: const TextStyle(fontSize: 20.0),
              ),
            ),
          ),
        ],
      );
    }

    final list = mapToUnifiedComicSimplifyEntryInfoList(state.list);

    return PluginComicGridSliver(
      controller: scrollController,
      entries: list,
      hasReachedMax: state.hasReachedMax,
      isLoadingMore: state.status == PluginPagedComicListStatus.loadingMore,
      loadMoreFailed:
          state.status == PluginPagedComicListStatus.loadingMoreFailure,
      onRetryLoadMore: () =>
          context.read<PluginPagedComicListCubit>().retryLoadMore(),
      onLoadMore: () => context.read<PluginPagedComicListCubit>().loadMore(),
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
      collectionTargetId: widget.collectionTargetId,
      collectionTargetName: widget.collectionTargetName,
      detailed: widget.detailed,
    );
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<PluginPagedComicListCubit>().loadMore();
    }
  }

  bool get _isBottom {
    if (!scrollController.hasClients) return false;
    final maxScroll = scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return false;
    final currentScroll = scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
