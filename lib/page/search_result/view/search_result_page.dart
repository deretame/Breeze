import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide Thumb;
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/page/comic_list/view/plugin_comic_grid_sliver.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/search_result.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_mapper.dart';

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
      final historyItem = _buildHistoryItem(widget.searchEvent);
      final settingCubit = context.read<GlobalSettingCubit>();
      final history = settingCubit.state.searchHistory.toList();
      history
        ..remove(historyItem)
        ..insert(0, historyItem);
      await Future.delayed(const Duration(milliseconds: 200));
      settingCubit.updateState(
        (current) =>
            current.copyWith(searchHistory: history.take(200).toList()),
      );
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
            final searchCubit = context.read<SearchCubit>();
            if (searchCubit.state != state.searchEvent.searchStates) {
              searchCubit.update(state.searchEvent.searchStates);
            }
          }
          return _comicList(state);
      }
    },
  );

  String _buildHistoryItem(SearchEvent event) {
    final keyword = event.searchStates.searchKeyword.trim();
    final payload = <String, dynamic>{};
    if (event.searchStates.pluginExtern.isNotEmpty) {
      payload['extern'] = event.searchStates.pluginExtern;
    }
    if (payload.isEmpty) {
      return keyword;
    }
    return '$keyword&&${jsonEncode(payload)}';
  }

  Widget _comicList(SearchState state) {
    return _genericList(state);
  }

  Widget _genericList(SearchState state) {
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

    final list = mapToUnifiedComicSimplifyEntryInfoList(
      state.comics.map((item) => item.comic),
    );

    return PluginComicGridSliver(
      controller: _scrollController,
      entries: list,
      hasReachedMax:
          state.hasReachedMax && state.status == SearchStatus.success,
      isLoadingMore: state.status == SearchStatus.loadingMore,
      loadMoreFailed: state.status == SearchStatus.getMoreFailure,
      onRetryLoadMore: () => _refresh(SearchStatus.loadingMore),
      onLoadMore: _fetchSearchResult,
    );
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
