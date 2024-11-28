import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/page/favourite/favorite.dart';

import '../../../config/global.dart';
import '../../../main.dart';
import '../../../mobx/string_select.dart';

@RoutePage()
class FavoritePage extends StatelessWidget {
  const FavoritePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FavouriteBloc()..add(FavouriteEvent(1, Uuid().v4())),
      child: _FavoritePage(),
    );
  }
}

class _FavoritePage extends StatefulWidget {
  const _FavoritePage();

  @override
  State<_FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<_FavoritePage>
    with SingleTickerProviderStateMixin {
  int pageCount = 0;
  String refresh = "";
  final pageStore = StringSelectStore();
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

    pageCount = 1;
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
    return Scaffold(
      appBar: AppBar(title: Text("收藏")),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Column(
              children: <Widget>[
                SizedBox(height: 35), // 为顶部阴影容器预留空间
                Expanded(
                  child: BlocBuilder<FavouriteBloc, FavouriteState>(
                    builder: (context, state) {
                      switch (state.status) {
                        case FavouriteStatus.failure:
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _showErrorDialog(
                              context,
                              "漫画加载失败:\n${state.result}",
                            );
                          });
                          // 因为必须要返回一个 Widget，所以这里返回一个空白的 SizedBox
                          return SizedBox.shrink();
                        case FavouriteStatus.success:
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

                              // 返回正在加载的项目或者漫画条目
                              return index >= state.comics.length
                                  ? const BottomLoader()
                                  : ComicEntryWidget(
                                      comicEntryInfo: state.comics[index].doc,
                                    );
                            },
                            itemCount: state.hasReachedMax
                                ? state.comics.length + 1 // 添加用于提示的文本
                                : state.comics.length,
                            controller: _scrollController,
                          );
                        case FavouriteStatus.initial:
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        case FavouriteStatus.loadingMore:
                          return ListView.builder(
                            itemBuilder: (BuildContext context, int index) {
                              if (index < state.comics.length) {
                                return ComicEntryWidget(
                                  comicEntryInfo: state.comics[index].doc,
                                );
                              } else {
                                return const BottomLoader(); // 显示加载动画
                              }
                            },
                            itemCount: state.hasReachedMax
                                ? state.comics.length
                                : state.comics.length + 1,
                            controller: _scrollController,
                          );
                        case FavouriteStatus.getMoreFailure:
                          // 弹出对话框
                          _showErrorDialog(
                            context,
                            "漫画加载失败:\n${state.result}",
                          );
                          return ListView.builder(
                            itemBuilder: (BuildContext context, int index) {
                              return ComicEntryWidget(
                                comicEntryInfo: state.comics[index].doc,
                              );
                            },
                            itemCount: state.comics.length,
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
    );
  }

  void _showErrorDialog(
    BuildContext context,
    String errorMessage,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('加载失败'),
          content: SingleChildScrollView(
            child: Text(errorMessage),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('重新加载'),
              onPressed: () {
                _refresh();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _refresh() {
    // 使用原本输入参数进行重新搜索
    context.read<FavouriteBloc>().add(
          FavouriteEvent(
            pageCount,
            Uuid().v4(),
          ),
        );
  }

  void _fetchFavoriteResult() {
    context.read<FavouriteBloc>().add(
          FavouriteEvent(
            pageCount + 1,
            refresh,
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
      _fetchFavoriteResult();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}