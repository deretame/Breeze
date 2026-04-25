import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/model/unified_comic_list_item.dart';
import 'package:zephyr/model/unified_comic_list_item_mapper.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/comic_list/view/plugin_comic_grid_sliver.dart';
import 'package:zephyr/util/json/json_dispose.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_mapper.dart';
import 'package:zephyr/widgets/error_view.dart';

typedef PluginPageCoreBuilder = Map<String, dynamic> Function(int page);
typedef PluginPageExternBuilder = Map<String, dynamic> Function(int page);

Map<String, dynamic> _sanitizePluginItemMap(dynamic item) {
  return asMap(replaceNestedNullList(asMap(item)));
}

enum PluginPagedComicListStatus {
  initial,
  success,
  failure,
  loadingMore,
  loadingMoreFailure,
}

class PluginPagedComicListState extends Equatable {
  const PluginPagedComicListState({
    this.status = PluginPagedComicListStatus.initial,
    this.list = const <UnifiedComicListItem>[],
    this.hasReachedMax = false,
    this.page = 1,
    this.result = '',
  });

  final PluginPagedComicListStatus status;
  final List<UnifiedComicListItem> list;
  final bool hasReachedMax;
  final int page;
  final String result;

  PluginPagedComicListState copyWith({
    PluginPagedComicListStatus? status,
    List<UnifiedComicListItem>? list,
    bool? hasReachedMax,
    int? page,
    String? result,
  }) {
    return PluginPagedComicListState(
      status: status ?? this.status,
      list: list ?? this.list,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      page: page ?? this.page,
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [status, list, hasReachedMax, page, result];
}

class PluginPagedComicListCubit extends Cubit<PluginPagedComicListState> {
  PluginPagedComicListCubit({
    required this.pluginId,
    required this.fnPath,
    required this.coreBuilder,
    required this.externBuilder,
  }) : super(const PluginPagedComicListState());

  final String pluginId;
  final String fnPath;
  final PluginPageCoreBuilder coreBuilder;
  final PluginPageExternBuilder externBuilder;

  Future<void> loadInitial() async {
    _safeEmit(
      state.copyWith(
        status: PluginPagedComicListStatus.initial,
        list: const <UnifiedComicListItem>[],
        hasReachedMax: false,
        page: 1,
        result: '',
      ),
    );
    await _fetchPage(page: 1, append: false);
  }

  Future<void> loadMore() async {
    if (state.hasReachedMax ||
        state.status == PluginPagedComicListStatus.loadingMore) {
      return;
    }

    _safeEmit(state.copyWith(status: PluginPagedComicListStatus.loadingMore));
    await _fetchPage(page: state.page + 1, append: true);
  }

  Future<void> retryLoadMore() async {
    await loadMore();
  }

  Future<void> _fetchPage({required int page, required bool append}) async {
    final currentList = append ? state.list : const <UnifiedComicListItem>[];
    final resolvedFnPath = fnPath.trim();

    try {
      if (resolvedFnPath.isEmpty) {
        throw StateError('插件列表请求缺少 fnPath: pluginId=$pluginId');
      }
      final pluginResponse = await callUnifiedComicPlugin(
        pluginId: pluginId,
        fnPath: resolvedFnPath,
        core: coreBuilder(page),
        extern: externBuilder(page),
      );
      final envelope = UnifiedPluginEnvelope.fromMap(pluginResponse);
      final data = asMap(envelope.data);
      final source = envelope.source.trim().isNotEmpty
          ? envelope.source.trim()
          : pluginId;
      final items = asList(data['items']).map(_sanitizePluginItemMap).toList();
      final raw = replaceNestedNullList(asMap(data['raw']));
      final listLikeKeys = ['content', 'list'];

      List<UnifiedComicListItem> nextItems = items
          .map((item) => unifiedComicFromPluginListMap(item, source: source))
          .toList();
      if (nextItems.isEmpty) {
        for (final key in listLikeKeys) {
          final rawList = asList(raw[key]).map(_sanitizePluginItemMap).toList();
          if (rawList.isNotEmpty) {
            nextItems = rawList
                .map(
                  (item) => unifiedComicFromPluginListMap(item, source: source),
                )
                .toList();
            break;
          }
        }
      }

      final mergedList = [...currentList, ...nextItems];
      final hasReachedMax = data['hasReachedMax'] == true || nextItems.isEmpty;

      _safeEmit(
        state.copyWith(
          status: PluginPagedComicListStatus.success,
          list: mergedList,
          hasReachedMax: hasReachedMax,
          page: page,
          result: page.toString(),
        ),
      );
    } catch (e, stackTrace) {
      logger.e(e, stackTrace: stackTrace);

      _safeEmit(
        state.copyWith(
          status: currentList.isNotEmpty
              ? PluginPagedComicListStatus.loadingMoreFailure
              : PluginPagedComicListStatus.failure,
          list: currentList,
          result: e.toString(),
        ),
      );
    }
  }

  void _safeEmit(PluginPagedComicListState nextState) {
    if (isClosed) {
      return;
    }
    emit(nextState);
  }
}

class PluginPagedComicListView extends StatelessWidget {
  const PluginPagedComicListView({
    super.key,
    required this.pluginId,
    required this.fnPath,
    required this.coreBuilder,
    required this.externBuilder,
    this.shrinkWrap = false,
    this.physics,
  });

  final String pluginId;
  final String fnPath;
  final PluginPageCoreBuilder coreBuilder;
  final PluginPageExternBuilder externBuilder;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PluginPagedComicListCubit(
        pluginId: pluginId,
        fnPath: fnPath,
        coreBuilder: coreBuilder,
        externBuilder: externBuilder,
      )..loadInitial(),
      child: _PluginPagedComicListBody(
        shrinkWrap: shrinkWrap,
        physics: physics,
      ),
    );
  }
}

class _PluginPagedComicListBody extends StatefulWidget {
  const _PluginPagedComicListBody({
    required this.shrinkWrap,
    required this.physics,
  });

  final bool shrinkWrap;
  final ScrollPhysics? physics;

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
    return BlocBuilder<PluginPagedComicListCubit, PluginPagedComicListState>(
      builder: (context, state) {
        switch (state.status) {
          case PluginPagedComicListStatus.initial:
            return const Center(child: CircularProgressIndicator());
          case PluginPagedComicListStatus.failure:
            return ErrorView(
              errorMessage: '${state.result}\n加载失败，请重试。',
              onRetry: () =>
                  context.read<PluginPagedComicListCubit>().loadInitial(),
            );
          case PluginPagedComicListStatus.loadingMore:
          case PluginPagedComicListStatus.loadingMoreFailure:
          case PluginPagedComicListStatus.success:
            return _buildContent(context, state);
        }
      },
    );
  }

  Widget _buildContent(BuildContext context, PluginPagedComicListState state) {
    if (state.list.isEmpty &&
        state.status == PluginPagedComicListStatus.success) {
      return const Center(
        child: Text('啥都没有', style: TextStyle(fontSize: 20.0)),
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
      physics: widget.physics,
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
