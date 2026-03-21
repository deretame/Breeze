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

typedef PluginPageCoreBuilder = Map<String, dynamic> Function(int page);
typedef PluginPageExternBuilder = Map<String, dynamic> Function(int page);

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
    this.list = const <Map<String, dynamic>>[],
    this.hasReachedMax = false,
    this.page = 1,
    this.result = '',
  });

  final PluginPagedComicListStatus status;
  final List<Map<String, dynamic>> list;
  final bool hasReachedMax;
  final int page;
  final String result;

  PluginPagedComicListState copyWith({
    PluginPagedComicListStatus? status,
    List<Map<String, dynamic>>? list,
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
    required this.from,
    required this.fnPath,
    required this.coreBuilder,
    required this.externBuilder,
  }) : super(const PluginPagedComicListState());

  final From from;
  final String fnPath;
  final PluginPageCoreBuilder coreBuilder;
  final PluginPageExternBuilder externBuilder;

  Future<void> loadInitial() async {
    _safeEmit(
      state.copyWith(
        status: PluginPagedComicListStatus.initial,
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
    final currentList = append ? state.list : const <Map<String, dynamic>>[];

    try {
      final pluginResponse = await callUnifiedComicPlugin(
        from: from,
        fnPath: fnPath,
        core: coreBuilder(page),
        extern: externBuilder(page),
      );
      final envelope = UnifiedPluginEnvelope.fromMap(pluginResponse);
      final data = asMap(envelope.data);
      final items = asList(data['items']).map((item) => asMap(item)).toList();
      final raw = replaceNestedNullList(asMap(data['raw']));
      final listLikeKeys = ['content', 'list'];

      List<Map<String, dynamic>> nextItems = items
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      if (nextItems.isEmpty) {
        for (final key in listLikeKeys) {
          final rawList = asList(raw[key]).map((item) => asMap(item)).toList();
          if (rawList.isNotEmpty) {
            nextItems = rawList
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            break;
          }
        }
      }

      final mergedList = [...currentList, ...nextItems];
      final hasReachedMax = data['hasReachedMax'] == true;

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
    required this.from,
    required this.fnPath,
    required this.coreBuilder,
    required this.externBuilder,
    required this.itemMapper,
  });

  final From from;
  final String fnPath;
  final PluginPageCoreBuilder coreBuilder;
  final PluginPageExternBuilder externBuilder;
  final Map<String, dynamic> Function(Map<String, dynamic> item) itemMapper;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PluginPagedComicListCubit(
        from: from,
        fnPath: fnPath,
        coreBuilder: coreBuilder,
        externBuilder: externBuilder,
      )..loadInitial(),
      child: _PluginPagedComicListBody(itemMapper: itemMapper),
    );
  }
}

class _PluginPagedComicListBody extends StatefulWidget {
  const _PluginPagedComicListBody({required this.itemMapper});

  final Map<String, dynamic> Function(Map<String, dynamic> item) itemMapper;

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

    final normalized = state.list.map(widget.itemMapper);
    final list = mapToUnifiedComicSimplifyEntryInfoList(
      normalized.map(unifiedComicFromMap),
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
        if (state.status == PluginPagedComicListStatus.loadingMore)
          const SliverToBoxAdapter(child: Center(child: BottomLoader())),
        if (state.status == PluginPagedComicListStatus.loadingMoreFailure)
          SliverToBoxAdapter(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => context
                        .read<PluginPagedComicListCubit>()
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
      context.read<PluginPagedComicListCubit>().loadMore();
    }
  }

  bool get _isBottom {
    if (!scrollController.hasClients) return false;
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
