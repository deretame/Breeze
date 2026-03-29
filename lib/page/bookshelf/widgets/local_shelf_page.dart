import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/model/unified_comic_list_item.dart';
import 'package:zephyr/model/unified_comic_list_item_mapper.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_grid.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_mapper.dart';

enum ShelfPageMode { favorite, history, download }

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
  late final Object _bloc;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _bloc = _createBloc();
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
    _scrollController.dispose();
    if (_bloc is LocalFavoriteBloc) {
      (_bloc).close();
    } else if (_bloc is UserHistoryBloc) {
      (_bloc).close();
    } else if (_bloc is UserDownloadBloc) {
      (_bloc).close();
    }
    super.dispose();
  }

  Object _createBloc() {
    return switch (widget.mode) {
      ShelfPageMode.favorite => LocalFavoriteBloc(),
      ShelfPageMode.history => UserHistoryBloc(),
      ShelfPageMode.download => UserDownloadBloc(),
    };
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

  void _dispatch() {
    if (widget.mode == ShelfPageMode.favorite) {
      final state = context.read<LocalFavoriteCubit>().state;
      (_bloc as LocalFavoriteBloc).add(
        LocalFavoriteEvent(searchEnterConst: _buildSearchEnter(state)),
      );
      return;
    }

    if (widget.mode == ShelfPageMode.history) {
      final state = context.read<HistoryCubit>().state;
      (_bloc as UserHistoryBloc).add(
        UserHistoryEvent(_buildSearchEnter(state), 0),
      );
      return;
    }

    final state = context.read<DownloadCubit>().state;
    (_bloc as UserDownloadBloc).add(
      UserDownloadEvent(_buildSearchEnter(state), 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return switch (widget.mode) {
      ShelfPageMode.favorite => BlocProvider.value(
        value: _bloc as LocalFavoriteBloc,
        child: BlocBuilder<LocalFavoriteBloc, LocalFavoriteState>(
          builder: (context, state) {
            if (state.status == LocalFavoriteStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == LocalFavoriteStatus.failure) {
              return _buildError(state.result);
            }
            final comics = state.comics
                .map(unifiedComicFromUnifiedFavorite)
                .toList();
            return _buildList(comics, type: ComicEntryType.favorite);
          },
        ),
      ),
      ShelfPageMode.history => BlocProvider.value(
        value: _bloc as UserHistoryBloc,
        child: BlocBuilder<UserHistoryBloc, UserHistoryState>(
          builder: (context, state) {
            if (state.status == UserHistoryStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == UserHistoryStatus.failure) {
              return _buildError(state.result);
            }
            final comics = state.comics
                .cast<UnifiedComicHistory>()
                .map(unifiedComicFromUnifiedHistory)
                .toList();
            return _buildList(
              comics,
              type: ComicEntryType.history,
              deleteType: DeleteType.history,
            );
          },
        ),
      ),
      ShelfPageMode.download => BlocProvider.value(
        value: _bloc as UserDownloadBloc,
        child: BlocBuilder<UserDownloadBloc, UserDownloadState>(
          builder: (context, state) {
            if (state.status == UserDownloadStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == UserDownloadStatus.failure) {
              return _buildError(state.result);
            }
            final comics = state.comics
                .cast<UnifiedComicDownload>()
                .map(unifiedComicFromUnifiedDownload)
                .toList();
            return _buildList(
              comics,
              type: ComicEntryType.download,
              deleteType: DeleteType.download,
            );
          },
        ),
      ),
    };
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
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ComicSimplifyEntrySliverGrid(entries: entries, type: type),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 10),
                IconButton(
                  onPressed: _dispatch,
                  icon: const Icon(Icons.refresh),
                ),
                if (deleteType != null)
                  deletingDialog(context, _dispatch, deleteType),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
