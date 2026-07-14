import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/page/comic_read/cubit/image_size_cubit.dart';
import 'package:zephyr/page/comic_read/cubit/reader_seamless_state.dart';
import 'package:zephyr/page/comic_read/method/get_local_info.dart';
import 'package:zephyr/page/comic_read/method/get_plugin_read_snapshot.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/page/comic_read/model/seamless_transition_state.dart';
import 'package:zephyr/page/comic_read/widgets/layout/read_layout.dart';
import 'package:zephyr/page/comic_read/widgets/modes/read_mode_utils.dart';
import 'package:zephyr/page/download/adapters/download_chapter_adapter.dart';
import 'package:zephyr/page/download/adapters/download_chapter_matcher.dart';
import 'package:zephyr/type/enum.dart';

/// 边界解析动作的结果。
///
/// [didLoad] 表示是否实际加载了章节；[targetGlobalSlot] 表示加载后需要跳转到的
/// 全局槽位（prepend 场景下需要把当前视觉位置平移），为 null 时无需跳转。
/// [prependedSlotCount] 仅在 prepend 场景下非 0，供 UI 层同步修正滚动偏移。
class SeamlessBoundaryResult {
  const SeamlessBoundaryResult({
    this.didLoad = false,
    this.targetGlobalSlot,
    this.prependedSlotCount = 0,
  });

  final bool didLoad;
  final int? targetGlobalSlot;
  final int prependedSlotCount;
}

/// 管理竖向半无缝章节拼接的状态与逻辑。
///
/// 职责：
/// - 维护已加载章节列表、过渡卡片状态、前后章预加载。
/// - 提供列/行模式条目构建、总槽位计算、全局/本地槽位映射。
/// - 在滚动到边界或点击过渡卡片时触发章节加载。
///
/// 注意：该类不直接操作 [ReaderCubit]；UI 层负责把 Cubit 的输出同步到阅读器状态。
class ReaderSeamlessCubit extends Cubit<ReaderSeamlessState> {
  ReaderSeamlessCubit({
    required String comicId,
    required String from,
    required ComicEntryType type,
    required dynamic comicInfo,
    required int initialOrder,
  }) : _comicId = comicId,
       _from = from,
       _type = type,
       _comicInfo = comicInfo,
       _initialOrder = initialOrder,
       super(const ReaderSeamlessState()) {
    _initChapterCatalog();
  }

  final String _comicId;
  final String _from;
  final ComicEntryType _type;
  final dynamic _comicInfo;
  final int _initialOrder;

  static const int _nextPrefetchThreshold = 2;
  static const int _nextAutoResolveThreshold = 1;

  List<UnifiedComicChapterRef> _chapterRefs = <UnifiedComicChapterRef>[];
  Map<int, int> _chapterOrderToCatalogIndex = <int, int>{};

  bool get _isDownloadEntryType =>
      _type == ComicEntryType.download ||
      _type == ComicEntryType.historyAndDownload;

  // ==================== 生命周期 / 初始化 ====================

  void _initChapterCatalog() {
    _chapterRefs = resolveUnifiedComicChapters(_comicInfo, _from);
    _chapterOrderToCatalogIndex = <int, int>{};
    for (var i = 0; i < _chapterRefs.length; i++) {
      _chapterOrderToCatalogIndex[_chapterRefs[i].order] = i;
    }
  }

  /// 初始章节加载成功后调用，把初始章节加入已加载队列。
  void bootstrap(
    NormalComicEpInfo initialEpInfo,
    int initialOrder,
    ReadSettingState readSetting,
  ) {
    if (state.loadedChapters.isNotEmpty) return;
    _addLoadedChapter(order: initialOrder, epInfo: initialEpInfo);
    _ensureEdgeTransitionsVisible(notify: false);
    final contextByOrder = _resolveImageSlotContextByChapterOrder(
      chapterOrder: initialOrder,
      readSetting: readSetting,
    );
    emit(
      state.copyWith(
        currentChapterOrder: initialOrder,
        currentChapterStartSlot: contextByOrder?.chapterStartSlot ?? 0,
        currentChapterSlotCount:
            contextByOrder?.chapterImageCount ??
            getReadModeSlotCount(
              imageCount: initialEpInfo.length,
              enableDoublePage: readSetting.doublePageMode,
              insertLeadingBlank: _insertLeadingBlank(readSetting),
            ),
      ),
    );
  }

  // ==================== 公共查询接口 ====================

  bool isSeamlessEnabled() => _catalogChapters().length > 1;

  bool canLoadPreviousChapter() {
    final chapters = _catalogChapters();
    if (chapters.isEmpty || state.loadedChapters.isEmpty) return false;
    final index = _catalogIndexByOrder(state.loadedChapters.first.order);
    return index > 0;
  }

  bool canLoadNextChapter() {
    final chapters = _catalogChapters();
    if (chapters.isEmpty || state.loadedChapters.isEmpty) return false;
    final index = _catalogIndexByOrder(state.loadedChapters.last.order);
    if (index < 0) return false;
    return index < chapters.length - 1;
  }

  int? get currentChapterOrder => state.currentChapterOrder;

  int get currentChapterStartSlot => state.currentChapterStartSlot;

  int get currentChapterSlotCount => state.currentChapterSlotCount;

  UnifiedComicChapterRef? chapterRefByOrder(int order) {
    final chapters = _catalogChapters();
    final index = _catalogIndexByOrder(order);
    if (index < 0 || index >= chapters.length) return null;
    return chapters[index];
  }

  int catalogIndexByOrder(int order) => _catalogIndexByOrder(order);

  int get catalogLength => _catalogChapters().length;

  String chapterTitleByOrder(int order) {
    final loaded = state.loadedChapters.where(
      (chapter) => chapter.order == order,
    );
    if (loaded.isNotEmpty) {
      final title = loaded.first.epInfo.epName.trim();
      if (title.isNotEmpty) return title;
    }
    final chapters = _catalogChapters();
    final index = _catalogIndexByOrder(order);
    if (index >= 0 && index < chapters.length) {
      final name = chapters[index].name.trim();
      if (name.isNotEmpty) return name;
    }
    return t.reader.chapterOrder(order: order);
  }

  // ==================== 条目构建与槽位计算 ====================

  List<ReadModeEntry> buildColumnEntries(ReadSettingState readSetting) {
    if (!isSeamlessEnabled() || state.loadedChapters.isEmpty) {
      final epInfo = state.loadedChapters.isNotEmpty
          ? state.loadedChapters.first.epInfo
          : NormalComicEpInfo();
      return List<ReadModeEntry>.generate(epInfo.docs.length, (index) {
        final doc = epInfo.docs[index];
        return ReadModeEntry.image(
          doc: doc,
          chapterId: epInfo.epId,
          chapterOrder: _initialOrder,
          chapterTitle: epInfo.epName,
          chapterPageIndex: index,
        );
      }, growable: false);
    }

    final entries = <ReadModeEntry>[];
    for (var i = 0; i < state.loadedChapters.length; i++) {
      final chapter = state.loadedChapters[i];
      final chapterOrder = chapter.order;

      if (_shouldShowTransition(nextOrder: chapterOrder)) {
        final previousOrder = _previousOrderOf(chapterOrder);
        if (previousOrder != null) {
          entries.add(
            ReadModeEntry.transition(
              chapterOrder: chapterOrder,
              chapterTitle: chapterTitleByOrder(chapterOrder),
              previousChapterOrder: previousOrder,
              previousChapterTitle: chapterTitleByOrder(previousOrder),
              transitionStatus: _transitionStatusByNextOrderValue(chapterOrder),
            ),
          );
        }
      }

      for (
        var pageIndex = 0;
        pageIndex < chapter.epInfo.docs.length;
        pageIndex++
      ) {
        final doc = chapter.epInfo.docs[pageIndex];
        entries.add(
          ReadModeEntry.image(
            doc: doc,
            chapterId: chapter.epInfo.epId,
            chapterOrder: chapter.order,
            chapterTitle: chapter.epInfo.epName,
            chapterPageIndex: pageIndex,
          ),
        );
      }
    }

    final endBoundaryNextOrder = _nextOrderOf(state.loadedChapters.last.order);
    if (endBoundaryNextOrder != null &&
        _shouldShowTransition(nextOrder: endBoundaryNextOrder)) {
      final previousOrder = _previousOrderOf(endBoundaryNextOrder);
      if (previousOrder != null) {
        entries.add(
          ReadModeEntry.transition(
            chapterOrder: endBoundaryNextOrder,
            chapterTitle: chapterTitleByOrder(endBoundaryNextOrder),
            previousChapterOrder: previousOrder,
            previousChapterTitle: chapterTitleByOrder(previousOrder),
            transitionStatus: _transitionStatusByNextOrderValue(
              endBoundaryNextOrder,
            ),
          ),
        );
      }
    }

    return entries;
  }

  /// 估算列模式下目标全局槽位对应的滚动偏移（不含 paddingTop 与微调值）。
  ///
  /// 用于在历史恢复、滑动条跳转等场景中先做粗略同步偏移，
  /// 再由 observerController.jumpTo 做精确修正，减弱视觉跳变。
  double estimateColumnHeightBeforeGlobalSlot(
    int targetGlobalSlot,
    ReadSettingState readSetting,
    ImageSizeCubit imageSizeCubit,
    double contentWidth,
  ) {
    if (targetGlobalSlot <= 0) return 0.0;

    final entries = buildColumnEntries(readSetting);
    if (entries.isEmpty) return 0.0;

    final slotEntries = _resolveDisplaySlotEntries(
      targetSlot: targetGlobalSlot,
      entryCount: entries.length,
      enableDoublePage: readSetting.doublePageMode,
      insertLeadingBlank: _insertLeadingBlank(readSetting),
      isTransitionAt: (entryIndex) =>
          entries[entryIndex].type == ReadModeEntryType.transition,
    );
    if (slotEntries == null) return 0.0;

    final targetEntryIndex = slotEntries.$1;
    if (targetEntryIndex <= 0) return 0.0;

    var totalHeight = 0.0;
    for (var i = 0; i < targetEntryIndex; i++) {
      final entry = entries[i];
      if (entry.type == ReadModeEntryType.transition) {
        totalHeight += contentWidth;
        continue;
      }

      final localPageIndex = entry.chapterPageIndex ?? 0;
      final cacheIndex = resolveStableSizeCacheIndex(
        chapterOrder: entry.chapterOrder,
        localPageIndex: localPageIndex,
      );
      final size = imageSizeCubit.state.getSizeValue(cacheIndex);

      if (size.width > 0 && size.height > 0) {
        totalHeight += size.height * (contentWidth / size.width);
      } else {
        totalHeight += imageSizeCubit.state.defaultHeight;
      }
    }
    return totalHeight;
  }

  List<ReadModeEntry> buildRowEntries(ReadSettingState readSetting) {
    if (!isSeamlessEnabled() || state.loadedChapters.isEmpty) {
      final epInfo = state.loadedChapters.isNotEmpty
          ? state.loadedChapters.first.epInfo
          : NormalComicEpInfo();
      return List<ReadModeEntry>.generate(epInfo.docs.length, (index) {
        final doc = epInfo.docs[index];
        return ReadModeEntry.image(
          doc: doc,
          chapterId: epInfo.epId,
          chapterOrder: _initialOrder,
          chapterTitle: epInfo.epName,
          chapterPageIndex: index,
        );
      }, growable: false);
    }

    final entries = <ReadModeEntry>[];
    for (var i = 0; i < state.loadedChapters.length; i++) {
      final chapter = state.loadedChapters[i];
      final chapterOrder = chapter.order;
      if (_shouldShowTransition(nextOrder: chapterOrder)) {
        final previousOrder = _previousOrderOf(chapterOrder);
        if (previousOrder != null) {
          entries.add(
            ReadModeEntry.transition(
              chapterOrder: chapterOrder,
              chapterTitle: chapterTitleByOrder(chapterOrder),
              previousChapterOrder: previousOrder,
              previousChapterTitle: chapterTitleByOrder(previousOrder),
              transitionStatus: _transitionStatusByNextOrderValue(chapterOrder),
            ),
          );
        }
      }
      for (
        var pageIndex = 0;
        pageIndex < chapter.epInfo.docs.length;
        pageIndex++
      ) {
        final doc = chapter.epInfo.docs[pageIndex];
        entries.add(
          ReadModeEntry.image(
            doc: doc,
            chapterId: chapter.epInfo.epId,
            chapterOrder: chapter.order,
            chapterTitle: chapter.epInfo.epName,
            chapterPageIndex: pageIndex,
          ),
        );
      }
    }

    final endBoundaryNextOrder = _nextOrderOf(state.loadedChapters.last.order);
    if (endBoundaryNextOrder != null &&
        _shouldShowTransition(nextOrder: endBoundaryNextOrder)) {
      final previousOrder = _previousOrderOf(endBoundaryNextOrder);
      if (previousOrder != null) {
        entries.add(
          ReadModeEntry.transition(
            chapterOrder: endBoundaryNextOrder,
            chapterTitle: chapterTitleByOrder(endBoundaryNextOrder),
            previousChapterOrder: previousOrder,
            previousChapterTitle: chapterTitleByOrder(previousOrder),
            transitionStatus: _transitionStatusByNextOrderValue(
              endBoundaryNextOrder,
            ),
          ),
        );
      }
    }

    return entries;
  }

  int resolveTotalSlots(ReadSettingState readSetting) {
    final fallback = state.loadedChapters.isNotEmpty
        ? state.loadedChapters.first.epInfo.length
        : 0;

    if (!isSeamlessEnabled() || state.loadedChapters.isEmpty) {
      return getReadModeSlotCount(
        imageCount: fallback,
        enableDoublePage: readSetting.doublePageMode,
        insertLeadingBlank: _insertLeadingBlank(readSetting),
      );
    }

    if (isColumnReadMode(readSetting.readMode)) {
      final entries = buildColumnEntries(readSetting);
      return _resolveDisplaySlotCount(
        entryCount: entries.length,
        enableDoublePage: readSetting.doublePageMode,
        insertLeadingBlank: _insertLeadingBlank(readSetting),
        isTransitionAt: (entryIndex) =>
            entries[entryIndex].type == ReadModeEntryType.transition,
      );
    }
    final entries = buildRowEntries(readSetting);
    return _resolveDisplaySlotCount(
      entryCount: entries.length,
      enableDoublePage: readSetting.doublePageMode,
      insertLeadingBlank: _insertLeadingBlank(readSetting),
      isTransitionAt: (entryIndex) =>
          entries[entryIndex].type == ReadModeEntryType.transition,
    );
  }

  // ==================== 槽位映射 ====================

  int mapGlobalToLocalSlot(int globalIndex) {
    final local = globalIndex - state.currentChapterStartSlot;
    final maxLocal = effectiveCurrentChapterSlotCount() - 1;
    return local.clamp(0, maxLocal);
  }

  int mapLocalToGlobalSlot(int localIndex) {
    final maxLocal = effectiveCurrentChapterSlotCount() - 1;
    final clampedLocal = localIndex.clamp(0, maxLocal);
    return state.currentChapterStartSlot + clampedLocal;
  }

  int effectiveCurrentChapterSlotCount() {
    if (state.currentChapterSlotCount > 0) return state.currentChapterSlotCount;
    return 1;
  }

  bool isTransitionSlot(int globalSlot, ReadSettingState readSetting) {
    if (!isSeamlessEnabled() || state.loadedChapters.isEmpty) return false;
    if (globalSlot < 0) return false;

    if (isColumnReadMode(readSetting.readMode)) {
      final entries = buildColumnEntries(readSetting);
      final slotEntries = _resolveDisplaySlotEntries(
        targetSlot: globalSlot,
        entryCount: entries.length,
        enableDoublePage: readSetting.doublePageMode,
        insertLeadingBlank: _insertLeadingBlank(readSetting),
        isTransitionAt: (entryIndex) =>
            entries[entryIndex].type == ReadModeEntryType.transition,
      );
      if (slotEntries == null) return false;
      return entries[slotEntries.$1].type == ReadModeEntryType.transition;
    }

    final entries = buildRowEntries(readSetting);
    final slotEntries = _resolveDisplaySlotEntries(
      targetSlot: globalSlot,
      entryCount: entries.length,
      enableDoublePage: readSetting.doublePageMode,
      insertLeadingBlank: _insertLeadingBlank(readSetting),
      isTransitionAt: (entryIndex) =>
          entries[entryIndex].type == ReadModeEntryType.transition,
    );
    if (slotEntries == null) return false;
    return entries[slotEntries.$1].type == ReadModeEntryType.transition;
  }

  int? transitionNextOrderByGlobalSlot(
    int globalSlot,
    ReadSettingState readSetting,
  ) {
    if (!isSeamlessEnabled() || state.loadedChapters.isEmpty) return null;
    if (globalSlot < 0) return null;

    if (isColumnReadMode(readSetting.readMode)) {
      final entries = buildColumnEntries(readSetting);
      final slotEntries = _resolveDisplaySlotEntries(
        targetSlot: globalSlot,
        entryCount: entries.length,
        enableDoublePage: readSetting.doublePageMode,
        insertLeadingBlank: _insertLeadingBlank(readSetting),
        isTransitionAt: (entryIndex) =>
            entries[entryIndex].type == ReadModeEntryType.transition,
      );
      if (slotEntries == null) return null;
      final entry = entries[slotEntries.$1];
      if (entry.type != ReadModeEntryType.transition) return null;
      return entry.chapterOrder;
    }

    final entries = buildRowEntries(readSetting);
    final slotEntries = _resolveDisplaySlotEntries(
      targetSlot: globalSlot,
      entryCount: entries.length,
      enableDoublePage: readSetting.doublePageMode,
      insertLeadingBlank: _insertLeadingBlank(readSetting),
      isTransitionAt: (entryIndex) =>
          entries[entryIndex].type == ReadModeEntryType.transition,
    );
    if (slotEntries == null) return null;
    final entry = entries[slotEntries.$1];
    if (entry.type != ReadModeEntryType.transition) return null;
    return entry.chapterOrder;
  }

  // ==================== 历史恢复辅助 ====================

  int resolveHistoryGlobalSlot(
    int baseGlobalSlot,
    ReadSettingState readSetting,
  ) {
    var result = baseGlobalSlot;
    if (_hasLeadingTransition(readSetting)) {
      result += 1;
    }
    return result;
  }

  int resolveEntryDefaultGlobalSlot(ReadSettingState readSetting) {
    return _hasLeadingTransition(readSetting) ? 1 : 0;
  }

  bool _hasLeadingTransition(ReadSettingState readSetting) {
    if (!isSeamlessEnabled() || state.loadedChapters.isEmpty) return false;
    final leadingChapterOrder = state.loadedChapters.first.order;
    return _shouldShowTransition(nextOrder: leadingChapterOrder);
  }

  // ==================== 用户动作入口 ====================

  /// 仅同步"当前章节"映射，不触发边界解析/预加载。
  ///
  /// 用于章节跳转后保持当前章节身份一致，避免额外副作用。
  void applyCurrentChapterByGlobalSlot(
    int globalSlot,
    ReadSettingState readSetting,
  ) {
    _applyCurrentChapterByGlobalSlot(globalSlot, readSetting);
  }

  /// 当前显示的全局槽位发生变化时调用（滚动/翻页）。
  ///
  /// 返回值包含边界解析动作的结果；如果发生了 prepend，调用方需要根据
  /// [SeamlessBoundaryResult.targetGlobalSlot] 重新定位视图。
  Future<SeamlessBoundaryResult> onGlobalSlotObserved(
    int globalSlot,
    ReadSettingState readSetting,
  ) async {
    _applyCurrentChapterByGlobalSlot(globalSlot, readSetting);
    if (state.loadedChapters.isEmpty || isClosed) {
      return const SeamlessBoundaryResult();
    }

    final transitionNextOrder = transitionNextOrderByGlobalSlot(
      globalSlot,
      readSetting,
    );
    if (transitionNextOrder != null) {
      return _ensureBoundaryResolved(
        nextOrder: transitionNextOrder,
        currentGlobalSlot: globalSlot,
        readSetting: readSetting,
      );
    }

    final totalSlots = resolveTotalSlots(readSetting);
    if (totalSlots <= 0) return const SeamlessBoundaryResult();

    final remainToEnd = totalSlots - globalSlot - 1;
    if (remainToEnd <= _nextAutoResolveThreshold && canLoadNextChapter()) {
      final nextOrder = _resolveAdjacentChapterOrder(previous: false);
      if (nextOrder != null) {
        return _ensureBoundaryResolved(
          nextOrder: nextOrder,
          currentGlobalSlot: globalSlot,
          readSetting: readSetting,
        );
      }
    }

    if (remainToEnd <= _nextPrefetchThreshold && canLoadNextChapter()) {
      await _prefetchNextChapterIfNeeded();
    }
    return const SeamlessBoundaryResult();
  }

  /// 用户通过边缘拉取或边界按钮触发前后章加载。
  Future<SeamlessBoundaryResult> triggerBoundary({
    required bool previous,
    required ReadSettingState readSetting,
  }) async {
    if (state.loadedChapters.isEmpty || isClosed) {
      return const SeamlessBoundaryResult();
    }

    if (previous) {
      if (!canLoadPreviousChapter()) {
        return const SeamlessBoundaryResult();
      }
      final nextOrder = state.loadedChapters.first.order;
      final revealed = _revealTransition(nextOrder: nextOrder);
      if (revealed) {
        _setTransitionStatus(nextOrder, SeamlessTransitionStatus.hidden);
        return SeamlessBoundaryResult(
          targetGlobalSlot: state.currentChapterStartSlot + 1,
        );
      }
      return _ensureBoundaryResolved(
        nextOrder: nextOrder,
        currentGlobalSlot: state.currentChapterStartSlot,
        readSetting: readSetting,
      );
    }

    if (!canLoadNextChapter()) {
      return const SeamlessBoundaryResult();
    }
    final nextOrder = _resolveAdjacentChapterOrder(previous: false);
    if (nextOrder == null) return const SeamlessBoundaryResult();
    final revealed = _revealTransition(nextOrder: nextOrder);
    if (revealed) {
      _setTransitionStatus(nextOrder, SeamlessTransitionStatus.hidden);
    }
    final status = _transitionStatusByNextOrderValue(nextOrder);
    if (status == SeamlessTransitionStatus.hidden ||
        status == SeamlessTransitionStatus.error) {
      return _ensureBoundaryResolved(
        nextOrder: nextOrder,
        currentGlobalSlot: state.currentChapterStartSlot,
        readSetting: readSetting,
      );
    } else {
      await _prefetchNextChapterIfNeeded();
      return const SeamlessBoundaryResult();
    }
  }

  /// 用户点击过渡卡片时调用。
  Future<SeamlessBoundaryResult> onTransitionAction(
    int nextOrder,
    ReadSettingState readSetting,
    int currentGlobalSlot,
  ) async {
    _revealTransition(nextOrder: nextOrder);
    return _ensureBoundaryResolved(
      nextOrder: nextOrder,
      currentGlobalSlot: currentGlobalSlot,
      readSetting: readSetting,
    );
  }

  // ==================== 内部：章节加载 ====================

  Future<void> _prefetchNextChapterIfNeeded() async {
    final nextOrder = _resolveAdjacentChapterOrder(previous: false);
    if (nextOrder == null) return;
    await _prefetchChapterByOrderIfNeeded(nextOrder);
  }

  Future<void> _prefetchChapterByOrderIfNeeded(int order) async {
    if (_isOrderLoaded(order)) return;
    if (state.prefetchedChapterInfoByOrder.containsKey(order)) return;
    if (state.prefetchingChapterOrders.contains(order)) return;
    if (state.loadingChapterOrders.contains(order)) return;

    final isVisible = state.visibleTransitionNextOrders.contains(order);
    _addPrefetchingOrder(order);
    if (isVisible) {
      _setTransitionStatus(order, SeamlessTransitionStatus.loading);
    }

    try {
      final chapterInfo = await _readChapterByOrder(order);
      if (isClosed) return;
      if (chapterInfo.length <= 0 || chapterInfo.docs.isEmpty) {
        if (isVisible) {
          _setTransitionStatus(order, SeamlessTransitionStatus.error);
        }
        return;
      }

      _setPrefetchedChapterInfo(order, chapterInfo);
      if (isVisible) {
        _setTransitionStatus(order, SeamlessTransitionStatus.ready);
      }
    } catch (_) {
      if (isVisible) {
        _setTransitionStatus(order, SeamlessTransitionStatus.error);
      }
    } finally {
      _removePrefetchingOrder(order);
    }
  }

  Future<SeamlessBoundaryResult> _ensureBoundaryResolved({
    required int nextOrder,
    required int currentGlobalSlot,
    required ReadSettingState readSetting,
  }) async {
    if (!state.visibleTransitionNextOrders.contains(nextOrder)) {
      _revealTransition(nextOrder: nextOrder);
    }

    final targetOrder = _resolveTargetOrderForBoundary(nextOrder);
    if (targetOrder == null) {
      _setTransitionStatus(nextOrder, SeamlessTransitionStatus.ready);
      return const SeamlessBoundaryResult();
    }
    if (state.loadingChapterOrders.contains(targetOrder)) {
      return const SeamlessBoundaryResult();
    }

    _addLoadingOrder(targetOrder);
    _setTransitionStatus(nextOrder, SeamlessTransitionStatus.loading);

    try {
      final prefetched = state.prefetchedChapterInfoByOrder[targetOrder];
      final chapterInfo = prefetched ?? await _readChapterByOrder(targetOrder);
      if (prefetched != null) {
        _removePrefetchedChapterInfo(targetOrder);
      }
      if (isClosed) {
        return const SeamlessBoundaryResult();
      }
      if (chapterInfo.length <= 0 || chapterInfo.docs.isEmpty) {
        _setTransitionStatus(nextOrder, SeamlessTransitionStatus.error);
        return const SeamlessBoundaryResult();
      }

      final shouldPrepend = _shouldPrependOrder(targetOrder);
      final previousTotalSlots = resolveTotalSlots(readSetting);
      if (!_isOrderLoaded(targetOrder)) {
        _addLoadedChapter(order: targetOrder, epInfo: chapterInfo);
      }

      _ensureEdgeTransitionsVisible();
      _setTransitionStatus(nextOrder, SeamlessTransitionStatus.ready);

      if (shouldPrepend) {
        final latestTotalSlots = resolveTotalSlots(readSetting);
        final shiftBy = (latestTotalSlots - previousTotalSlots).clamp(
          0,
          999999999,
        );
        return SeamlessBoundaryResult(
          didLoad: true,
          targetGlobalSlot: currentGlobalSlot + shiftBy,
          prependedSlotCount: shiftBy,
        );
      }
      return const SeamlessBoundaryResult(didLoad: true);
    } catch (_) {
      _setTransitionStatus(nextOrder, SeamlessTransitionStatus.error);
      return const SeamlessBoundaryResult();
    } finally {
      _removeLoadingOrder(targetOrder);
    }
  }

  Future<NormalComicEpInfo> _readChapterByOrder(int order) async {
    if (_isDownloadEntryType) {
      return getPluginInfoFromLocal(_from, _comicId, order);
    }
    final chapterRefs = resolveUnifiedComicChapters(_comicInfo, _from);
    const adapter = DownloadChapterAdapter();
    const matcher = DownloadChapterMatcher();
    final chapters = chapterRefs.map(adapter.fromChapterRef).toList();
    final chapter =
        matcher.findByOrder(chapters, order) ??
        (chapters.isNotEmpty ? chapters.first : null);
    return getPluginReadSnapshot(
      _comicId,
      order,
      _from,
      _comicInfo,
      chapter?.id,
      chapter?.effectiveRequestId ?? '',
      chapter?.id ?? '',
      Map<String, dynamic>.from(chapter?.extern ?? const <String, dynamic>{}),
    );
  }

  // ==================== 内部：状态更新辅助 ====================

  void _addLoadedChapter({
    required int order,
    required NormalComicEpInfo epInfo,
  }) {
    final updated = List<SeamlessChapter>.from(state.loadedChapters)
      ..add(SeamlessChapter(order: order, epInfo: epInfo));
    _sortLoadedChapters(updated);
    emit(state.copyWith(loadedChapters: updated));
  }

  void _sortLoadedChapters(List<SeamlessChapter> list) {
    list.sort((a, b) {
      final left = _catalogIndexByOrder(a.order);
      final right = _catalogIndexByOrder(b.order);
      if (left == right) return a.order.compareTo(b.order);
      if (left < 0) return 1;
      if (right < 0) return -1;
      return left.compareTo(right);
    });
  }

  void _addLoadingOrder(int order) {
    emit(
      state.copyWith(
        loadingChapterOrders: {...state.loadingChapterOrders, order},
      ),
    );
  }

  void _removeLoadingOrder(int order) {
    emit(
      state.copyWith(
        loadingChapterOrders: state.loadingChapterOrders
            .where((o) => o != order)
            .toSet(),
      ),
    );
  }

  void _addPrefetchingOrder(int order) {
    emit(
      state.copyWith(
        prefetchingChapterOrders: {...state.prefetchingChapterOrders, order},
      ),
    );
  }

  void _removePrefetchingOrder(int order) {
    emit(
      state.copyWith(
        prefetchingChapterOrders: state.prefetchingChapterOrders
            .where((o) => o != order)
            .toSet(),
      ),
    );
  }

  void _setPrefetchedChapterInfo(int order, NormalComicEpInfo info) {
    emit(
      state.copyWith(
        prefetchedChapterInfoByOrder: {
          ...state.prefetchedChapterInfoByOrder,
          order: info,
        },
      ),
    );
  }

  void _removePrefetchedChapterInfo(int order) {
    final updated = {...state.prefetchedChapterInfoByOrder}..remove(order);
    emit(state.copyWith(prefetchedChapterInfoByOrder: updated));
  }

  void _ensureEdgeTransitionsVisible({bool notify = true}) {
    if (state.loadedChapters.isEmpty) return;

    final firstOrder = state.loadedChapters.first.order;
    final lastOrder = state.loadedChapters.last.order;
    final requiredTransitionNextOrders = <int>{};

    if (_previousOrderOf(firstOrder) != null) {
      requiredTransitionNextOrders.add(firstOrder);
    }

    final tailNextOrder = _nextOrderOf(lastOrder);
    if (tailNextOrder != null) {
      requiredTransitionNextOrders.add(tailNextOrder);
    }

    final needUpdate = requiredTransitionNextOrders.any(
      (order) =>
          !state.visibleTransitionNextOrders.contains(order) ||
          !state.transitionStatusByNextOrder.containsKey(order),
    );
    if (!needUpdate) return;

    final updatedVisible = {...state.visibleTransitionNextOrders}
      ..addAll(requiredTransitionNextOrders);
    final updatedStatus = {...state.transitionStatusByNextOrder};
    for (final order in requiredTransitionNextOrders) {
      updatedStatus.putIfAbsent(order, () => SeamlessTransitionStatus.hidden);
    }

    if (notify) {
      emit(
        state.copyWith(
          visibleTransitionNextOrders: updatedVisible,
          transitionStatusByNextOrder: updatedStatus,
        ),
      );
    } else {
      emit(
        state.copyWith(
          visibleTransitionNextOrders: updatedVisible,
          transitionStatusByNextOrder: updatedStatus,
        ),
      );
    }
  }

  void _applyCurrentChapterByGlobalSlot(
    int globalSlot,
    ReadSettingState readSetting,
  ) {
    if (state.loadedChapters.isEmpty) return;

    final slotContext = _resolveImageSlotContextByGlobalSlot(
      globalSlot,
      readSetting,
    );
    if (slotContext == null) return;

    final chapter = state.loadedChapters.firstWhere(
      (item) => item.order == slotContext.chapterOrder,
      orElse: () => state.loadedChapters.last,
    );

    final chapterChanged =
        state.currentChapterOrder != chapter.order ||
        state.currentChapterStartSlot != slotContext.chapterStartSlot ||
        state.currentChapterSlotCount != slotContext.chapterImageCount;
    if (!chapterChanged) return;

    emit(
      state.copyWith(
        currentChapterOrder: chapter.order,
        currentChapterStartSlot: slotContext.chapterStartSlot,
        currentChapterSlotCount: slotContext.chapterImageCount,
      ),
    );
  }

  bool _revealTransition({required int nextOrder}) {
    if (state.visibleTransitionNextOrders.contains(nextOrder)) return false;
    emit(
      state.copyWith(
        visibleTransitionNextOrders: {
          ...state.visibleTransitionNextOrders,
          nextOrder,
        },
      ),
    );
    return true;
  }

  void _setTransitionStatus(int nextOrder, SeamlessTransitionStatus status) {
    if (state.transitionStatusByNextOrder[nextOrder] == status) return;
    emit(
      state.copyWith(
        transitionStatusByNextOrder: {
          ...state.transitionStatusByNextOrder,
          nextOrder: status,
        },
      ),
    );
  }

  SeamlessTransitionStatus _transitionStatusByNextOrderValue(int nextOrder) {
    final previousOrder = _previousOrderOf(nextOrder);
    if (previousOrder == null) {
      return SeamlessTransitionStatus.hidden;
    }
    final bothSidesLoaded =
        _isOrderLoaded(previousOrder) && _isOrderLoaded(nextOrder);
    if (bothSidesLoaded) {
      return SeamlessTransitionStatus.ready;
    }

    final targetOrder = _resolveTargetOrderForBoundary(nextOrder);
    if (targetOrder != null &&
        state.prefetchingChapterOrders.contains(targetOrder)) {
      return SeamlessTransitionStatus.loading;
    }
    if (targetOrder != null &&
        state.prefetchedChapterInfoByOrder.containsKey(targetOrder)) {
      return SeamlessTransitionStatus.ready;
    }

    return state.transitionStatusByNextOrder[nextOrder] ??
        SeamlessTransitionStatus.hidden;
  }

  // ==================== 内部：章节目录与边界判断 ====================

  int? _resolveAdjacentChapterOrder({required bool previous}) {
    final chapters = _catalogChapters();
    if (chapters.isEmpty || state.loadedChapters.isEmpty) return null;
    final anchorOrder = previous
        ? state.loadedChapters.first.order
        : state.loadedChapters.last.order;
    final anchorIndex = _catalogIndexByOrder(anchorOrder);
    if (anchorIndex < 0) return null;

    final targetIndex = previous ? anchorIndex - 1 : anchorIndex + 1;
    if (targetIndex < 0 || targetIndex >= chapters.length) return null;
    return chapters[targetIndex].order;
  }

  int? _resolveTargetOrderForBoundary(int nextOrder) {
    final previousOrder = _previousOrderOf(nextOrder);
    if (previousOrder == null) return null;

    final previousLoaded = _isOrderLoaded(previousOrder);
    final nextLoaded = _isOrderLoaded(nextOrder);

    if (!previousLoaded) return previousOrder;
    if (!nextLoaded) return nextOrder;
    return null;
  }

  bool _shouldPrependOrder(int order) {
    if (state.loadedChapters.isEmpty) return false;
    final firstLoadedIndex = _catalogIndexByOrder(
      state.loadedChapters.first.order,
    );
    final targetIndex = _catalogIndexByOrder(order);
    if (firstLoadedIndex < 0 || targetIndex < 0) return false;
    return targetIndex < firstLoadedIndex;
  }

  bool _shouldShowTransition({required int nextOrder}) {
    if (!state.visibleTransitionNextOrders.contains(nextOrder)) return false;
    final previousOrder = _previousOrderOf(nextOrder);
    return previousOrder != null;
  }

  bool _isOrderLoaded(int order) {
    return state.loadedChapters.any((chapter) => chapter.order == order);
  }

  List<UnifiedComicChapterRef> _catalogChapters() {
    if (_chapterRefs.isNotEmpty) return _chapterRefs;
    return const <UnifiedComicChapterRef>[];
  }

  int _catalogIndexByOrder(int order) {
    final mappedIndex = _chapterOrderToCatalogIndex[order];
    if (mappedIndex != null && mappedIndex >= 0) return mappedIndex;
    final chapters = _catalogChapters();
    return chapters.indexWhere((chapter) => chapter.order == order);
  }

  int? _previousOrderOf(int order) {
    final chapters = _catalogChapters();
    if (chapters.isEmpty) return null;
    final index = _catalogIndexByOrder(order);
    if (index <= 0) return null;
    return chapters[index - 1].order;
  }

  int? _nextOrderOf(int order) {
    final chapters = _catalogChapters();
    if (chapters.isEmpty) return null;
    final index = _catalogIndexByOrder(order);
    if (index < 0 || index >= chapters.length - 1) return null;
    return chapters[index + 1].order;
  }

  // ==================== 内部：槽位解析 ====================

  _ImageSlotContext? _resolveImageSlotContextByGlobalSlot(
    int globalSlot,
    ReadSettingState readSetting,
  ) {
    if (globalSlot < 0) return null;

    final entries = isColumnReadMode(readSetting.readMode)
        ? buildColumnEntries(readSetting)
        : buildRowEntries(readSetting);
    return _resolveImageSlotContextFromEntries(
      globalSlot,
      entries,
      enableDoublePage: readSetting.doublePageMode,
      insertLeadingBlank: _insertLeadingBlank(readSetting),
    );
  }

  _ImageSlotContext? _resolveImageSlotContextByChapterOrder({
    required int chapterOrder,
    required ReadSettingState readSetting,
  }) {
    if (!isSeamlessEnabled() || state.loadedChapters.isEmpty) return null;

    final entries = isColumnReadMode(readSetting.readMode)
        ? buildColumnEntries(readSetting)
        : buildRowEntries(readSetting);
    return _resolveChapterSlotContextFromEntries(
      chapterOrder,
      entries,
      enableDoublePage: readSetting.doublePageMode,
      insertLeadingBlank: _insertLeadingBlank(readSetting),
    );
  }

  bool _insertLeadingBlank(ReadSettingState readSetting) =>
      readSetting.doublePageMode && readSetting.doublePageLeadingBlank;

  int? _chapterOrderOfImageEntry(ReadModeEntry entry) =>
      entry.type == ReadModeEntryType.image ? entry.chapterOrder : null;

  _ImageSlotContext? _resolveImageSlotContextFromEntries(
    int globalSlot,
    List<ReadModeEntry> entries, {
    required bool enableDoublePage,
    required bool insertLeadingBlank,
  }) {
    final slotEntries = _resolveDisplaySlotEntries(
      targetSlot: globalSlot,
      entryCount: entries.length,
      enableDoublePage: enableDoublePage,
      insertLeadingBlank: insertLeadingBlank,
      isTransitionAt: (entryIndex) =>
          entries[entryIndex].type == ReadModeEntryType.transition,
    );
    if (slotEntries == null) return null;
    final current = entries[slotEntries.$1];
    final chapterOrder = _chapterOrderOfImageEntry(current);
    if (chapterOrder == null) return null;

    var chapterStartSlot = -1;
    var chapterSlotCount = 0;
    _forEachDisplaySlot(
      entryCount: entries.length,
      enableDoublePage: enableDoublePage,
      insertLeadingBlank: insertLeadingBlank,
      isTransitionAt: (entryIndex) =>
          entries[entryIndex].type == ReadModeEntryType.transition,
      onSlot: (slotIndex, primaryEntryIndex, secondaryEntryIndex) {
        final order = _chapterOrderOfImageEntry(entries[primaryEntryIndex]);
        if (order == null || order != chapterOrder) return;
        chapterStartSlot = chapterStartSlot < 0 ? slotIndex : chapterStartSlot;
        chapterSlotCount++;
      },
    );
    if (chapterStartSlot < 0 || chapterSlotCount <= 0) return null;
    return _ImageSlotContext(
      chapterOrder: chapterOrder,
      chapterStartSlot: chapterStartSlot,
      chapterImageCount: chapterSlotCount,
    );
  }

  _ImageSlotContext? _resolveChapterSlotContextFromEntries(
    int chapterOrder,
    List<ReadModeEntry> entries, {
    required bool enableDoublePage,
    required bool insertLeadingBlank,
  }) {
    var chapterStartSlot = -1;
    var chapterSlotCount = 0;
    _forEachDisplaySlot(
      entryCount: entries.length,
      enableDoublePage: enableDoublePage,
      insertLeadingBlank: insertLeadingBlank,
      isTransitionAt: (entryIndex) =>
          entries[entryIndex].type == ReadModeEntryType.transition,
      onSlot: (slotIndex, primaryEntryIndex, secondaryEntryIndex) {
        final order = _chapterOrderOfImageEntry(entries[primaryEntryIndex]);
        if (order == null || order != chapterOrder) return;
        chapterStartSlot = chapterStartSlot < 0 ? slotIndex : chapterStartSlot;
        chapterSlotCount++;
      },
    );
    if (chapterStartSlot < 0 || chapterSlotCount <= 0) return null;
    return _ImageSlotContext(
      chapterOrder: chapterOrder,
      chapterStartSlot: chapterStartSlot,
      chapterImageCount: chapterSlotCount,
    );
  }

  int _resolveDisplaySlotCount({
    required int entryCount,
    required bool enableDoublePage,
    required bool insertLeadingBlank,
    required bool Function(int entryIndex) isTransitionAt,
  }) {
    if (entryCount <= 0) return 0;
    var count = 0;
    _forEachDisplaySlot(
      entryCount: entryCount,
      enableDoublePage: enableDoublePage,
      insertLeadingBlank: insertLeadingBlank,
      isTransitionAt: isTransitionAt,
      onSlot: (slotIndex, primaryEntryIndex, secondaryEntryIndex) {
        count = slotIndex + 1;
      },
    );
    return count;
  }

  (int, int?)? _resolveDisplaySlotEntries({
    required int targetSlot,
    required int entryCount,
    required bool enableDoublePage,
    required bool insertLeadingBlank,
    required bool Function(int entryIndex) isTransitionAt,
  }) {
    if (targetSlot < 0 || entryCount <= 0) return null;
    (int, int?)? result;
    _forEachDisplaySlot(
      entryCount: entryCount,
      enableDoublePage: enableDoublePage,
      insertLeadingBlank: insertLeadingBlank,
      isTransitionAt: isTransitionAt,
      onSlot: (slotIndex, primaryEntryIndex, secondaryEntryIndex) {
        if (slotIndex != targetSlot || result != null) return;
        result = (primaryEntryIndex, secondaryEntryIndex);
      },
    );
    return result;
  }

  /// 与 [buildReadModeDoublePageSlots] 保持一致的槽位遍历。
  ///
  /// 首页留白槽位以「该页图片 entry 为 primary、secondary 为 null」表示，
  /// 仅用于槽位计数/章节归属；UI 侧单独渲染左侧空白。
  void _forEachDisplaySlot({
    required int entryCount,
    required bool enableDoublePage,
    required bool insertLeadingBlank,
    required bool Function(int entryIndex) isTransitionAt,
    required void Function(
      int slotIndex,
      int primaryEntryIndex,
      int? secondaryEntryIndex,
    )
    onSlot,
  }) {
    var slotIndex = 0;
    var entryIndex = 0;
    var needLeadingBlank = enableDoublePage && insertLeadingBlank;
    while (entryIndex < entryCount) {
      final primaryEntryIndex = entryIndex;
      if (!enableDoublePage || isTransitionAt(primaryEntryIndex)) {
        onSlot(slotIndex, primaryEntryIndex, null);
        slotIndex++;
        entryIndex++;
        if (enableDoublePage && isTransitionAt(primaryEntryIndex)) {
          needLeadingBlank = insertLeadingBlank;
        }
        continue;
      }

      if (needLeadingBlank) {
        onSlot(slotIndex, primaryEntryIndex, null);
        slotIndex++;
        entryIndex++;
        needLeadingBlank = false;
        continue;
      }

      entryIndex++;
      int? secondaryEntryIndex;
      if (entryIndex < entryCount && !isTransitionAt(entryIndex)) {
        secondaryEntryIndex = entryIndex;
        entryIndex++;
      }
      onSlot(slotIndex, primaryEntryIndex, secondaryEntryIndex);
      slotIndex++;
    }
  }
}

class _ImageSlotContext {
  const _ImageSlotContext({
    required this.chapterOrder,
    required this.chapterStartSlot,
    required this.chapterImageCount,
  });

  final int chapterOrder;
  final int chapterStartSlot;
  final int chapterImageCount;
}
