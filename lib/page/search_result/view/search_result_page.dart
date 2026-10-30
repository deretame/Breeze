import 'dart:convert';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:material_ui/material_ui.dart' hide Thumb;
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/comic_list/view/plugin_comic_grid_sliver.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_bookmark/cubit/search_bookmark_cubit.dart';
import 'package:zephyr/page/search_result/models/models.dart';
import 'package:zephyr/page/search_result/search_result.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_grid.dart';
import 'package:zephyr/widgets/comic_simplify_entry/detail_columns.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_mapper.dart';
import 'package:zephyr/widgets/toast.dart';

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
    with SingleTickerProviderStateMixin, AutoRouteAwareStateMixin {
  late SearchEvent searchEvent;
  final _scrollController = ScrollController();
  bool _bookmarkPickMode = false;
  String? _pickedComicId;
  // 书签跳转落地后待揭示的书签（成功回调里消费一次）。
  SearchBookmark? _pendingRevealBookmark;
  // 邻页找回中：待找书签 + 已向后探测次数 + 是否已试过向前。
  SearchBookmark? _probeBookmark;
  int _probeForwardCount = 0;
  bool _probeTriedBackward = false;
  // 跳转后需要描边高亮的锚点条目。
  String? _highlightComicId;
  // 揭示时滚动空间不足，已触发加载更多，等下一个 success 重试。
  SearchBookmark? _revealRetryBookmark;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  @override
  void initState() {
    super.initState();
    _pendingRevealBookmark = SearchBookmarkReveal.consume();
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

  /// 路由守护：本页被新路由盖住（进详情等）时取消描边；
  /// 返回时不再恢复，用户重跳才会再亮。
  @override
  void didPushNext() {
    super.didPushNext();
    if (_highlightComicId != null && mounted) {
      setState(() => _highlightComicId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // 搜索书签无需插件声明：快照只是搜索参数重放，全插件可用。
    return Scaffold(
      appBar: const SearchResultBar(),
      body: Stack(
        children: [
          Positioned.fill(child: _bloc()),
          if (_bookmarkPickMode)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildBookmarkPickBanner(colorScheme),
            ),
        ],
      ),
      floatingActionButtonLocation:
          context.watch<GlobalSettingCubit>().state.leftHandModeEnabled
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
      floatingActionButton: _bookmarkPickMode
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
                  // 无需插件声明，全插件可用。
                  SpeedDialChild(
                    child: const Icon(Icons.bookmark_add_outlined),
                    label: t.searchResult.bookmarkAdd,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                    onTap: _startBookmarkPick,
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
            final pending = _pendingRevealBookmark;
            if (pending != null) {
              _pendingRevealBookmark = null;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _revealAnchorAfterJump(pending);
              });
            } else if (_probeBookmark != null) {
              // 找回中的后续页：继续在本页找，找不到自动翻下一邻页。
              final probing = _probeBookmark!;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _revealAnchorAfterJump(probing);
              });
            }
            final retry = _revealRetryBookmark;
            if (retry != null) {
              _revealRetryBookmark = null;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _revealAnchorAfterJump(retry);
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
      // 书签揭示只要锚点描边，不压暗其它条目。
      dimOthers: false,
      hasReachedMax:
          (state.hasReachedMax || _bookmarkPickMode) &&
          state.status == SearchStatus.success,
      isLoadingMore: state.status == SearchStatus.loadingMore,
      loadMoreFailed: state.status == SearchStatus.getMoreFailure,
      onRetryLoadMore: () => _refresh(SearchStatus.loadingMore),
      onLoadMore: _fetchSearchResult,
      physics: _bookmarkPickMode ? const NeverScrollableScrollPhysics() : null,
      selectionMode: _bookmarkPickMode,
      isEntrySelected: _bookmarkPickMode
          ? (entry) => entry.id == _pickedComicId
          : null,
      onEntryTap: _bookmarkPickMode
          ? (entry) {
              setState(() => _pickedComicId = entry.id);
            }
          : null,
      detailed: context
          .watch<GlobalSettingCubit>()
          .state
          .bookshelfSetting
          .detailLayout,
    );
  }

  Widget _buildBookmarkPickBanner(ColorScheme colorScheme) {
    return Material(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                t.searchResult.bookmarkPickBanner,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onSecondaryContainer),
              ),
            ),
            TextButton(
              onPressed: _exitBookmarkPick,
              child: Text(t.common.cancel),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _confirmBookmarkPick,
              child: Text(t.common.confirm),
            ),
          ],
        ),
      ),
    );
  }

  void _startBookmarkPick() {
    setState(() {
      _bookmarkPickMode = true;
      _pickedComicId = null;
    });
  }

  void _exitBookmarkPick() {
    setState(() {
      _bookmarkPickMode = false;
      _pickedComicId = null;
    });
  }

  /// 书签跳转落地后：按“页内序号”精确定位到锚点，描边常驻直到切走。
  /// 只动锚点自身的常驻边框层（透明↔主色），不压暗其它条目、不拦截点击。
  /// 本页被新路由盖住时由 didPushNext 清除（路由守护）。
  ///
  /// 三步走：
  /// 1. 粗定：序号→行列，网格可精确算出行，详情算出（列，行）；
  /// 2. 逼建：滚到该行附近，让 sliver 把锚点建出来；
  /// 3. 精定：按 ValueKey(id) 找条目 context，ensureVisible 对齐到顶。
  void _revealAnchorAfterJump(SearchBookmark bookmark) {
    if (!mounted) return;
    final found = _findAnchorLocalIndex(bookmark);
    if (found != null) {
      _probeBookmark = null;
      _revealAt(found.$1, found.$2, bookmark.anchorComicId);
      return;
    }
    // 本页没有：进邻页找回（向后 N 次 → 向前 1 次）。
    // 已在找回中则保持计数（success 回调连击），只在首次进入时重置。
    if (!identical(_probeBookmark, bookmark)) {
      _probeBookmark = bookmark;
      _probeForwardCount = 0;
      _probeTriedBackward = false;
    }
    _probeNextPage();
  }

  /// 全量 comics 里按 id 找锚点，返回（页内序号，同页条目数）。
  /// 落地页即目标页时等价于旧的 anchorPage 过滤；找回翻页后页码会变，
  /// 所以不限定页，只认 id。
  (int, int)? _findAnchorLocalIndex(SearchBookmark bookmark) {
    final comics = context.read<SearchBloc>().state.comics;
    final index = comics.indexWhere(
      (item) => item.comic.id == bookmark.anchorComicId,
    );
    if (index < 0) return null;
    final page = comics[index].buildNumber;
    final pageItems = comics.where((item) => item.buildNumber == page).toList();
    final localIndex = pageItems.indexWhere(
      (item) => item.comic.id == bookmark.anchorComicId,
    );
    if (localIndex < 0) return null;
    return (localIndex, pageItems.length);
  }

  void _revealAt(int localIndex, int pageItemCount, String anchorId) {
    final detailed = context
        .read<GlobalSettingCubit>()
        .state
        .bookshelfSetting
        .detailLayout;
    if (detailed) {
      _revealDetailed(anchorId, localIndex, pageItemCount);
      return;
    }
    _revealGrid(anchorId, localIndex);
  }

  /// 邻页找回下一步：优先向后（nextUrl 链，最多 N 页），再向前 1 次（prevUrl）。
  /// 每次都是独立 initial 搜索（复用跳转标志直抓），成功后回到 success 回调继续找。
  void _probeNextPage() {
    if (!mounted) return;
    final bookmark = _probeBookmark;
    if (bookmark == null) return;
    final maxForward = context
        .read<GlobalSettingCubit>()
        .state
        .searchBookmarkProbePages
        .clamp(0, 10);
    final extern = Map<String, dynamic>.from(
      searchEvent.searchStates.pluginExtern,
    );
    if (_probeForwardCount < maxForward) {
      final nextUrl = (extern['nextUrl']?.toString() ?? '').trim();
      if (nextUrl.isEmpty) {
        _probeForwardCount = maxForward;
      } else {
        _probeForwardCount++;
        _probeFetch(nextUrl);
        return;
      }
    }
    if (!_probeTriedBackward) {
      _probeTriedBackward = true;
      final prevUrl = (extern['prevUrl']?.toString() ?? '').trim();
      if (prevUrl.isNotEmpty) {
        _probeFetch(prevUrl);
        return;
      }
    }
    // 都找完还没有：停在当前页，提示即可。
    _probeBookmark = null;
    showWarningToast(t.searchBookmark.anchorMissing(page: searchEvent.page));
  }

  /// 以指定 URL 为 currentUrl 发一次跳转式独立搜索。
  void _probeFetch(String url) {
    final extern = Map<String, dynamic>.from(
      searchEvent.searchStates.pluginExtern,
    )..['currentUrl'] = url;
    context.read<SearchBloc>().add(
      searchEvent.copyWith(
        status: SearchStatus.initial,
        searchStates: searchEvent.searchStates.copyWith(
          pluginExtern: extern,
          isSearchAggregate: true,
        ),
      ),
    );
  }

  /// 网格揭示：列数精确可算，行 = 序号 ~/ 列数。
  Future<void> _revealGrid(String anchorId, int localIndex) async {
    if (!mounted) return;
    final columns = _gridColumnCount();
    final row = localIndex ~/ columns;
    // 粗定：滚到该行（逼建锚点）。
    await _scrollToGridRow(row);
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    // 精定：按 key 找条目，ensureVisible 对齐到顶。
    final targetContext = _entryContextById(anchorId);
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        // ignore: use_build_context_synchronously
        targetContext,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        alignment: 0,
      );
    }
    if (!mounted) return;
    setState(() => _highlightComicId = anchorId);
  }

  /// 详情布局揭示：笨办法——把锚点前面所有行的高度全算出来累加，
  /// 一次滚到位，再 ensureVisible 微调对齐到顶。
  /// 列宽/文字宽度/样式与 build 期同快照，TextPainter 实测行高。
  Future<void> _revealDetailed(
    String anchorId,
    int localIndex,
    int pageItemCount,
  ) async {
    if (!_scrollController.hasClients) return;
    final comics = context.read<SearchBloc>().state.comics;
    final pageItems = comics
        .where((item) => item.buildNumber == searchEvent.page)
        .toList();
    final entries = mapToUnifiedComicSimplifyEntryInfoList(
      pageItems.map((item) => item.comic),
    );
    // 与 BaseComicGridSliver 同快照：内容宽→列数→列宽→文字宽。
    const padding = EdgeInsets.all(10);
    final contentWidth = MediaQuery.sizeOf(context).width - padding.horizontal;
    final columns = detailColumnCount(contentWidth);
    final columnWidth = columns <= 1
        ? contentWidth
        : (contentWidth - (columns - 1) * 10) / columns;
    final textWidth = columnWidth - 114 - 10 - 12;
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.3,
    );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(height: 1.4);
    // 锚点所在列、列内第几行：index = row * columns + column。
    final column = localIndex % columns;
    final targetRow = localIndex ~/ columns;
    // 累加同列前面所有行的高度 + 行间距。
    var offset = padding.top;
    for (var row = 0; row < targetRow; row++) {
      final index = row * columns + column;
      if (index >= entries.length) break;
      offset +=
          detailRowHeight(
            entries[index],
            textWidth,
            titleStyle: titleStyle ?? const TextStyle(fontSize: 14),
            subtitleStyle: subtitleStyle ?? const TextStyle(fontSize: 12),
          ) +
          kDetailRowSpacing;
    }
    final clamped = offset
        .clamp(0.0, _scrollController.position.maxScrollExtent)
        .toDouble();
    await _scrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    // 微调：按 key 找条目，ensureVisible 对齐到顶（消除累计误差）。
    final targetContext = _entryContextById(anchorId);
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        // ignore: use_build_context_synchronously
        targetContext,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        alignment: 0,
      );
    }
    if (!mounted) return;
    setState(() => _highlightComicId = anchorId);
  }

  /// 网格列数：与 BaseComicGridSliver 同算法（视口宽快照）。
  int _gridColumnCount() {
    final delegate = buildComicSimplifyEntryGridDelegate();
    if (delegate is! SliverGridDelegateWithMaxCrossAxisExtent) return 1;
    const padding = EdgeInsets.all(10);
    final contentWidth = MediaQuery.sizeOf(context).width - padding.horizontal;
    return math.max(1, (contentWidth / delegate.maxCrossAxisExtent).ceil());
  }

  /// 网格按行滚：行高精确可算（itemWidth / aspectRatio）。
  Future<void> _scrollToGridRow(int row) async {
    if (!_scrollController.hasClients) return;
    final delegate = buildComicSimplifyEntryGridDelegate();
    if (delegate is! SliverGridDelegateWithMaxCrossAxisExtent) return;
    const padding = EdgeInsets.all(10);
    final contentWidth = MediaQuery.sizeOf(context).width - padding.horizontal;
    final columns = math.max(
      1,
      (contentWidth / delegate.maxCrossAxisExtent).ceil(),
    );
    final itemWidth =
        (contentWidth - (columns - 1) * delegate.crossAxisSpacing) / columns;
    final itemHeight = itemWidth / delegate.childAspectRatio;
    final target = padding.top + row * (itemHeight + delegate.mainAxisSpacing);
    final clamped = target.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    await _scrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  // 旧估算链（_ensureRevealScrollRoom/_estimateRevealOffset/_scrollToGridIndex）
  // 已被序号三步走（_revealGrid/_revealDetailed）取代，删。
  /// 按条目 id 找已 layout 的条目 context（未建返回 null）。
  BuildContext? _entryContextById(String id) {
    BuildContext? found;
    void visitor(Element element) {
      if (found != null) return;
      final key = element.widget.key;
      if (key is ValueKey && key.value == id) {
        found = element;
        return;
      }
      element.visitChildren(visitor);
    }

    context.visitChildElements(visitor);
    return found;
  }

  Future<void> _confirmBookmarkPick() async {
    final pickedId = _pickedComicId;
    if (pickedId == null || pickedId.isEmpty) {
      showWarningToast(t.searchResult.bookmarkPickNone);
      return;
    }
    final states = searchEvent.searchStates;
    final keyword = states.searchKeyword.trim();
    final pluginId = states.from.trim();
    if (keyword.isEmpty || pluginId.isEmpty) {
      showWarningToast(t.searchResult.bookmarkPickNoResult);
      return;
    }
    final comics = context.read<SearchBloc>().state.comics;
    if (comics.isEmpty) {
      showWarningToast(t.searchResult.bookmarkPickNoResult);
      return;
    }
    ComicNumber? picked;
    var pickedIndex = -1;
    for (var i = 0; i < comics.length; i++) {
      if (comics[i].comic.id == pickedId) {
        picked = comics[i];
        pickedIndex = i;
        break;
      }
    }
    if (picked == null || pickedIndex < 0) {
      showWarningToast(t.searchResult.bookmarkPickNoResult);
      return;
    }
    // 页内序号：同 buildNumber（页码）的第一条即本页起始。
    var pageStart = pickedIndex;
    while (pageStart > 0 &&
        comics[pageStart - 1].buildNumber == picked.buildNumber) {
      pageStart--;
    }
    await SearchBookmarkCubit().add(
      source: pluginId,
      keyword: keyword,
      extern: Map<String, dynamic>.from(states.pluginExtern),
      anchorComicId: pickedId,
      anchorTitle: picked.comic.title,
      anchorCover: jsonEncode(picked.comic.cover.toJson()),
      anchorPage: picked.buildNumber,
      anchorIndex: pickedIndex - pageStart,
    );
    if (!mounted) return;
    _exitBookmarkPick();
    showSuccessToast(t.searchResult.bookmarkAdded);
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
