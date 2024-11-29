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
      create: (_) => SearchBloc()..add(FetchSearchResult(searchEnterConst)),
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
                                      _refresh(searchEnterConst);
                                    },
                                    child: Text('点击重试'),
                                  ),
                                ],
                              ),
                            );
                          case SearchStatus.success:
                            comics = state.comics;
                            pagesCount = state.pagesCount;
                            if (state.comics.length < 8 &&
                                !state.hasReachedMax) {
                              _fetchSearchResult();
                            }
                            _update(state.searchEnterConst);
                            if (state.comics.isEmpty) {
                              return const Center(
                                child: Text(
                                  '啥都没有',
                                  style: TextStyle(fontSize: 20.0),
                                ),
                              );
                            }
                            return ListView.builder(
                              itemBuilder: (BuildContext context, int index) {
                                // 如果索引等于状态的 comics.length，并且已经达到最大值
                                if (state.hasReachedMax &&
                                    index == state.comics.length) {
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

                                return index >= state.comics.length
                                    ? const BottomLoader()
                                    : ComicEntryWidget(
                                        comicEntryInfo: docToComicEntryInfo(
                                          state.comics[index].doc,
                                        ),
                                      );
                              },
                              itemCount: state.hasReachedMax
                                  ? state.comics.length + 1
                                  : state.comics.length,
                              controller: _scrollController,
                            );
                          case SearchStatus.loadingMore:
                            return ListView.builder(
                              itemBuilder: (BuildContext context, int index) {
                                if (index < state.comics.length) {
                                  return ComicEntryWidget(
                                    comicEntryInfo: docToComicEntryInfo(
                                      state.comics[index].doc,
                                    ),
                                  );
                                } else {
                                  return const BottomLoader(); // 显示加载动画
                                }
                              },
                              itemCount: state.comics.length + 1,
                              controller: _scrollController,
                            );
                          case SearchStatus.getMoreFailure:
                            return ListView.builder(
                              itemBuilder: (BuildContext context, int index) {
                                if (index == state.comics.length) {
                                  return Center(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _refresh(searchEnterConst);
                                      },
                                      child: Text('点击重试'),
                                    ),
                                  );
                                }

                                return index >= state.comics.length
                                    ? const BottomLoader()
                                    : ComicEntryWidget(
                                        comicEntryInfo: docToComicEntryInfo(
                                          state.comics[index].doc,
                                        ),
                                      );
                              },
                              itemCount: state.comics.length + 1,
                              controller: _scrollController,
                            );
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
                          ? Colors.black.withOpacity(0.2)
                          : Colors.white.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 2,
                      offset: const Offset(0, 2),
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

  void _refresh(SearchEnterConst searchEnterConst) {
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
          ),
        );
  }

  void _fetchSearchResult() {
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
          ),
        );
  }

  void _onScroll() {
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
      });
    });
  }
}
