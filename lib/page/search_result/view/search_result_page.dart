import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/page/search_result/search_result.dart';

import '../../../config/global.dart';
import '../../../main.dart';
import '../../../mobx/string_select.dart';
import '../../../widgets/comic_entry/comic_entry.dart';
import '../models/models.dart';
import '../widgets/page_skip.dart';

@RoutePage()
class SearchResultPage extends StatelessWidget {
  final SearchEnterConst searchEnterConst;

  const SearchResultPage({
    super.key,
    required this.searchEnterConst,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchBloc()
        ..add(
          FetchSearchResult(
            searchEnterConst,
            SearchStatus.initial,
          ),
        ),
      child: _SearchResultPage(searchEnterConst: searchEnterConst),
    );
  }
}

class _SearchResultPage extends StatefulWidget {
  final SearchEnterConst searchEnterConst;

  const _SearchResultPage({
    required this.searchEnterConst,
  });

  @override
  State<_SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<_SearchResultPage>
    with SingleTickerProviderStateMixin {
  get searchEnterConst => widget.searchEnterConst;

  final pageStore = StringSelectStore();
  late SearchEnter _searchEnter;
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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0), // 初始位置
      end: const Offset(0, 2),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut, // 动画曲线
    ));

    _searchEnter = SearchEnter.fromConst(searchEnterConst);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SearchEnterProvider(
      searchEnter: _searchEnter,
      child: Scaffold(
        appBar: BikaSearchBar(),
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Column(
                children: <Widget>[
                  SizedBox(height: 35), // 为顶部阴影容器预留空间
                  Expanded(
                    child: BlocBuilder<SearchBloc, SearchState>(
                      builder: (context, state) {
                        _update(state.searchEnterConst);
                        switch (state.status) {
                          case SearchStatus.initial:
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
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
                                      _refresh(
                                        SearchEnterConst.from(_searchEnter),
                                        SearchStatus.initial,
                                      );
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
                    ),
                  ),
                ],
              ),
            ),
            // 这里是操作栏
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 35,
                decoration: BoxDecoration(
                  color: globalSetting.backgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: globalSetting.themeType
                          ? materialColorScheme.secondaryFixedDim
                          : materialColorScheme.secondaryFixedDim,
                      spreadRadius: 0,
                      blurRadius: 2,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    SizedBox(width: 5),
                    SortWidget(),
                    SizedBox(width: 5),
                    CategoriesSelect(),
                    SizedBox(width: 5),
                    CategoriesShield(),
                    Expanded(child: Container()),
                    Observer(builder: (context) {
                      return Text(
                        pageStore.date,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      );
                    }),
                    SizedBox(
                      width: 5,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: SlideTransition(
          position: _slideAnimation,
          child: PageSkip(
            pageStore: pageStore,
            pagesCount: pagesCount,
          ),
        ),
      ),
    );
  }

  Widget _comicList(SearchState state) {
    int itemCount = state.comics.length + 1;
    comics = state.comics;
    pagesCount = state.pagesCount;
    _searchEnter = SearchEnter.fromConst(state.searchEnterConst);
    if (state.status == SearchStatus.success) {
      if (state.comics.length < 8 && !state.hasReachedMax) {
        _fetchSearchResult();
      }
      if (state.comics.isEmpty && state.hasReachedMax) {
        return const Center(
          child: Text(
            '啥都没有',
            style: TextStyle(fontSize: 20.0),
          ),
        );
      }
      if (!state.hasReachedMax) {
        itemCount = itemCount - 1;
      }
    }

    return ListView.builder(
      itemBuilder: (BuildContext context, int index) {
        if (index == state.comics.length) {
          switch (state.status) {
            case SearchStatus.success:
              if (state.hasReachedMax) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Text(
                      '你来到了未知领域呢~',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ),
                );
              }
            case SearchStatus.loadingMore:
              return const BottomLoader(); // 显示加载动画
            case SearchStatus.getMoreFailure:
              return Center(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        _refresh(
                          SearchEnterConst.from(_searchEnter),
                          SearchStatus.loadingMore,
                        );
                      },
                      child: const Text('点击重试'),
                    ),
                  ],
                ),
              );
            default:
              break;
          }
        }

        return ComicEntryWidget(
          comicEntryInfo: docToComicEntryInfo(
            state.comics[index].doc,
          ),
        );
      },
      itemCount: itemCount,
      controller: _scrollController,
    );
  }

  void _refresh(
    SearchEnterConst searchEnterConst,
    SearchStatus status,
  ) {
    // 使用原本输入参数进行重新搜索
    context.read<SearchBloc>().add(
          FetchSearchResult(
            SearchEnterConst(
              url: searchEnterConst.url,
              from: searchEnterConst.from,
              keyword: searchEnterConst.keyword,
              type: searchEnterConst.type,
              state: searchEnterConst.state,
              sort: searchEnterConst.sort,
              categories: searchEnterConst.categories,
              pageCount: searchEnterConst.pageCount,
              refresh: Uuid().v4(), //传入一个不一样的值，来强行刷新
            ),
            status,
          ),
        );
  }

  void _fetchSearchResult() {
    debugPrint('pagesCount: ${_searchEnter.pageCount + 1}');
    context.read<SearchBloc>().add(
          FetchSearchResult(
            SearchEnterConst(
              url: _searchEnter.url,
              from: _searchEnter.from,
              keyword: _searchEnter.keyword,
              type: _searchEnter.type,
              state: _searchEnter.state,
              sort: _searchEnter.sort,
              categories: _searchEnter.categories,
              pageCount: _searchEnter.pageCount + 1,
              refresh: _searchEnter.refresh,
            ),
            SearchStatus.loadingMore,
          ),
        );
  }

  void _onScroll() {
    var currentTime = DateTime.now().millisecondsSinceEpoch;

    // 只有当距离上一次执行超过10ms时，才执行
    if (currentTime - _lastExecutedTime > 10) {
      double itemHeight = 180.0 + ((screenHeight / 10) * 0.1);
      double currentScrollPosition = _scrollController.position.pixels;
      double middlePosition = currentScrollPosition + (screenHeight / 3);
      double listViewStartOffset = 0.0;
      int itemIndex =
          ((middlePosition - listViewStartOffset) / itemHeight).floor();

      if (itemIndex >= 0 && itemIndex < comics.length) {
        int buildNumber = comics[itemIndex].buildNumber;
        debugPrint(comics[itemIndex].doc.title);
        pageStore.setDate("$buildNumber/$pagesCount");
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

  void _update(SearchEnterConst searchEnterConst) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _searchEnter = SearchEnter.fromConst(searchEnterConst);
        // debugPrint('pagesCount: ${searchEnterConst.pageCount}');
      });
    });
  }
}
