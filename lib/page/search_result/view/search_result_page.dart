import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide Thumb;
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/search_result.dart';

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
    return MultiBlocProvider(
      providers: [
        searchCubit != null
            ? BlocProvider.value(value: searchCubit!)
            : BlocProvider(
                create: (_) => SearchCubit(searchEvent.searchStates),
              ),
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
      final history = settingCubit.state.searchHistory.toList();
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: SearchResultBar(searchEvent: searchEvent),
      body: _bloc(),
      floatingActionButton: SlideTransition(
        position: _slideAnimation,
        child: SpeedDial(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          buttonSize: const Size(56, 56),
          childrenButtonSize: const Size(56, 56),
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          icon: Icons.menu,
          activeIcon: Icons.close,
          useRotationAnimation: true,
          animationDuration: const Duration(milliseconds: 300),
          spacing: 12,
          spaceBetweenChildren: 8,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.vertical_align_top),
              label: '返回顶部',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              onTap: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.shortcut),
              label: '跳转页面',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              onTap: () async {
                final int? targetPage = await showNumberInputDialog(
                  context: context,
                  title: '跳转',
                  initialValue: searchEvent.page,
                );

                if (targetPage != null && context.mounted) {
                  context.read<SearchBloc>().add(
                    searchEvent.copyWith(
                      page: targetPage,
                      status: SearchStatus.initial,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
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
          if (state.status == SearchStatus.success) {
            searchEvent = state.searchEvent;
          }
          return _comicList(state);
      }
    },
  );

  Widget _comicList(SearchState state) {
    final bool isBrevity =
        context.watch<BikaSettingCubit>().state.brevity ||
        context.read<SearchCubit>().state.from == From.jm;
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
      return element.comicInfo.when(
        bika: (data) => ComicSimplifyEntryInfo(
          title: data.title,
          id: data.id,
          fileServer: data.thumb.fileServer,
          path: data.thumb.path,
          pictureType: "cover",
          from: "bika",
        ),
        jm: (data) => ComicSimplifyEntryInfo(
          title: data.name,
          id: data.id,
          fileServer: getJmCoverUrl(data.id),
          path: "${data.id}.jpg",
          pictureType: 'cover',
          from: 'jm',
        ),
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
