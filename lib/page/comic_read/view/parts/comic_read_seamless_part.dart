part of '../comic_read.dart';

class _LoadedChapterData {
  const _LoadedChapterData({required this.order, required this.epInfo});

  final int order;
  final NormalComicEpInfo epInfo;
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

extension _ComicReadSeamlessPart on _ComicReadPageState {
  static const int _nextPrefetchThreshold = 2;
  static const int _nextAutoResolveThreshold = 1;

  bool get _isDownloadEntryType =>
      _type == ComicEntryType.download ||
      _type == ComicEntryType.historyAndDownload;

  void _initChapterCatalog() {
    _chapterRefs = resolveUnifiedComicChapters(comicInfo, widget.from);
    _chapterOrderToCatalogIndex = <int, int>{};
    for (var i = 0; i < _chapterRefs.length; i++) {
      _chapterOrderToCatalogIndex[_chapterRefs[i].order] = i;
    }
  }

  bool _isSeamlessEnabled(ReadSettingState readSetting) {
    final chapterCount = _catalogChapters().length;
    return chapterCount > 1;
  }

  void _bootstrapInitialChapterFeed(NormalComicEpInfo initialEpInfo) {
    if (_loadedChapters.isNotEmpty) return;
    _loadedChapters.add(
      _LoadedChapterData(order: widget.order, epInfo: initialEpInfo),
    );
    _sortLoadedChaptersByCatalog();
    _ensureEdgeTransitionsVisible(notify: false);
    final readSetting = context.read<GlobalSettingCubit>().state.readSetting;
    final contextByOrder = _resolveImageSlotContextByChapterOrder(
      chapterOrder: widget.order,
      readSetting: readSetting,
    );
    _currentChapterStartSlot = contextByOrder?.chapterStartSlot ?? 0;
    _currentChapterSlotCount =
        contextByOrder?.chapterImageCount ??
        getReadModeSlotCount(
          imageCount: initialEpInfo.length,
          enableDoublePage: readSetting.doublePageMode,
        );
    _syncJumpChapterState(order: widget.order);
  }

  void _ensureEdgeTransitionsVisible({bool notify = true}) {
    if (_loadedChapters.isEmpty) return;

    final firstOrder = _loadedChapters.first.order;
    final lastOrder = _loadedChapters.last.order;
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
          !_visibleTransitionNextOrders.contains(order) ||
          !_transitionStatusByNextOrder.containsKey(order),
    );
    if (!needUpdate) return;

    void applyChanges() {
      for (final order in requiredTransitionNextOrders) {
        _visibleTransitionNextOrders.add(order);
        _transitionStatusByNextOrder.putIfAbsent(
          order,
          () => SeamlessTransitionStatus.hidden,
        );
      }
    }

    if (!notify) {
      applyChanges();
      return;
    }

    _refreshState(applyChanges);
  }

  int _resolveTotalSlots(ReadSettingState readSetting) {
    if (!_isSeamlessEnabled(readSetting)) {
      return getReadModeSlotCount(
        imageCount: epInfo.length,
        enableDoublePage: readSetting.doublePageMode,
      );
    }

    if (_loadedChapters.isEmpty) {
      return getReadModeSlotCount(
        imageCount: epInfo.length,
        enableDoublePage: readSetting.doublePageMode,
      );
    }

    if (isColumnReadMode(readSetting.readMode)) {
      final entries = _buildColumnEntries(readSetting: readSetting);
      return _resolveDisplaySlotCount(
        entryCount: entries.length,
        enableDoublePage: readSetting.doublePageMode,
        isTransitionAt: (entryIndex) =>
            entries[entryIndex].type == ColumnModeEntryType.transition,
      );
    }
    final entries = _buildRowEntries(readSetting: readSetting);
    return _resolveDisplaySlotCount(
      entryCount: entries.length,
      enableDoublePage: readSetting.doublePageMode,
      isTransitionAt: (entryIndex) =>
          entries[entryIndex].type == RowModeEntryType.transition,
    );
  }

  List<ColumnModeEntry> _buildColumnEntries({
    required ReadSettingState readSetting,
  }) {
    if (!_isSeamlessEnabled(readSetting) || _loadedChapters.isEmpty) {
      return List<ColumnModeEntry>.generate(epInfo.docs.length, (index) {
        final doc = epInfo.docs[index];
        return ColumnModeEntry.image(
          doc: doc,
          chapterId: epInfo.epId,
          chapterOrder: widget.order,
          chapterTitle: epInfo.epName,
          chapterLocalPageIndex: index,
          chapterTotalPages: epInfo.length,
        );
      }, growable: false);
    }

    final entries = <ColumnModeEntry>[];
    for (
      var chapterIndex = 0;
      chapterIndex < _loadedChapters.length;
      chapterIndex++
    ) {
      final chapter = _loadedChapters[chapterIndex];
      final chapterOrder = chapter.order;

      if (_shouldShowTransition(nextOrder: chapterOrder)) {
        final previousOrder = _previousOrderOf(chapterOrder);
        if (previousOrder != null) {
          entries.add(
            ColumnModeEntry.transition(
              chapterOrder: chapterOrder,
              chapterTitle: _chapterTitleByOrder(chapterOrder),
              previousChapterOrder: previousOrder,
              previousChapterTitle: _chapterTitleByOrder(previousOrder),
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
          ColumnModeEntry.image(
            doc: doc,
            chapterId: chapter.epInfo.epId,
            chapterOrder: chapter.order,
            chapterTitle: chapter.epInfo.epName,
            chapterLocalPageIndex: pageIndex,
            chapterTotalPages: chapter.epInfo.length,
          ),
        );
      }
    }

    final endBoundaryNextOrder = _nextOrderOf(_loadedChapters.last.order);
    if (endBoundaryNextOrder != null &&
        _shouldShowTransition(nextOrder: endBoundaryNextOrder)) {
      final previousOrder = _previousOrderOf(endBoundaryNextOrder);
      if (previousOrder != null) {
        entries.add(
          ColumnModeEntry.transition(
            chapterOrder: endBoundaryNextOrder,
            chapterTitle: _chapterTitleByOrder(endBoundaryNextOrder),
            previousChapterOrder: previousOrder,
            previousChapterTitle: _chapterTitleByOrder(previousOrder),
            transitionStatus: _transitionStatusByNextOrderValue(
              endBoundaryNextOrder,
            ),
          ),
        );
      }
    }

    return entries;
  }

  List<RowModeEntry> _buildRowEntries({required ReadSettingState readSetting}) {
    if (!_isSeamlessEnabled(readSetting) || _loadedChapters.isEmpty) {
      return List<RowModeEntry>.generate(epInfo.docs.length, (index) {
        final doc = epInfo.docs[index];
        return RowModeEntry.image(
          doc: doc,
          chapterId: epInfo.epId,
          chapterOrder: widget.order,
          chapterTitle: epInfo.epName,
          chapterLocalPageIndex: index,
        );
      }, growable: false);
    }

    final entries = <RowModeEntry>[];
    for (
      var chapterIndex = 0;
      chapterIndex < _loadedChapters.length;
      chapterIndex++
    ) {
      final chapter = _loadedChapters[chapterIndex];
      final chapterOrder = chapter.order;
      if (_shouldShowTransition(nextOrder: chapterOrder)) {
        final previousOrder = _previousOrderOf(chapterOrder);
        if (previousOrder != null) {
          entries.add(
            RowModeEntry.transition(
              chapterOrder: chapterOrder,
              chapterTitle: _chapterTitleByOrder(chapterOrder),
              previousChapterOrder: previousOrder,
              previousChapterTitle: _chapterTitleByOrder(previousOrder),
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
          RowModeEntry.image(
            doc: doc,
            chapterId: chapter.epInfo.epId,
            chapterOrder: chapter.order,
            chapterTitle: chapter.epInfo.epName,
            chapterLocalPageIndex: pageIndex,
          ),
        );
      }
    }

    final endBoundaryNextOrder = _nextOrderOf(_loadedChapters.last.order);
    if (endBoundaryNextOrder != null &&
        _shouldShowTransition(nextOrder: endBoundaryNextOrder)) {
      final previousOrder = _previousOrderOf(endBoundaryNextOrder);
      if (previousOrder != null) {
        entries.add(
          RowModeEntry.transition(
            chapterOrder: endBoundaryNextOrder,
            chapterTitle: _chapterTitleByOrder(endBoundaryNextOrder),
            previousChapterOrder: previousOrder,
            previousChapterTitle: _chapterTitleByOrder(previousOrder),
            transitionStatus: _transitionStatusByNextOrderValue(
              endBoundaryNextOrder,
            ),
          ),
        );
      }
    }

    return entries;
  }

  int _resolveDisplaySlotCount({
    required int entryCount,
    required bool enableDoublePage,
    required bool Function(int entryIndex) isTransitionAt,
  }) {
    if (entryCount <= 0) return 0;
    var count = 0;
    _forEachDisplaySlot(
      entryCount: entryCount,
      enableDoublePage: enableDoublePage,
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
    required bool Function(int entryIndex) isTransitionAt,
  }) {
    if (targetSlot < 0 || entryCount <= 0) return null;
    (int, int?)? result;
    _forEachDisplaySlot(
      entryCount: entryCount,
      enableDoublePage: enableDoublePage,
      isTransitionAt: isTransitionAt,
      onSlot: (slotIndex, primaryEntryIndex, secondaryEntryIndex) {
        if (slotIndex != targetSlot || result != null) return;
        result = (primaryEntryIndex, secondaryEntryIndex);
      },
    );
    return result;
  }

  void _forEachDisplaySlot({
    required int entryCount,
    required bool enableDoublePage,
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
    while (entryIndex < entryCount) {
      final primaryEntryIndex = entryIndex;
      if (!enableDoublePage || isTransitionAt(primaryEntryIndex)) {
        onSlot(slotIndex, primaryEntryIndex, null);
        slotIndex++;
        entryIndex++;
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

  int _effectiveCurrentChapterSlotCount() {
    if (_currentChapterSlotCount > 0) return _currentChapterSlotCount;
    final readSetting = context.read<GlobalSettingCubit>().state.readSetting;
    final fallback = getReadModeSlotCount(
      imageCount: epInfo.length,
      enableDoublePage: readSetting.doublePageMode,
    );
    return fallback > 0 ? fallback : 1;
  }

  int _mapGlobalToCurrentChapterLocalSlot(int globalIndex) {
    final local = globalIndex - _currentChapterStartSlot;
    final maxLocal = _effectiveCurrentChapterSlotCount() - 1;
    return local.clamp(0, maxLocal);
  }

  int _mapCurrentChapterLocalToGlobalSlot(int localIndex) {
    final maxLocal = _effectiveCurrentChapterSlotCount() - 1;
    final clampedLocal = localIndex.clamp(0, maxLocal);
    return _currentChapterStartSlot + clampedLocal;
  }

  bool _isTransitionGlobalSlot(int globalSlot, ReadSettingState readSetting) {
    if (!_isSeamlessEnabled(readSetting) || _loadedChapters.isEmpty) {
      return false;
    }
    if (globalSlot < 0) return false;

    if (isColumnReadMode(readSetting.readMode)) {
      final entries = _buildColumnEntries(readSetting: readSetting);
      final slotEntries = _resolveDisplaySlotEntries(
        targetSlot: globalSlot,
        entryCount: entries.length,
        enableDoublePage: readSetting.doublePageMode,
        isTransitionAt: (entryIndex) =>
            entries[entryIndex].type == ColumnModeEntryType.transition,
      );
      if (slotEntries == null) return false;
      return entries[slotEntries.$1].type == ColumnModeEntryType.transition;
    }

    final entries = _buildRowEntries(readSetting: readSetting);
    final slotEntries = _resolveDisplaySlotEntries(
      targetSlot: globalSlot,
      entryCount: entries.length,
      enableDoublePage: readSetting.doublePageMode,
      isTransitionAt: (entryIndex) =>
          entries[entryIndex].type == RowModeEntryType.transition,
    );
    if (slotEntries == null) return false;
    return entries[slotEntries.$1].type == RowModeEntryType.transition;
  }

  int? _transitionNextOrderByGlobalSlot(
    int globalSlot,
    ReadSettingState readSetting,
  ) {
    if (!_isSeamlessEnabled(readSetting) || _loadedChapters.isEmpty) {
      return null;
    }
    if (globalSlot < 0) return null;

    if (isColumnReadMode(readSetting.readMode)) {
      final entries = _buildColumnEntries(readSetting: readSetting);
      final slotEntries = _resolveDisplaySlotEntries(
        targetSlot: globalSlot,
        entryCount: entries.length,
        enableDoublePage: readSetting.doublePageMode,
        isTransitionAt: (entryIndex) =>
            entries[entryIndex].type == ColumnModeEntryType.transition,
      );
      if (slotEntries == null) return null;
      final entry = entries[slotEntries.$1];
      if (entry.type != ColumnModeEntryType.transition) return null;
      return entry.chapterOrder;
    }

    final entries = _buildRowEntries(readSetting: readSetting);
    final slotEntries = _resolveDisplaySlotEntries(
      targetSlot: globalSlot,
      entryCount: entries.length,
      enableDoublePage: readSetting.doublePageMode,
      isTransitionAt: (entryIndex) =>
          entries[entryIndex].type == RowModeEntryType.transition,
    );
    if (slotEntries == null) return null;
    final entry = entries[slotEntries.$1];
    if (entry.type != RowModeEntryType.transition) return null;
    return entry.chapterOrder;
  }

  bool _canLoadPreviousChapter() {
    final chapters = _catalogChapters();
    if (chapters.isEmpty || _loadedChapters.isEmpty) return false;
    final index = _catalogIndexByOrder(_loadedChapters.first.order);
    return index > 0;
  }

  bool _canLoadNextChapter() {
    final chapters = _catalogChapters();
    if (chapters.isEmpty || _loadedChapters.isEmpty) return false;
    final index = _catalogIndexByOrder(_loadedChapters.last.order);
    if (index < 0) return false;
    return index < chapters.length - 1;
  }

  int? _resolveAdjacentChapterOrder({required bool previous}) {
    final chapters = _catalogChapters();
    if (chapters.isEmpty || _loadedChapters.isEmpty) return null;
    final anchorOrder = previous
        ? _loadedChapters.first.order
        : _loadedChapters.last.order;
    final anchorIndex = _catalogIndexByOrder(anchorOrder);
    if (anchorIndex < 0) return null;

    final targetIndex = previous ? anchorIndex - 1 : anchorIndex + 1;
    if (targetIndex < 0 || targetIndex >= chapters.length) return null;
    return chapters[targetIndex].order;
  }

  Future<void> _triggerSeamlessBoundary({required bool previous}) async {
    if (_loadedChapters.isEmpty) return;

    if (previous) {
      if (!_canLoadPreviousChapter()) return;
      final nextOrder = _loadedChapters.first.order;
      final revealed = _revealTransition(nextOrder: nextOrder);
      if (revealed) {
        _setTransitionStatus(nextOrder, SeamlessTransitionStatus.hidden);
        await _shiftCurrentSlot(shiftBy: 1);
        return;
      }
      await _ensureBoundaryResolved(nextOrder: nextOrder);
      return;
    }

    if (!_canLoadNextChapter()) return;
    final nextOrder = _resolveAdjacentChapterOrder(previous: false);
    if (nextOrder == null) return;
    final revealed = _revealTransition(nextOrder: nextOrder);
    if (revealed) {
      _setTransitionStatus(nextOrder, SeamlessTransitionStatus.hidden);
    }
    final status = _transitionStatusByNextOrderValue(nextOrder);
    if (status == SeamlessTransitionStatus.hidden ||
        status == SeamlessTransitionStatus.error) {
      unawaited(_ensureBoundaryResolved(nextOrder: nextOrder));
    } else {
      unawaited(_prefetchNextChapterIfNeeded());
    }
  }

  Future<void> _prefetchNextChapterIfNeeded() async {
    final nextOrder = _resolveAdjacentChapterOrder(previous: false);
    if (nextOrder == null) return;
    await _prefetchChapterByOrderIfNeeded(nextOrder);
  }

  Future<void> _prefetchChapterByOrderIfNeeded(int order) async {
    if (_isOrderLoaded(order)) return;
    if (_prefetchedChapterInfoByOrder.containsKey(order)) return;
    if (_prefetchingChapterOrders.contains(order)) return;
    if (_loadingChapterOrders.contains(order)) return;

    final isVisible = _visibleTransitionNextOrders.contains(order);
    _prefetchingChapterOrders.add(order);
    if (isVisible) {
      _setTransitionStatus(order, SeamlessTransitionStatus.loading);
    }

    try {
      final chapterInfo = await _readChapterByOrder(order);
      if (!mounted) return;
      if (chapterInfo.length <= 0 || chapterInfo.docs.isEmpty) {
        if (isVisible) {
          _setTransitionStatus(order, SeamlessTransitionStatus.error);
        }
        return;
      }

      _prefetchedChapterInfoByOrder[order] = chapterInfo;
      if (isVisible) {
        _setTransitionStatus(order, SeamlessTransitionStatus.ready);
      }
    } catch (_) {
      if (isVisible) {
        _setTransitionStatus(order, SeamlessTransitionStatus.error);
      }
    } finally {
      _prefetchingChapterOrders.remove(order);
    }
  }

  Future<void> _onTransitionAction(int nextOrder) async {
    _revealTransition(nextOrder: nextOrder);
    await _ensureBoundaryResolved(nextOrder: nextOrder);
  }

  Future<void> _ensureBoundaryResolved({required int nextOrder}) async {
    if (!_visibleTransitionNextOrders.contains(nextOrder)) {
      _revealTransition(nextOrder: nextOrder);
    }

    final targetOrder = _resolveTargetOrderForBoundary(nextOrder);
    if (targetOrder == null) {
      _setTransitionStatus(nextOrder, SeamlessTransitionStatus.ready);
      return;
    }
    if (_loadingChapterOrders.contains(targetOrder)) return;

    _loadingChapterOrders.add(targetOrder);
    _setTransitionStatus(nextOrder, SeamlessTransitionStatus.loading);
    final readSetting = context.read<GlobalSettingCubit>().state.readSetting;
    final previousTotalSlots = _resolveTotalSlots(readSetting);
    final oldGlobalPageIndex = context.read<ReaderCubit>().state.pageIndex;
    final shouldPrepend = _shouldPrependOrder(targetOrder);

    try {
      final chapterInfo =
          _prefetchedChapterInfoByOrder.remove(targetOrder) ??
          await _readChapterByOrder(targetOrder);
      if (!mounted) return;
      if (chapterInfo.length <= 0 || chapterInfo.docs.isEmpty) {
        _setTransitionStatus(nextOrder, SeamlessTransitionStatus.error);
        return;
      }

      if (!_isOrderLoaded(targetOrder)) {
        _refreshState(() {
          _loadedChapters.add(
            _LoadedChapterData(order: targetOrder, epInfo: chapterInfo),
          );
          _sortLoadedChaptersByCatalog();
        });
      }

      _ensureEdgeTransitionsVisible();

      _setTransitionStatus(nextOrder, SeamlessTransitionStatus.ready);

      if (shouldPrepend) {
        final latestReadSetting = context
            .read<GlobalSettingCubit>()
            .state
            .readSetting;
        final latestTotalSlots = _resolveTotalSlots(latestReadSetting);
        final shiftBy = (latestTotalSlots - previousTotalSlots).clamp(
          0,
          double.maxFinite.toInt(),
        );
        final shiftedGlobalIndex = oldGlobalPageIndex + shiftBy;
        await _jumpToGlobalSlot(shiftedGlobalIndex);
      } else {
        _applyCurrentChapterByGlobalSlot(oldGlobalPageIndex);
      }
    } catch (_) {
      _setTransitionStatus(nextOrder, SeamlessTransitionStatus.error);
    } finally {
      _loadingChapterOrders.remove(targetOrder);
    }
  }

  Future<NormalComicEpInfo> _readChapterByOrder(int order) async {
    if (_isDownloadEntryType) {
      return getPluginInfoFromLocal(widget.from, comicId, order);
    }
    return getPluginReadSnapshot(comicId, order, widget.from, comicInfo);
  }

  void _onSeamlessGlobalSlotObserved(int globalSlot) {
    _applyCurrentChapterByGlobalSlot(globalSlot);
    if (_loadedChapters.isEmpty) return;

    final readSetting = context.read<GlobalSettingCubit>().state.readSetting;
    final transitionNextOrder = _transitionNextOrderByGlobalSlot(
      globalSlot,
      readSetting,
    );
    if (transitionNextOrder != null) {
      unawaited(_ensureBoundaryResolved(nextOrder: transitionNextOrder));
      return;
    }

    final totalSlots = context.read<ReaderCubit>().state.totalSlots;
    if (totalSlots <= 0) return;

    final remainToEnd = totalSlots - globalSlot - 1;
    if (remainToEnd <= _nextAutoResolveThreshold && _canLoadNextChapter()) {
      final nextOrder = _resolveAdjacentChapterOrder(previous: false);
      if (nextOrder != null) {
        unawaited(_ensureBoundaryResolved(nextOrder: nextOrder));
      }
    }

    if (remainToEnd <= _nextPrefetchThreshold && _canLoadNextChapter()) {
      unawaited(_prefetchNextChapterIfNeeded());
    }
  }

  void _applyCurrentChapterByGlobalSlot(int globalSlot) {
    if (_loadedChapters.isEmpty) return;
    final readSetting = context.read<GlobalSettingCubit>().state.readSetting;

    final slotContext = _resolveImageSlotContextByGlobalSlot(
      globalSlot,
      readSetting,
    );
    if (slotContext == null) {
      return;
    }

    final chapter = _loadedChapters.firstWhere(
      (item) => item.order == slotContext.chapterOrder,
      orElse: () => _loadedChapters.last,
    );

    final chapterChanged =
        epInfo.epId != chapter.epInfo.epId ||
        _currentChapterStartSlot != slotContext.chapterStartSlot ||
        _currentChapterSlotCount != slotContext.chapterImageCount;
    if (!chapterChanged) return;

    _refreshState(() {
      epInfo = chapter.epInfo;
      _currentChapterStartSlot = slotContext.chapterStartSlot;
      _currentChapterSlotCount = slotContext.chapterImageCount;
      _syncJumpChapterState(order: chapter.order);
    });
  }

  _ImageSlotContext? _resolveImageSlotContextByGlobalSlot(
    int globalSlot,
    ReadSettingState readSetting,
  ) {
    if (globalSlot < 0) return null;

    if (isColumnReadMode(readSetting.readMode)) {
      final entries = _buildColumnEntries(readSetting: readSetting);
      final slotEntries = _resolveDisplaySlotEntries(
        targetSlot: globalSlot,
        entryCount: entries.length,
        enableDoublePage: readSetting.doublePageMode,
        isTransitionAt: (entryIndex) =>
            entries[entryIndex].type == ColumnModeEntryType.transition,
      );
      if (slotEntries == null) return null;
      final current = entries[slotEntries.$1];
      if (current.type != ColumnModeEntryType.image) return null;
      final chapterOrder = current.chapterOrder;
      var chapterStartSlot = -1;
      var chapterSlotCount = 0;
      _forEachDisplaySlot(
        entryCount: entries.length,
        enableDoublePage: readSetting.doublePageMode,
        isTransitionAt: (entryIndex) =>
            entries[entryIndex].type == ColumnModeEntryType.transition,
        onSlot: (slotIndex, primaryEntryIndex, secondaryEntryIndex) {
          final entry = entries[primaryEntryIndex];
          if (entry.type != ColumnModeEntryType.image) return;
          if (entry.chapterOrder != chapterOrder) return;
          chapterStartSlot = chapterStartSlot < 0
              ? slotIndex
              : chapterStartSlot;
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

    final entries = _buildRowEntries(readSetting: readSetting);
    final slotEntries = _resolveDisplaySlotEntries(
      targetSlot: globalSlot,
      entryCount: entries.length,
      enableDoublePage: readSetting.doublePageMode,
      isTransitionAt: (entryIndex) =>
          entries[entryIndex].type == RowModeEntryType.transition,
    );
    if (slotEntries == null) return null;
    final current = entries[slotEntries.$1];
    if (current.type != RowModeEntryType.image) return null;
    final chapterOrder = current.chapterOrder;
    var chapterStartSlot = -1;
    var chapterSlotCount = 0;
    _forEachDisplaySlot(
      entryCount: entries.length,
      enableDoublePage: readSetting.doublePageMode,
      isTransitionAt: (entryIndex) =>
          entries[entryIndex].type == RowModeEntryType.transition,
      onSlot: (slotIndex, primaryEntryIndex, secondaryEntryIndex) {
        final entry = entries[primaryEntryIndex];
        if (entry.type != RowModeEntryType.image) return;
        if (entry.chapterOrder != chapterOrder) return;
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

  _ImageSlotContext? _resolveImageSlotContextByChapterOrder({
    required int chapterOrder,
    required ReadSettingState readSetting,
  }) {
    if (!_isSeamlessEnabled(readSetting) || _loadedChapters.isEmpty) {
      return null;
    }

    if (isColumnReadMode(readSetting.readMode)) {
      final entries = _buildColumnEntries(readSetting: readSetting);
      var chapterStartSlot = -1;
      var chapterSlotCount = 0;
      _forEachDisplaySlot(
        entryCount: entries.length,
        enableDoublePage: readSetting.doublePageMode,
        isTransitionAt: (entryIndex) =>
            entries[entryIndex].type == ColumnModeEntryType.transition,
        onSlot: (slotIndex, primaryEntryIndex, secondaryEntryIndex) {
          final entry = entries[primaryEntryIndex];
          if (entry.type != ColumnModeEntryType.image) return;
          if (entry.chapterOrder != chapterOrder) return;
          chapterStartSlot = chapterStartSlot < 0
              ? slotIndex
              : chapterStartSlot;
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

    final entries = _buildRowEntries(readSetting: readSetting);
    var chapterStartSlot = -1;
    var chapterSlotCount = 0;
    _forEachDisplaySlot(
      entryCount: entries.length,
      enableDoublePage: readSetting.doublePageMode,
      isTransitionAt: (entryIndex) =>
          entries[entryIndex].type == RowModeEntryType.transition,
      onSlot: (slotIndex, primaryEntryIndex, secondaryEntryIndex) {
        final entry = entries[primaryEntryIndex];
        if (entry.type != RowModeEntryType.image) return;
        if (entry.chapterOrder != chapterOrder) return;
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

  bool _hasLeadingTransition(ReadSettingState readSetting) {
    if (!_isSeamlessEnabled(readSetting) || _loadedChapters.isEmpty) {
      return false;
    }
    final leadingChapterOrder = _loadedChapters.first.order;
    return _shouldShowTransition(nextOrder: leadingChapterOrder);
  }

  int _resolveEntryDefaultGlobalSlot(ReadSettingState readSetting) {
    return _hasLeadingTransition(readSetting) ? 1 : 0;
  }

  int _resolveHistoryGlobalSlotWithTransitions({
    required int baseGlobalSlot,
    required ReadSettingState readSetting,
  }) {
    var result = baseGlobalSlot;
    if (_hasLeadingTransition(readSetting)) {
      result += 1;
    }
    return result;
  }

  bool _isOrderLoaded(int order) {
    return _loadedChapters.any((chapter) => chapter.order == order);
  }

  bool _shouldShowTransition({required int nextOrder}) {
    if (!_visibleTransitionNextOrders.contains(nextOrder)) return false;
    final previousOrder = _previousOrderOf(nextOrder);
    return previousOrder != null;
  }

  bool _revealTransition({required int nextOrder}) {
    if (_visibleTransitionNextOrders.contains(nextOrder)) {
      return false;
    }
    _refreshState(() {
      _visibleTransitionNextOrders.add(nextOrder);
    });
    return true;
  }

  void _setTransitionStatus(int nextOrder, SeamlessTransitionStatus status) {
    if (_transitionStatusByNextOrder[nextOrder] == status) return;
    _refreshState(() {
      _transitionStatusByNextOrder[nextOrder] = status;
    });
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
        _prefetchingChapterOrders.contains(targetOrder)) {
      return SeamlessTransitionStatus.loading;
    }
    if (targetOrder != null &&
        _prefetchedChapterInfoByOrder.containsKey(targetOrder)) {
      return SeamlessTransitionStatus.ready;
    }

    return _transitionStatusByNextOrder[nextOrder] ??
        SeamlessTransitionStatus.hidden;
  }

  int? _resolveTargetOrderForBoundary(int nextOrder) {
    final previousOrder = _previousOrderOf(nextOrder);
    if (previousOrder == null) return null;

    final previousLoaded = _isOrderLoaded(previousOrder);
    final nextLoaded = _isOrderLoaded(nextOrder);

    if (!previousLoaded) {
      return previousOrder;
    }
    if (!nextLoaded) {
      return nextOrder;
    }
    return null;
  }

  bool _shouldPrependOrder(int order) {
    if (_loadedChapters.isEmpty) return false;
    final firstLoadedIndex = _catalogIndexByOrder(_loadedChapters.first.order);
    final targetIndex = _catalogIndexByOrder(order);
    if (firstLoadedIndex < 0 || targetIndex < 0) return false;
    return targetIndex < firstLoadedIndex;
  }

  Future<void> _shiftCurrentSlot({required int shiftBy}) async {
    if (shiftBy == 0) return;
    final oldGlobal = context.read<ReaderCubit>().state.pageIndex;
    await _jumpToGlobalSlot(oldGlobal + shiftBy);
  }

  Future<void> _jumpToGlobalSlot(int targetGlobalSlot) async {
    if (!mounted) return;
    final cubit = context.read<ReaderCubit>();
    final readSetting = context.read<GlobalSettingCubit>().state.readSetting;
    final maxSlot = (_resolveTotalSlots(readSetting) - 1).clamp(
      0,
      double.maxFinite.toInt(),
    );
    final safeTarget = targetGlobalSlot.clamp(0, maxSlot);
    cubit.updatePageIndex(safeTarget);
    cubit.updateSliderChanged(safeTarget.toDouble());
    _applyCurrentChapterByGlobalSlot(safeTarget);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final readMode = context
          .read<GlobalSettingCubit>()
          .state
          .readSetting
          .readMode;
      if (isColumnReadMode(readMode)) {
        if (!scrollController.hasClients) return;
        observerController.jumpTo(
          index: safeTarget,
          offset: (offset) => MediaQuery.of(context).padding.top + 5.0,
        );
        return;
      }
      if (_pageController.hasClients) {
        _pageController.jumpToPage(safeTarget);
      }
    });
  }

  void _sortLoadedChaptersByCatalog() {
    _loadedChapters.sort((a, b) {
      final left = _catalogIndexByOrder(a.order);
      final right = _catalogIndexByOrder(b.order);
      if (left == right) {
        return a.order.compareTo(b.order);
      }
      if (left < 0) return 1;
      if (right < 0) return -1;
      return left.compareTo(right);
    });
  }

  int _catalogIndexByOrder(int order) {
    final mappedIndex = _chapterOrderToCatalogIndex[order];
    if (mappedIndex != null && mappedIndex >= 0) {
      return mappedIndex;
    }
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

  String _chapterTitleByOrder(int order) {
    final loaded = _loadedChapters.where((chapter) => chapter.order == order);
    if (loaded.isNotEmpty) {
      final title = loaded.first.epInfo.epName.trim();
      if (title.isNotEmpty) {
        return title;
      }
    }
    final chapters = _catalogChapters();
    final index = _catalogIndexByOrder(order);
    if (index >= 0 && index < chapters.length) {
      final name = chapters[index].name.trim();
      if (name.isNotEmpty) {
        return name;
      }
    }
    return '章节 $order';
  }

  List<UnifiedComicChapterRef> _catalogChapters() {
    if (_chapterRefs.isNotEmpty) {
      return _chapterRefs;
    }
    return _jumpChapter.chapters;
  }

  void _syncJumpChapterState({required int order}) {
    _jumpChapter.order = order;
    final chapters = _catalogChapters();
    final index = _catalogIndexByOrder(order);
    if (index < 0) {
      _jumpChapter.havePrev = false;
      _jumpChapter.haveNext = false;
      return;
    }
    _jumpChapter.havePrev = index > 0;
    _jumpChapter.haveNext = index < chapters.length - 1;
  }
}
