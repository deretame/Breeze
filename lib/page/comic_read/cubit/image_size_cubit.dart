import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/comic_read/method/image_size_cache_store.dart';
import 'package:zephyr/page/comic_read/widgets/layout/read_layout.dart';

class ImageSizeState {
  final Map<int, Size> sizeCache;
  final Set<int> resolvedIndices;
  final double defaultWidth;
  final double defaultHeight;

  ImageSizeState({
    required this.sizeCache,
    required this.resolvedIndices,
    required this.defaultWidth,
    required this.defaultHeight,
  });

  Size getSizeValue(int index) {
    return sizeCache[index] ?? Size(defaultWidth, defaultHeight);
  }
}

class ImageSizeCubit extends Cubit<ImageSizeState> {
  static const Duration _saveDebounceDuration = Duration(milliseconds: 300);

  final int count;
  final double defaultWidth;
  final double defaultHeight;
  final String sourceTag;
  final List<String> pageKeys;
  final int _chapterOrder;
  final ImageSizeCacheStore _cacheStore;

  Timer? _saveTimer;
  bool _hasPendingSave = false;
  bool _isFlushing = false;
  bool _isDisposed = false;

  ImageSizeCubit({
    required this.count,
    required this.defaultWidth,
    required this.defaultHeight,
    required this.sourceTag,
    required this.pageKeys,
    required int chapterOrder,
    required bool hydrateOnInit,
    required Map<int, Size> initialCache,
    required Set<int> initialResolved,
  }) : _chapterOrder = chapterOrder,
       _cacheStore = ImageSizeCacheStore(
         sourceTag: sourceTag,
         pageKeys: pageKeys,
       ),
       super(
         ImageSizeState(
           sizeCache: initialCache,
           resolvedIndices: initialResolved,
           defaultWidth: defaultWidth,
           defaultHeight: defaultHeight,
         ),
       ) {
    if (hydrateOnInit) {
      unawaited(_hydrateFromDisk());
    }
  }

  factory ImageSizeCubit.create({
    required double defaultWidth,
    required int count,
    required String sourceTag,
    required List<String> pageKeys,
    required int chapterOrder,
    Map<int, Size>? persistedCache,
  }) {
    final double defaultHeight = defaultWidth * 1.2;

    final initialCache = <int, Size>{};
    final initialResolved = <int>{};

    for (int i = 0; i < count; i++) {
      double currentHeight;
      currentHeight = defaultHeight;
      initialCache[i] = Size(defaultWidth, currentHeight);
    }

    if (persistedCache != null && persistedCache.isNotEmpty) {
      for (final entry in persistedCache.entries) {
        if (entry.key < 0 || entry.key >= count) continue;
        // 持久化以本地页索引为键，运行时以章节哈希索引为键，这里做映射。
        final cacheIndex = resolveStableSizeCacheIndex(
          chapterOrder: chapterOrder,
          localPageIndex: entry.key,
        );
        initialCache[cacheIndex] = entry.value;
        initialResolved.add(cacheIndex);
      }
    }

    return ImageSizeCubit(
      count: count,
      defaultWidth: defaultWidth,
      defaultHeight: defaultHeight,
      sourceTag: sourceTag,
      pageKeys: pageKeys,
      chapterOrder: chapterOrder,
      hydrateOnInit: persistedCache == null,
      initialCache: initialCache,
      initialResolved: initialResolved,
    );
  }

  ({Size size, bool isCached}) getSize(int index) {
    final size = state.sizeCache[index] ?? Size(defaultWidth, defaultHeight);
    final isCached = state.resolvedIndices.contains(index);
    return (size: size, isCached: isCached);
  }

  void updateSize(int index, Size newSize) {
    final isAlreadyResolved = state.resolvedIndices.contains(index);
    final isSizeChanged = state.sizeCache[index] != newSize;

    if (!isAlreadyResolved || isSizeChanged) {
      final newCache = Map<int, Size>.from(state.sizeCache);
      newCache[index] = newSize;
      final newResolved = Set<int>.from(state.resolvedIndices);
      newResolved.add(index);

      emit(
        ImageSizeState(
          sizeCache: newCache,
          resolvedIndices: newResolved,
          defaultWidth: state.defaultWidth,
          defaultHeight: state.defaultHeight,
        ),
      );
      _markDirtyAndScheduleSave();
    }
  }

  Future<void> _hydrateFromDisk() async {
    try {
      final persisted = await _cacheStore.readIndexedSizes(
        pageKeys: pageKeys,
        count: count,
      );
      if (persisted.isEmpty || _isDisposed) return;

      final newCache = Map<int, Size>.from(state.sizeCache);
      final newResolved = Set<int>.from(state.resolvedIndices);
      var changed = false;

      for (final entry in persisted.entries) {
        // 与 create 一致：本地页索引 → 运行时章节哈希索引。
        final cacheIndex = resolveStableSizeCacheIndex(
          chapterOrder: _chapterOrder,
          localPageIndex: entry.key,
        );
        newCache[cacheIndex] = entry.value;
        newResolved.add(cacheIndex);
        changed = true;
      }

      if (changed) {
        emit(
          ImageSizeState(
            sizeCache: newCache,
            resolvedIndices: newResolved,
            defaultWidth: state.defaultWidth,
            defaultHeight: state.defaultHeight,
          ),
        );
      }
    } catch (_) {}
  }

  void _markDirtyAndScheduleSave() {
    _hasPendingSave = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounceDuration, () {
      unawaited(flushNow());
    });
  }

  Future<void> flushNow() async {
    if (_isDisposed || !_hasPendingSave) return;
    if (_isFlushing) return;

    _isFlushing = true;
    _hasPendingSave = false;
    try {
      // 运行时索引（章节哈希）→ 本地页索引，持久化层只认本地页索引。
      final localSizes = <int, Size>{};
      final localResolved = <int>{};
      final max = count < pageKeys.length ? count : pageKeys.length;
      for (var i = 0; i < max; i++) {
        final runtimeIndex = resolveStableSizeCacheIndex(
          chapterOrder: _chapterOrder,
          localPageIndex: i,
        );
        if (!state.resolvedIndices.contains(runtimeIndex)) continue;
        final size = state.sizeCache[runtimeIndex];
        if (size == null) continue;
        localSizes[i] = size;
        localResolved.add(i);
      }
      await _cacheStore.write(
        pageKeys: pageKeys,
        sizeCache: localSizes,
        resolvedIndices: localResolved,
        count: count,
      );
    } catch (_) {
      _hasPendingSave = true;
    } finally {
      _isFlushing = false;
    }
  }

  Future<({int recordCount, int fileBytes, String filePath})>
  getCacheStats() async {
    return _cacheStore.getStats();
  }

  Future<void> debugPrintCacheStats() async {
    final stats = await getCacheStats();
    debugPrint(
      '[ImageSizeCache] source=$sourceTag records=${stats.recordCount} bytes=${stats.fileBytes} path=${stats.filePath}',
    );
  }

  @override
  Future<void> close() async {
    _saveTimer?.cancel();
    await flushNow();
    _isDisposed = true;
    return super.close();
  }
}
