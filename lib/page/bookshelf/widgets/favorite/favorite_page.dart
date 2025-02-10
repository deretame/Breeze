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
      create: (_) => UserFavouriteBloc()
        ..add(UserFavouriteEvent(UserFavouriteStatus.initial, 1, Uuid().v4())),
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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    pageCount = 1;
    eventBus.on<FavoriteEvent>().listen((event) {
      if (event.type == EventType.refresh) {
        _refresh(initState: true);
      } else if (event.type == EventType.pageSkip) {
        _pageSkip(event.page);
      } else if (event.type == EventType.updateShield) {
        _refresh(updateShield: true);
      } else if (event.type == EventType.showInfo) {
        stringSelectStore.setDate("$_currentIndex/$pagesCount"); // 更新状态
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<UserFavouriteBloc, UserFavouriteState>(
      builder: (context, state) {
        return RefreshIndicator(
          displacement: 60.0,
          onRefresh: () async {
            // 触发刷新操作
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
          SizedBox(height: 10), // 添加间距
          ElevatedButton(
            onPressed: () => _refresh(),
            child: Text('点击重试'),
          ),
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
      return const Center(
        child: Text(
          '啥都没有',
          style: TextStyle(fontSize: 20.0),
        ),
      );
    }

    debugPrint(state.status.toString());
    debugPrint(state.hasReachedMax.toString());

    int itemCount = state.comics.length +
        (state.hasReachedMax ? 1 : 0) +
        (state.status == UserFavouriteStatus.loadingMore ? 1 : 0) +
        (state.status == UserFavouriteStatus.getMoreFailure ? 1 : 0);

    debugPrint(itemCount.toString());

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          if (widget.indexStore.date == 0) {
            final maxScroll = notification.metrics.maxScrollExtent;
            final currentScroll = notification.metrics.pixels;
            if (currentScroll >= maxScroll * 0.9) {
              _fetchFavoriteResult();
            }
            _handleScrollPosition(notification.metrics);
          }
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                // 如果索引等于状态的 comics.length，并且已经达到最大值
                if (index == state.comics.length) {
                  if (state.status == UserFavouriteStatus.success &&
                      state.hasReachedMax) {
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

                  if (state.status == UserFavouriteStatus.getMoreFailure) {
                    return Center(
                      child: ElevatedButton(
                        onPressed: () => _refresh(),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('点击重试'),
                        ),
                      ),
                    );
                  }

                  if (state.status == UserFavouriteStatus.loadingMore) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                } else {
                  return FavoriteComicEntryWidget(
                    comicEntryInfo: state.comics[index].doc,
                  );
                }
                return null;
              },
              childCount: itemCount,
            ),
          ),
        ],
      ),
    );
  }

  void _refresh({
    bool updateShield = false,
    bool initState = false,
  }) {
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
            UserFavouriteEvent(
              UserFavouriteStatus.loadingMore,
              pageCount,
              refresh,
            ),
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

  void _handleScrollPosition(ScrollMetrics metrics) {
    double itemHeight = 180.0 + ((screenHeight / 10) * 0.1); // 计算每个 item 的高度
    double currentScrollPosition = metrics.pixels; // 当前滚动位置
    double middlePosition =
        currentScrollPosition + (screenHeight / 3); // 计算中间位置
    double listViewStartOffset = 0.0; // ListView 的起始偏移量
    int itemIndex = ((middlePosition - listViewStartOffset) / itemHeight)
        .floor(); // 计算当前 item 的索引

    if (itemIndex >= 0 && itemIndex < comics.length) {
      int buildNumber =
          comics[itemIndex].buildNumber; // 获取当前 item 的 buildNumber
      debugPrint(comics[itemIndex].doc.title); // 打印当前 item 的标题
      stringSelectStore.setDate("$buildNumber/$pagesCount"); // 更新状态
      _currentIndex = buildNumber; // 更新当前索引
    }
  }
}
