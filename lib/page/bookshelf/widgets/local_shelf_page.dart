import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/model/unified_comic_list_item.dart';
import 'package:zephyr/model/unified_comic_list_item_mapper.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import 'package:zephyr/page/comic_list/view/plugin_comic_grid_sliver.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_mapper.dart';

class LocalShelfPage extends StatefulWidget {
  const LocalShelfPage({
    super.key,
    required this.mode,
    required this.refreshSignal,
  });

  final ShelfPageMode mode;
  final int refreshSignal;

  @override
  State<LocalShelfPage> createState() => _LocalShelfPageState();
}

class _LocalShelfPageState extends State<LocalShelfPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  late final BookshelfSectionBloc _bloc;
  bool _autoLoadArmed = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _bloc = BookshelfSectionBloc(mode: widget.mode);
    _scrollController.addListener(_onScroll);
    _dispatch();
  }

  @override
  void didUpdateWidget(covariant LocalShelfPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _dispatch();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final extentAfter = _scrollController.position.extentAfter;
    if (extentAfter > 640) {
      _autoLoadArmed = true;
      return;
    }
    if (!_autoLoadArmed || extentAfter > 320) {
      return;
    }
    _autoLoadArmed = false;
    _tryAutoLoadMore();
  }

  void _tryAutoLoadMore() {
    final section = _bloc.state;
    if (section.status != BookshelfLoadStatus.success) {
      return;
    }
    if (section.hasReachedMax ||
        section.isLoadingMore ||
        section.loadMoreFailed) {
      return;
    }
    _dispatch(append: true);
  }

  SearchEnter _buildSearchEnter(SearchStatusState state) {
    return SearchEnter(
      keyword: state.keyword,
      sort: state.sort,
      categories: state.categories,
      sources: state.sources,
      refresh: const Uuid().v4(),
    );
  }

  SearchStatusState _currentSearchState() {
    return context.read<BookshelfSearchCubit>().state.stateOf(widget.mode);
  }

  void _dispatch({bool append = false}) {
    _bloc.add(
      BookshelfLoadRequested(
        searchEnterConst: _buildSearchEnter(_currentSearchState()),
        append: append,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<BookshelfSectionBloc, BookshelfSectionState>(
        builder: (context, state) {
          if (state.status == BookshelfLoadStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == BookshelfLoadStatus.failure) {
            return _buildError(state.result);
          }

          return switch (widget.mode) {
            ShelfPageMode.favorite => _buildList(
              state.comics
                  .cast<UnifiedComicFavorite>()
                  .map(unifiedComicFromUnifiedFavorite)
                  .toList(),
              type: ComicEntryType.favorite,
              hasReachedMax: state.hasReachedMax,
              isLoadingMore: state.isLoadingMore,
              loadMoreFailed: state.loadMoreFailed,
            ),
            ShelfPageMode.history => _buildList(
              state.comics
                  .cast<UnifiedComicHistory>()
                  .map(unifiedComicFromUnifiedHistory)
                  .toList(),
              type: ComicEntryType.history,
              deleteType: DeleteType.history,
              hasReachedMax: state.hasReachedMax,
              isLoadingMore: state.isLoadingMore,
              loadMoreFailed: state.loadMoreFailed,
            ),
            ShelfPageMode.download => _buildList(
              state.comics
                  .cast<UnifiedComicDownload>()
                  .map(unifiedComicFromUnifiedDownload)
                  .toList(),
              type: ComicEntryType.download,
              deleteType: DeleteType.download,
              hasReachedMax: state.hasReachedMax,
              isLoadingMore: state.isLoadingMore,
              loadMoreFailed: state.loadMoreFailed,
            ),
          };
        },
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$message\n加载失败', textAlign: TextAlign.center),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _dispatch, child: const Text('点击重试')),
        ],
      ),
    );
  }

  Widget _buildList(
    List<UnifiedComicListItem> comics, {
    required ComicEntryType type,
    DeleteType? deleteType,
    required bool hasReachedMax,
    required bool isLoadingMore,
    required bool loadMoreFailed,
  }) {
    if (comics.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Spacer(),
            const Text('啥都没有', style: TextStyle(fontSize: 20.0)),
            const SizedBox(height: 10),
            IconButton(onPressed: _dispatch, icon: const Icon(Icons.refresh)),
            const Spacer(),
          ],
        ),
      );
    }

    final entries = mapToUnifiedComicSimplifyEntryInfoList(comics);
    return RefreshIndicator(
      onRefresh: () async => _dispatch(),
      child: PluginComicGridSliver(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        entries: entries,
        type: type,
        hasReachedMax: hasReachedMax,
        isLoadingMore: isLoadingMore,
        loadMoreFailed: loadMoreFailed,
        onRetryLoadMore: () => _dispatch(append: true),
        onLoadMore: () => _dispatch(append: true),
      ),
    );
  }
}
