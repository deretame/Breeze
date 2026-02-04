import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide Thumb;
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/search_result.dart';
import 'package:zephyr/util/context/context_extensions.dart';

import '../../../cubit/string_select.dart';
import '../../../type/enum.dart';
import '../../../widgets/comic_entry/comic_entry.dart';
import '../../../widgets/comic_simplify_entry/comic_simplify_entry.dart';
import '../../../widgets/comic_simplify_entry/comic_simplify_entry_info.dart';
import '../models/models.dart';

@RoutePage()
class SearchResultPage extends StatelessWidget implements AutoRouteWrapper {
  final SearchEvent searchEvent;
  final SearchCubit? searchCubit;

  const SearchResultPage({
    super.key,
    required this.searchEvent,
    this.searchCubit,
  });

  @override
  Widget wrappedRoute(BuildContext context) {
    logger.d(searchEvent);
    return MultiBlocProvider(
      providers: [
        searchCubit != null
            ? BlocProvider.value(value: searchCubit!)
            : BlocProvider(create: (_) => SearchCubit(SearchStates())),
        BlocProvider(create: (_) => SearchBloc()..add(searchEvent)),
        BlocProvider(create: (_) => StringSelectCubit()),
      ],
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SearchResultPage(searchEvent: searchEvent);
  }
}

class _SearchResultPage extends StatefulWidget {
  final SearchEvent searchEvent;

  const _SearchResultPage({required this.searchEvent});

  @override
  State<_SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<_SearchResultPage>
    with SingleTickerProviderStateMixin {
  late SearchEvent searchEvent;
  final _scrollController = ScrollController();
  late List<ComicNumber> comics;
  int pagesCount = 0;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  int _lastExecutedTime = 0; // 上次执行的时间

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // 动画持续时间
    );
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0), // 初始位置
          end: const Offset(0, 2),
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut, // 动画曲线
          ),
        );

    searchEvent = widget.searchEvent;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final keyword = widget.searchEvent.searchStates.searchKeyword.trim();
      if (keyword.isEmpty) return;
      final settingCubit = context.read<GlobalSettingCubit>();
      final List<String> history = settingCubit.state.searchHistory.toList();
      history
        ..remove(keyword)
        ..insert(0, keyword);
      await Future.delayed(const Duration(milliseconds: 200));
      settingCubit.updateSearchHistory(history.take(200).toList());
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SearchResultBar(searchEvent: searchEvent),
      body: _bloc(),
      // floatingActionButton: SlideTransition(
      //   position: _slideAnimation,
      //   child: PageSkip(
      //     pagesCount: pagesCount,
      //     searchEnter: _searchEnter,
      //     onChanged: _update,
      //   ),
      // ),
    );
  }

  Widget _bloc() => BlocBuilder<SearchBloc, SearchState>(
    builder: (context, state) {
      switch (state.status) {
        case SearchStatus.initial:
          return const Center(child: CircularProgressIndicator());
        case SearchStatus.failure:
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
                  onPressed: () {
                    _refresh(SearchStatus.initial);
                  },
                  child: Text('点击重试'),
                ),
              ],
            ),
          );
        case SearchStatus.success:
        case SearchStatus.loadingMore:
        case SearchStatus.getMoreFailure:
          return _comicList(state);
      }
    },
  );

  Widget _comicList(SearchState state) {
    final bool isBrevity = context.watch<BikaSettingCubit>().state.brevity;
    return isBrevity ? _brevityList(state) : _detailedList(state);
  }

  Widget _brevityList(SearchState state) {
    if (state.status == SearchStatus.success) {
      if (state.comics.length < 30 && !state.hasReachedMax) {
        _fetchSearchResult();
      }
      if (state.comics.isEmpty && state.hasReachedMax) {
        return const Center(
          child: Text('啥都没有', style: TextStyle(fontSize: 20.0)),
        );
      }
    }

    final list = state.comics.map((element) {
      final data = element.comicInfo as Bika;
      return ComicSimplifyEntryInfo(
        title: data.comics.title,
        id: data.comics.id,
        fileServer: data.comics.thumb.fileServer,
        path: data.comics.thumb.path,
        pictureType: "cover",
        from: "bika",
      );
    }).toList();

    final elementsRows = generateResponsiveRows(context, list);

    final itemCount = _calculateItemCount(state, elementsRows.length);

    return ListView.builder(
      itemBuilder: (context, index) =>
          _buildListItem(context, index, state, elementsRows),
      itemCount: itemCount,
      controller: _scrollController,
    );
  }

  Widget _detailedList(SearchState state) {
    comics = state.comics;
    pagesCount = state.searchEvent.page;

    if (state.status == SearchStatus.success) {
      if (state.comics.length < 8 && !state.hasReachedMax) {
        _fetchSearchResult();
      }
      if (state.comics.isEmpty && state.hasReachedMax) {
        return const Center(
          child: Text('啥都没有', style: TextStyle(fontSize: 20.0)),
        );
      }
    }

    final itemCount = _calculateItemCount(state, state.comics.length);

    return ListView.builder(
      itemBuilder: (context, index) => _buildListItem(context, index, state),
      itemCount: itemCount,
      controller: _scrollController,
    );
  }

  // 公共方法：计算item数量
  int _calculateItemCount(SearchState state, int dataLength) {
    var count = dataLength + 1;
    if (!state.hasReachedMax) count--;
    if (state.status == SearchStatus.loadingMore ||
        state.status == SearchStatus.getMoreFailure) {
      count++;
    }
    return count;
  }

  // 公共方法：构建列表项
  Widget _buildListItem(
    BuildContext context,
    int index,
    SearchState state, [
    List<List<ComicSimplifyEntryInfo>>? elementsRows,
  ]) {
    // 处理列表底部状态显示
    if (elementsRows != null && index >= elementsRows.length ||
        elementsRows == null && index >= state.comics.length) {
      return _buildListFooter(state);
    }

    // 简洁模式
    if (elementsRows != null) {
      final key = elementsRows[index].map((e) => e.id).join(',');
      return ComicSimplifyEntryRow(
        key: ValueKey(key),
        entries: elementsRows[index],
        type: ComicEntryType.normal,
      );
    }
    // 详细模式
    else {
      final data = state.comics[index].comicInfo;
      if (data is Bika) {
        return ComicEntryWidget(
          comicEntryInfo: docToComicEntryInfo(data.comics),
        );
      } else {
        return const SizedBox.shrink();
      }
    }
  }

  // 公共方法：构建列表底部
  Widget _buildListFooter(SearchState state) {
    switch (state.status) {
      case SearchStatus.success:
        if (state.hasReachedMax) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30.0),
              child: Text('没有更多了', style: TextStyle(fontSize: 20.0)),
            ),
          );
        }
        break;
      case SearchStatus.loadingMore:
        return const BottomLoader();
      case SearchStatus.getMoreFailure:
        return Center(
          child: Column(
            children: [
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _refresh(SearchStatus.loadingMore),
                child: const Text('点击重试'),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
    return const SizedBox.shrink();
  }

  void _refresh(SearchStatus status) {
    // 使用原本输入参数进行重新搜索
    context.read<SearchBloc>().add(searchEvent.copyWith(status: status));
  }

  void _fetchSearchResult() {
    context.read<SearchBloc>().add(
      searchEvent.copyWith(
        page: searchEvent.page + 1,
        status: SearchStatus.loadingMore,
      ),
    );
  }

  void _onScroll() {
    var currentTime = DateTime.now().millisecondsSinceEpoch;

    // logger.d(bikaSetting.brevity);
    // 只有当距离上一次执行超过50ms且漫画展示不为简略时，才执行
    final bool isBrevity = context.read<BikaSettingCubit>().state.brevity;
    if (currentTime - _lastExecutedTime > 100 && !isBrevity) {
      double itemHeight = 180.0 + ((context.screenHeight / 10) * 0.1);
      double currentScrollPosition = _scrollController.position.pixels;
      double middlePosition =
          currentScrollPosition + (context.screenHeight / 3);
      double listViewStartOffset = 0.0;
      int itemIndex = ((middlePosition - listViewStartOffset) / itemHeight)
          .floor();

      if (itemIndex >= 0 && itemIndex < comics.length) {
        int buildNumber = comics[itemIndex].buildNumber;
        // logger.d(comics[itemIndex].doc.title);
        context.read<StringSelectCubit>().setDate("$buildNumber/$pagesCount");
      }

      // 更新上次执行时间
      _lastExecutedTime = currentTime;
    }

    // 控制 FAB 的上下移动
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_animationController.isDismissed) {
        _animationController.forward(); // 向上滚动时隐藏 FAB
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (_animationController.isCompleted) {
        _animationController.reverse(); // 向下滚动时显示 FAB
      }
    }

    if (_isBottom) {
      _fetchSearchResult();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
