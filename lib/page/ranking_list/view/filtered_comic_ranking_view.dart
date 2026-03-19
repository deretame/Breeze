import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/model/unified_comic_list_item_mapper.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/search_result/widgets/bottom_loader.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/json/json_dispose.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_grid.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_mapper.dart';
import 'package:zephyr/widgets/error_view.dart';

enum FilteredComicRankingStatus {
  initial,
  success,
  failure,
  loadingMore,
  loadingMoreFailure,
}

class FilteredComicRankingState extends Equatable {
  const FilteredComicRankingState({
    this.status = FilteredComicRankingStatus.initial,
    this.list = const <Map<String, dynamic>>[],
    this.hasReachedMax = false,
    this.page = 1,
    this.result = '',
  });

  final FilteredComicRankingStatus status;
  final List<Map<String, dynamic>> list;
  final bool hasReachedMax;
  final int page;
  final String result;

  FilteredComicRankingState copyWith({
    FilteredComicRankingStatus? status,
    List<Map<String, dynamic>>? list,
    bool? hasReachedMax,
    int? page,
    String? result,
  }) {
    return FilteredComicRankingState(
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

class FilteredComicRankingCubit extends Cubit<FilteredComicRankingState> {
  FilteredComicRankingCubit({
    required this.type,
    required this.order,
  }) : super(const FilteredComicRankingState());

  final String type;
  final String order;

  Future<void> loadInitial() async {
    emit(
      state.copyWith(
        status: FilteredComicRankingStatus.initial,
        list: const <Map<String, dynamic>>[],
        hasReachedMax: false,
        page: 1,
        result: '',
      ),
    );
    await _fetchPage(page: 1, append: false);
  }

  Future<void> loadMore() async {
    if (state.hasReachedMax ||
        state.status == FilteredComicRankingStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(status: FilteredComicRankingStatus.loadingMore));
    await _fetchPage(page: state.page + 1, append: true);
  }

  Future<void> retryLoadMore() async {
    await loadMore();
  }

  Future<void> _fetchPage({
    required int page,
    required bool append,
  }) async {
    final currentList = append ? state.list : const <Map<String, dynamic>>[];

    try {
      final pluginResponse = await callUnifiedComicPlugin(
        from: From.jm,
        fnPath: 'getRankingData',
        core: {'page': page},
        extern: {'type': type, 'order': order, 'source': 'ranking'},
      );
      final envelope = UnifiedPluginEnvelope.fromMap(pluginResponse);
      final data = asMap(envelope.data);
      final items = asList(data['items']).map((item) => asMap(item)).toList();
      final raw = replaceNestedNullList(asMap(data['raw']));
      final content = asList(
        raw['content'],
      ).map((item) => asMap(item)).toList();
      final nextItems = items.isNotEmpty ? items : content;

      final mergedList = [
        ...currentList,
        ...nextItems.map((item) => Map<String, dynamic>.from(item)),
      ];
      final hasReachedMax = data['hasReachedMax'] == true;

      emit(
        state.copyWith(
          status: FilteredComicRankingStatus.success,
          list: mergedList,
          hasReachedMax: hasReachedMax,
          page: page,
          result: page.toString(),
        ),
      );
    } catch (e, stackTrace) {
      logger.e(e, stackTrace: stackTrace);

      emit(
        state.copyWith(
          status: currentList.isNotEmpty
              ? FilteredComicRankingStatus.loadingMoreFailure
              : FilteredComicRankingStatus.failure,
          list: currentList,
          result: e.toString(),
        ),
      );
    }
  }
}

class FilteredComicRankingView extends StatelessWidget {
  const FilteredComicRankingView({
    super.key,
    required this.type,
    required this.order,
  });

  final String type;
  final String order;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          FilteredComicRankingCubit(type: type, order: order)..loadInitial(),
      child: _FilteredComicRankingBody(type: type, order: order),
    );
  }
}

class _FilteredComicRankingBody extends StatefulWidget {
  const _FilteredComicRankingBody({
    required this.type,
    required this.order,
  });

  final String type;
  final String order;

  @override
  State<_FilteredComicRankingBody> createState() =>
      _FilteredComicRankingBodyState();
}

class _FilteredComicRankingBodyState extends State<_FilteredComicRankingBody>
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
    return BlocBuilder<FilteredComicRankingCubit, FilteredComicRankingState>(
      builder: (context, state) {
        switch (state.status) {
          case FilteredComicRankingStatus.initial:
            return const Center(child: CircularProgressIndicator());
          case FilteredComicRankingStatus.failure:
            return ErrorView(
              errorMessage: '${state.result}\n加载失败，请重试。',
              onRetry: () =>
                  context.read<FilteredComicRankingCubit>().loadInitial(),
            );
          case FilteredComicRankingStatus.loadingMore:
          case FilteredComicRankingStatus.loadingMoreFailure:
          case FilteredComicRankingStatus.success:
            return _buildContent(context, state);
        }
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    FilteredComicRankingState state,
  ) {
    if (state.list.isEmpty && state.status == FilteredComicRankingStatus.success) {
      return const Center(
        child: Text('啥都没有', style: TextStyle(fontSize: 20.0)),
      );
    }

    final list = mapToUnifiedComicSimplifyEntryInfoList(
      state.list.map(unifiedComicFromMap),
    );

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        ComicSimplifyEntrySliverGrid(
          entries: list,
          type: ComicEntryType.normal,
        ),
        if (state.hasReachedMax)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(30.0),
                child: Text('没有更多了', style: TextStyle(fontSize: 20.0)),
              ),
            ),
          ),
        if (state.status == FilteredComicRankingStatus.loadingMore)
          const SliverToBoxAdapter(child: Center(child: BottomLoader())),
        if (state.status == FilteredComicRankingStatus.loadingMoreFailure)
          SliverToBoxAdapter(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => context
                        .read<FilteredComicRankingCubit>()
                        .retryLoadMore(),
                    child: const Text('点击重试'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<FilteredComicRankingCubit>().loadMore();
    }
  }

  bool get _isBottom {
    if (!scrollController.hasClients) return false;
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
