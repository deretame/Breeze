import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';

import '../../../../config/global.dart';
import '../../../../main.dart';
import '../../../../mobx/int_select.dart';
import '../../../../mobx/string_select.dart';

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
        stringSelectStore.setDate("$_currentIndex/$pagesCount");
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
    _handleScrollPosition(_scrollController.position);
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
    comics = state.comics;
    pageCount = state.pageCount;
    pagesCount = state.pagesCount;
    refresh = state.refresh;

    if (state.comics.length < 8 && !state.hasReachedMax) {
      _fetchFavoriteResult();
    }

    if (state.comics.isEmpty) {
      return Center(
        child: Center(
          child: Column(
            children: [
              const Spacer(),
              const Text('啥都没有', style: TextStyle(fontSize: 20.0)),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _refresh, child: const Text('刷新')),
              const Spacer(),
            ],
          ),
        ),
      );
    }

    int itemCount = state.comics.length;
    bool showLoadingMore = state.status == UserFavouriteStatus.loadingMore;
    bool showError = state.status == UserFavouriteStatus.getMoreFailure;
    bool showEnd = state.hasReachedMax;

    return ListView.builder(
      controller: _scrollController,
      physics: AlwaysScrollableScrollPhysics(),
      itemCount: itemCount + (showLoadingMore || showError || showEnd ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= itemCount) {
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
                onPressed: () => _refresh(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('点击重试'),
                ),
              ),
            );
          } else if (showEnd) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Text(
                  '你来到了未知领域呢~',
                  style: const TextStyle(fontSize: 20.0),
                ),
              ),
            );
          }
        }

        return FavoriteComicEntryWidget(
          comicEntryInfo: state.comics[index].doc,
        );
      },
    );
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

    if (currentTime - _lastExecutedTime > 50) {
      if (itemIndex >= 0 && itemIndex < comics.length) {
        int buildNumber = comics[itemIndex].buildNumber;
        logger.d(comics[itemIndex].doc.title);
        stringSelectStore.setDate("$buildNumber/$pagesCount");
        _currentIndex = buildNumber;
        // 更新上次执行时间
        _lastExecutedTime = currentTime;
      }
    }
  }
}
