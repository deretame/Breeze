import 'package:auto_route/auto_route.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:material_ui/material_ui.dart' hide Thumb;
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_list/view/plugin_comic_grid_sliver.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/models/models.dart';
import 'package:zephyr/page/search_result/search_cursor/search_cursor.dart';
import 'package:zephyr/page/search_result/search_result.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_grid.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_mapper.dart';
import 'package:zephyr/widgets/toast.dart';
import 'dart:math' as math;

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
  final _cursorStore = SearchCursorStore();
  bool _cursorPickMode = false;
  String? _pickedComicId;
  // 游标跳转落地后待揭示的锚点（成功回调里消费一次）。
  // 来源有二：本页 _jumpToCursor 直接设置；搜索页跳转经 SearchCursorReveal
  // 总线在 initState 转入。
  String? _pendingRevealAnchorId;
  // 揭示时滚动空间不足，已触发加载更多，等下一个 success 重试。
  String? _revealRetryAnchorId;
  // 为满足揭示额外加载的页数（上限 2，防止无限加载）。
  int _revealExtraPages = 0;
  // 跳转后需要描边高亮的锚点条目。
  String? _highlightComicId;
  int pagesCount = 0;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    final busAnchor = SearchCursorReveal.consume();
    if (busAnchor != null) {
      _pendingRevealAnchorId = busAnchor;
    }
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
            current.copyWith(searchHistory: history.take(300).toList()),
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
      appBar: SearchResultBar(
        searchEvent: searchEvent,
        onStartCursorPick: _startCursorPick,
        onJumpToCursor: _jumpToCursor,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _bloc()),
          if (_cursorPickMode)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildCursorPickBanner(colorScheme),
            ),
        ],
      ),
      floatingActionButtonLocation:
          context.watch<GlobalSettingCubit>().state.leftHandModeEnabled
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
      floatingActionButton: _cursorPickMode
          ? null
          : SlideTransition(
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
                    label: t.searchResult.returnToTop,
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
                    label: t.searchResult.jumpToPage,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                    onTap: () async {
                      final int? targetPage = await showNumberInputDialog(
                        context: context,
                        title: t.searchResult.jump,
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
          return Center(child: CircularProgressIndicator());
        case SearchStatus.failure:
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.result, style: TextStyle(fontSize: 20)),
                SizedBox(height: 10), // 添加间距
                ElevatedButton(
                  onPressed: () {
                    _refresh(SearchStatus.initial);
                  },
                  child: Text(t.searchResult.retry),
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
            final pendingAnchor = _pendingRevealAnchorId;
            if (pendingAnchor != null) {
              _pendingRevealAnchorId = null;
              _revealExtraPages = 0;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _revealAnchorAfterJump(pendingAnchor);
              });
            }
            final retryAnchor = _revealRetryAnchorId;
            if (retryAnchor != null) {
              _revealRetryAnchorId = null;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _revealAnchorAfterJump(retryAnchor);
              });
            }
          }
          return _comicList(state);
      }
    },
  );

  String _buildHistoryItem(SearchEvent event) {
    return event.searchStates.searchKeyword.trim();
  }

  Widget _comicList(SearchState state) {
    return _genericList(state);
  }

  Widget _genericList(SearchState state) {
    if (state.status == SearchStatus.success) {
      if (state.comics.isEmpty && state.hasReachedMax) {
        return Center(
          child: Text(
            t.comicList.nothingHere,
            style: TextStyle(fontSize: 20.0),
          ),
        );
      }
    }

    final list = mapToUnifiedComicSimplifyEntryInfoList(
      state.comics.map((item) => item.comic),
    );

    return PluginComicGridSliver(
      controller: _scrollController,
      entries: list,
      highlightEntryId: _highlightComicId,
      hasReachedMax:
          (state.hasReachedMax || _cursorPickMode) &&
          state.status == SearchStatus.success,
      isLoadingMore: state.status == SearchStatus.loadingMore,
      loadMoreFailed: state.status == SearchStatus.getMoreFailure,
      onRetryLoadMore: () => _refresh(SearchStatus.loadingMore),
      onLoadMore: _fetchSearchResult,
      physics: _cursorPickMode ? const NeverScrollableScrollPhysics() : null,
      selectionMode: _cursorPickMode,
      isEntrySelected: _cursorPickMode
          ? (entry) => entry.id == _pickedComicId
          : null,
      onEntryTap: _cursorPickMode
          ? (entry) {
              logger.d('cursor pick selected: id=${entry.id}');
              setState(() => _pickedComicId = entry.id);
            }
          : _highlightComicId != null
          // 游标高亮激活时，点任意封面先取消高亮（本次不进入详情）。
          ? (entry) => setState(() => _highlightComicId = null)
          : null,
      detailed: context
          .watch<GlobalSettingCubit>()
          .state
          .bookshelfSetting
          .detailLayout,
    );
  }

  Widget _buildCursorPickBanner(ColorScheme colorScheme) {
    return Material(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                t.searchResult.cursorPickBanner,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onSecondaryContainer),
              ),
            ),
            TextButton(
              onPressed: _exitCursorPick,
              child: Text(t.common.cancel),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _confirmCursorPick,
              child: Text(t.common.confirm),
            ),
          ],
        ),
      ),
    );
  }

  void _startCursorPick() {
    setState(() {
      _cursorPickMode = true;
      _pickedComicId = null;
    });
  }

  void _exitCursorPick() {
    setState(() {
      _cursorPickMode = false;
      _pickedComicId = null;
    });
  }

  /// 游标跳转落地后：滚动到锚点所在行并描边高亮该封面。
  void _revealAnchorAfterJump(String anchorId) {
    if (!mounted) return;
    final comics = context.read<SearchBloc>().state.comics;
    final index = comics.indexWhere((item) => item.comic.id == anchorId);
    if (index < 0) {
      logger.w('cursor jump: anchor missing in loaded page, id=$anchorId');
      return;
    }
    if (_ensureRevealScrollRoom(anchorId, index)) {
      // 二分定位的锚点几乎总在落地页尾部，一页内容往往不够把它滚到
      // 顶部；先静默加载下一页垫高内容，成功后再重试揭示。
      return;
    }
    _scrollToGridIndex(index);
    setState(() => _highlightComicId = anchorId);
  }

  /// 检查锚点行滚到顶所需空间是否超出当前可滚动范围。
  /// 超出且还能加载时触发加载更多并返回 true（由 _revealRetryAnchorId
  /// 在下一个 success 接力重试）。
  bool _ensureRevealScrollRoom(String anchorId, int index) {
    if (!_scrollController.hasClients) return false;
    final target = _estimateRevealOffset(index);
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (target <= maxExtent) return false;
    final bloc = context.read<SearchBloc>();
    if (bloc.state.hasReachedMax || _revealExtraPages >= 2) return false;
    _revealExtraPages++;
    _revealRetryAnchorId = anchorId;
    _fetchSearchResult();
    return true;
  }

  /// 按网格布局参数估算第 [index] 项到顶所需的滚动偏移。
  /// 与 buildComicSimplifyEntryGridDelegate / BaseComicGridSliver 的
  /// padding(10) 保持同步，若那边改动需要同步这里。
  double _estimateRevealOffset(int index) {
    final delegate = buildComicSimplifyEntryGridDelegate();
    if (delegate is! SliverGridDelegateWithMaxCrossAxisExtent) return 0;
    const padding = EdgeInsets.all(10);
    final contentWidth = MediaQuery.sizeOf(context).width - padding.horizontal;
    final columns = math.max(
      1,
      (contentWidth / delegate.maxCrossAxisExtent).ceil(),
    );
    final itemWidth =
        (contentWidth - (columns - 1) * delegate.crossAxisSpacing) / columns;
    final itemHeight = itemWidth / delegate.childAspectRatio;
    final row = index ~/ columns;
    return padding.top + row * (itemHeight + delegate.mainAxisSpacing);
  }

  void _scrollToGridIndex(int index) {
    if (!_scrollController.hasClients) return;
    final target = _estimateRevealOffset(index);
    final clamped = target.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _confirmCursorPick() async {
    final pickedId = _pickedComicId;
    if (pickedId == null || pickedId.isEmpty) {
      showWarningToast(t.searchResult.cursorPickNone);
      return;
    }
    final states = searchEvent.searchStates;
    final keyword = states.searchKeyword.trim();
    final pluginId = states.from.trim();
    final support = searchCursorPlugins[pluginId];
    if (support == null ||
        states.sortBy != support.newestSortBy ||
        keyword.isEmpty ||
        pluginId.isEmpty) {
      showWarningToast(t.searchResult.cursorOnlyNewestSort);
      return;
    }
    if (!isPlainKeywordExtern(states.pluginExtern)) {
      showWarningToast(t.searchResult.cursorPlainKeywordOnly);
      return;
    }
    final comics = context.read<SearchBloc>().state.comics;
    if (comics.isEmpty) {
      showWarningToast(t.searchResult.cursorPickNoResult);
      return;
    }
    ComicNumber? picked;
    for (final comic in comics) {
      if (comic.comic.id == pickedId) {
        picked = comic;
        break;
      }
    }
    if (picked == null) {
      logger.w(
        'cursor pick: comic not found in bloc state, id=$pickedId, count=${comics.length}',
      );
      showWarningToast(t.searchResult.cursorPickNoResult);
      return;
    }
    final record = SearchCursorRecord(
      pluginId: pluginId,
      keyword: keyword,
      sortBy: states.sortBy,
      anchorComicId: pickedId,
      anchorTitle: picked.comic.title,
      // 排序键随插件不同（JM: update_at Unix 秒；Bika: updated_at ISO）。
      anchorUpdateAt: support.sortKeyOf(picked.comic.raw),
      anchorPage: picked.buildNumber,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      extern: Map<String, dynamic>.from(states.pluginExtern),
    );
    await _cursorStore.saveRecord(record);
    if (!mounted) return;
    _exitCursorPick();
    showSuccessToast(t.searchResult.cursorAdded);
  }

  Future<void> _jumpToCursor(SearchCursorRecord record) async {
    if (_cursorPickMode) _exitCursorPick();
    setState(() => _highlightComicId = null);
    final result = await locateCursorWithProgress(context, record);
    if (result == null || !mounted) return;
    if (result.found) {
      _pendingRevealAnchorId = record.anchorComicId;
    }
    final searchCubit = context.read<SearchCubit>();
    final newStates = searchCubit.state.copyWith(
      from: record.pluginId,
      searchKeyword: record.keyword,
      sortBy: record.sortBy,
      // 复现记录游标时的完整 extern（含 Bika 分类筛选等）。
      pluginExtern: Map<String, dynamic>.from(record.extern),
    );
    searchCubit.update(newStates);
    context.read<SearchBloc>().add(
      SearchEvent().copyWith(
        searchStates: newStates,
        page: result.page,
        status: SearchStatus.initial,
      ),
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
