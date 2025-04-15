import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';

import '../../../../config/global.dart';
import '../../../../main.dart';
import '../../../../mobx/int_select.dart';
import '../../../../mobx/string_select.dart';
import '../../../../widgets/comic_entry/comic_entry.dart';
import '../../../../widgets/comic_simplify_entry/comic_simplify_entry.dart';
import '../../../../widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

class FavoritePage extends StatelessWidget {
  final SearchStatusStore searchStatusStore;
  final StringSelectStore stringSelectStore;
  final IntSelectStore indexStore;

  const FavoritePage({
    super.key,
    required this.searchStatusStore,
    required this.stringSelectStore,
    required this.indexStore,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              UserFavouriteBloc()..add(
                UserFavouriteEvent(UserFavouriteStatus.initial, 1, Uuid().v4()),
              ),
      child: _FavoritePage(
        searchStatusStore: searchStatusStore,
        stringSelectStore: stringSelectStore,
        indexStore: indexStore,
      ),
    );
  }
}

class _FavoritePage extends StatefulWidget {
  final SearchStatusStore searchStatusStore;
  final StringSelectStore stringSelectStore;
  final IntSelectStore indexStore;

  const _FavoritePage({
    required this.searchStatusStore,
    required this.stringSelectStore,
    required this.indexStore,
  });

  @override
  State<_FavoritePage> createState() => _UserFavoritePageState();
}

class _UserFavoritePageState extends State<_FavoritePage>
    with AutomaticKeepAliveClientMixin {
  SearchStatusStore get searchStatusStore => widget.searchStatusStore;

  StringSelectStore get stringSelectStore => widget.stringSelectStore;

  late List<ComicNumber> comics;
  int pageCount = 0;
  String refresh = "";
  int pagesCount = 0;
  int _currentIndex = 0;

  ScrollController get _scrollController => scrollControllers['favorite']!;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    pageCount = 1;

    scrollControllers['favorite']!.addListener(_scrollListener);
    _scrollController.addListener(_scrollListener);
    eventBus.on<FavoriteEvent>().listen((event) {
      if (event.type == EventType.refresh) {
        _refresh(initState: true);
      } else if (event.type == EventType.pageSkip) {
        _pageSkip(event.page);
      } else if (event.type == EventType.updateShield) {
        _refresh(updateShield: true);
      } else if (event.type == EventType.showInfo) {
        if (!bikaSetting.brevity) {
          stringSelectStore.setDate("$_currentIndex/$pagesCount");
        } else {
          stringSelectStore.setDate("");
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _fetchFavoriteResult();
    }
    if (!bikaSetting.brevity) {
      _handleScrollPosition(_scrollController.position);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<UserFavouriteBloc, UserFavouriteState>(
      builder: (context, state) {
        return RefreshIndicator(
          displacement: 60.0,
          onRefresh: () async {
            if (widget.indexStore.date == 0) {
              _refresh(initState: true);
            }
          },
          child: _buildContent(state),
        );
      },
    );
  }

  Widget _buildContent(UserFavouriteState state) {
    switch (state.status) {
      case UserFavouriteStatus.initial:
        stringSelectStore.setDate("");
        return const Center(child: CircularProgressIndicator());
      case UserFavouriteStatus.failure:
        return _buildError(state);
      case UserFavouriteStatus.getMoreFailure:
      case UserFavouriteStatus.loadingMore:
      case UserFavouriteStatus.success:
        return _buildList(state);
    }
  }

  Widget _buildError(UserFavouriteState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${state.result.toString()}\n加载失败',
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 10),
          ElevatedButton(onPressed: () => _refresh(), child: Text('点击重试')),
        ],
      ),
    );
  }

  Widget _buildList(UserFavouriteState state) {
    _updateStateVariables(state);

    if (_shouldFetchMore(state)) {
      _fetchFavoriteResult();
    }

    if (state.comics.isEmpty) {
      return _buildEmptyState();
    }

    return bikaSetting.brevity
        ? _buildBrevityList(state)
        : _buildDetailedList(state);
  }

  // 状态更新
  void _updateStateVariables(UserFavouriteState state) {
    comics = state.comics;
    pageCount = state.pageCount;
    pagesCount = state.pagesCount;
    refresh = state.refresh;
  }

  // 判断是否需要获取更多
  bool _shouldFetchMore(UserFavouriteState state) {
    if (bikaSetting.brevity) {
      return state.comics.length < 30 && !state.hasReachedMax;
    } else {
      return state.comics.length < 8 && !state.hasReachedMax;
    }
  }

  // 空状态UI
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const Spacer(),
          const Text('啥都没有', style: TextStyle(fontSize: 20.0)),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _refresh, child: const Text('刷新')),
          const Spacer(),
        ],
      ),
    );
  }

  // 构建简洁模式列表
  Widget _buildBrevityList(UserFavouriteState state) {
    final elementsRows = generateElements(_convertToSimplifyList(state.comics));
    return _buildCommonListView(
      state: state,
      itemCount: elementsRows.length,
      itemBuilder: (context, index) => _buildBrevityItem(elementsRows[index]),
    );
  }

  // 构建详细模式列表
  Widget _buildDetailedList(UserFavouriteState state) {
    return _buildCommonListView(
      state: state,
      itemCount: state.comics.length,
      itemBuilder:
          (context, index) =>
              FavoriteComicEntryWidget(comicEntryInfo: state.comics[index].doc),
    );
  }

  // 公共列表构建方法
  ListView _buildCommonListView({
    required UserFavouriteState state,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    final showLoadingMore = state.status == UserFavouriteStatus.loadingMore;
    final showError = state.status == UserFavouriteStatus.getMoreFailure;
    final showEnd = state.hasReachedMax;
    final totalItemCount =
        itemCount + (showLoadingMore || showError || showEnd ? 1 : 0);

    return ListView.builder(
      itemExtent:
          bikaSetting.brevity
              ? screenWidth * 0.425
              : 180.0 + (screenHeight / 10) * 0.1,
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: totalItemCount,
      itemBuilder: (context, index) {
        if (index >= itemCount) {
          return _buildFooterItem(showLoadingMore, showError, showEnd);
        }
        return itemBuilder(context, index);
      },
    );
  }

  // 构建简洁模式下的列表项
  Widget _buildBrevityItem(List<ComicSimplifyEntryInfo> entries) {
    return ComicSimplifyEntry(
      key: ValueKey(entries.map((e) => e.id).join(',')),
      entries: entries,
      type: ComicEntryType.normal,
    );
  }

  // 构建底部加载/错误/结束项
  Widget _buildFooterItem(bool showLoadingMore, bool showError, bool showEnd) {
    if (showLoadingMore) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (showError) {
      return Center(
        child: ElevatedButton(
          onPressed: _refresh,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('点击重试'),
          ),
        ),
      );
    } else if (showEnd) {
      return Column(
        children: [
          SizedBox(height: 10),
          IconButton(
            onPressed: () {
              eventBus.fire(FavoriteEvent(EventType.refresh, SortType.dd, 1));
            },
            icon: const Icon(Icons.refresh),
          ),
          Center(child: Text('没有更多了', style: const TextStyle(fontSize: 20.0))),
          SizedBox(height: 10),
        ],
      );
    }
    return SizedBox.shrink();
  }

  // 转换数据为简洁模式需要的格式
  List<ComicSimplifyEntryInfo> _convertToSimplifyList(
    List<ComicNumber> comics,
  ) {
    return comics
        .map(
          (element) => ComicSimplifyEntryInfo(
            title: element.doc.title,
            id: element.doc.id,
            fileServer: element.doc.thumb.fileServer,
            path: element.doc.thumb.path,
            pictureType: "favourite",
            from: "bika",
          ),
        )
        .toList();
  }

  void _refresh({bool updateShield = false, bool initState = false}) {
    if (updateShield) {
      context.read<UserFavouriteBloc>().add(
        UserFavouriteEvent(
          UserFavouriteStatus.loadingMore,
          pageCount,
          "updateShield",
        ),
      );
      return;
    }

    if (initState) {
      context.read<UserFavouriteBloc>().add(
        UserFavouriteEvent(
          UserFavouriteStatus.initial,
          1,
          Uuid().v4().toString(),
        ),
      );
    }

    if (pageCount != 1) {
      context.read<UserFavouriteBloc>().add(
        UserFavouriteEvent(UserFavouriteStatus.loadingMore, pageCount, refresh),
      );
    } else {
      context.read<UserFavouriteBloc>().add(
        UserFavouriteEvent(
          UserFavouriteStatus.initial,
          1,
          Uuid().v4().toString(),
        ),
      );
    }
  }

  void _pageSkip(int page) {
    context.read<UserFavouriteBloc>().add(
      UserFavouriteEvent(
        UserFavouriteStatus.initial,
        page,
        Uuid().v4().toString(),
      ),
    );
  }

  void _fetchFavoriteResult() {
    context.read<UserFavouriteBloc>().add(
      UserFavouriteEvent(
        UserFavouriteStatus.loadingMore,
        pageCount + 1,
        refresh,
      ),
    );
  }

  var _lastExecutedTime = 0;

  void _handleScrollPosition(ScrollMetrics metrics) {
    double itemHeight = 180.0 + ((screenHeight / 10) * 0.1);
    double currentScrollPosition = metrics.pixels;
    double middlePosition = currentScrollPosition + (screenHeight / 3);
    double listViewStartOffset = 0.0;
    int itemIndex =
        ((middlePosition - listViewStartOffset) / itemHeight).floor();

    var currentTime = DateTime.now().millisecondsSinceEpoch;

    if (currentTime - _lastExecutedTime > 100) {
      if (itemIndex >= 0 && itemIndex < comics.length) {
        int buildNumber = comics[itemIndex].buildNumber;
        // logger.d(comics[itemIndex].doc.title);
        stringSelectStore.setDate("$buildNumber/$pagesCount");
        _currentIndex = buildNumber;
        // 更新上次执行时间
        _lastExecutedTime = currentTime;
      }
    }
  }
}
