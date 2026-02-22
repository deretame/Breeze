import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/cubit/int_select.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/debouncer.dart';
import 'package:zephyr/widgets/comic_entry/comic_entry.dart';

import '../../../../cubit/string_select.dart';
import '../../../../main.dart';
import '../../../../type/enum.dart';
import '../../../../widgets/comic_simplify_entry/comic_simplify_entry.dart';
import '../../../../widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserFavouriteBloc()
        ..add(UserFavouriteEvent(UserFavouriteStatus.initial, 1, Uuid().v4())),
      child: _FavoritePage(),
    );
  }
}

class _FavoritePage extends StatefulWidget {
  const _FavoritePage();

  @override
  State<_FavoritePage> createState() => _UserFavoritePageState();
}

class _UserFavoritePageState extends State<_FavoritePage>
    with AutomaticKeepAliveClientMixin {
  late List<dynamic> comics;
  int pageCount = 0;
  String refresh = "";
  int pagesCount = 0;
  int _currentIndex = 0;

  late final ScrollController _scrollController;

  late final StreamSubscription _eventSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    pageCount = 1;

    _scrollController = ScrollController();

    _scrollController.addListener(_scrollListener);
    _eventSubscription = eventBus.on<FavoriteEvent>().listen((event) {
      if (!mounted) return; // 增加 mounted 检查

      if (event.type == EventType.refresh) {
        _refresh(initState: true);
      } else if (event.type == EventType.pageSkip) {
        _pageSkip(event.page);
      } else if (event.type == EventType.updateShield) {
        _refresh(updateShield: true);
      } else if (event.type == EventType.showInfo) {
        final bikaSettingState = context.read<BikaSettingCubit>().state;
        if (!bikaSettingState.brevity) {
          context.read<StringSelectCubit>().setDate(
            "$_currentIndex/$pagesCount",
          );
        } else {
          context.read<StringSelectCubit>().setDate("");
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _eventSubscription.cancel();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _fetchFavoriteResult();
    }
    final bikaSettingState = context.read<BikaSettingCubit>().state;
    if (!bikaSettingState.brevity) {
      _handleScrollPosition(_scrollController.position);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocListener<UserFavouriteBloc, UserFavouriteState>(
      listener: (context, state) {
        if (state.status == UserFavouriteStatus.initial) {
          context.read<StringSelectCubit>().setDate("");
        }
      },
      child: BlocBuilder<UserFavouriteBloc, UserFavouriteState>(
        builder: (context, state) {
          return RefreshIndicator(
            displacement: 60.0,
            onRefresh: () async {
              if (context.read<IntSelectCubit>().state == 0) {
                _refresh(initState: true);
              }
            },
            child: _buildContent(state),
          );
        },
      ),
    );
  }

  Widget _buildContent(UserFavouriteState state) {
    switch (state.status) {
      case UserFavouriteStatus.initial:
        // --- 8. 移除这里的副作用 (已移至 BlocListener) ---
        // stringSelectStore.setDate("");
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

    final bikaSettingState = context.watch<BikaSettingCubit>().state;

    return bikaSettingState.brevity
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
    final bikaSettingState = context.watch<BikaSettingCubit>().state;

    if (bikaSettingState.brevity) {
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
    final list = _convertToSimplifyList(state.comics);
    final showLoadingMore = state.status == UserFavouriteStatus.loadingMore;
    final showError = state.status == UserFavouriteStatus.getMoreFailure;
    final showEnd = state.hasReachedMax;
    final maxExtent = isTabletWithOutContext() ? 200.0 : 150.0;

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(10),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxExtent,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              return ComicSimplifyEntry(
                key: ValueKey(list[index].id),
                info: list[index],
                type: ComicEntryType.normal,
              );
            }, childCount: list.length),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildFooterItem(showLoadingMore, showError, showEnd),
        ),
      ],
    );
  }

  // 构建详细模式列表
  Widget _buildDetailedList(UserFavouriteState state) {
    final temp = state.comics.map((e) => e as ComicNumber).toList();

    return _buildCommonListView(
      state: state,
      itemCount: temp.length,
      itemBuilder: (context, index) => ComicEntryWidget(
        comicEntryInfo: temp[index].doc.toComicEntryInfo(),
        pictureType: PictureType.favourite,
      ),
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
  List<ComicSimplifyEntryInfo> _convertToSimplifyList(List<dynamic> comics) {
    final comicChoice = context.read<GlobalSettingCubit>().state.comicChoice;

    if (comicChoice == 1) {
      final temp = comics.map((e) => e as ComicNumber).toList();

      return temp
          .map(
            (element) => ComicSimplifyEntryInfo(
              title: element.doc.title,
              id: element.doc.id,
              fileServer: element.doc.thumb.fileServer,
              path: element.doc.thumb.path,
              pictureType: PictureType.favourite,
              from: From.bika,
            ),
          )
          .toList();
    } else {
      return [];
    }
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
      return;
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
    double itemHeight = 180.0 + ((context.screenHeight / 10) * 0.1);
    double currentScrollPosition = metrics.pixels;
    double middlePosition = currentScrollPosition + (context.screenHeight / 3);
    double listViewStartOffset = 0.0;
    int itemIndex = ((middlePosition - listViewStartOffset) / itemHeight)
        .floor();

    var currentTime = DateTime.now().millisecondsSinceEpoch;

    if (currentTime - _lastExecutedTime > 100) {
      final temp = comics.map((e) => e as ComicNumber).toList();
      if (itemIndex >= 0 && itemIndex < temp.length) {
        int buildNumber = temp[itemIndex].buildNumber;
        // logger.d(comics[itemIndex].doc.title);
        context.read<StringSelectCubit>().setDate("$buildNumber/$pagesCount");
        _currentIndex = buildNumber;
        // 更新上次执行时间
        _lastExecutedTime = currentTime;
      }
    }
  }
}
