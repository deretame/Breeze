import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/comic_read/method/image_size_cache_store.dart';

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
    required bool hydrateOnInit,
    required Map<int, Size> initialCache,
    required Set<int> initialResolved,
  }) : _cacheStore = ImageSizeCacheStore(
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
        initialCache[entry.key] = entry.value;
        initialResolved.add(entry.key);
      }
    }

    return ImageSizeCubit(
      count: count,
      defaultWidth: defaultWidth,
      defaultHeight: defaultHeight,
      sourceTag: sourceTag,
      pageKeys: pageKeys,
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
        newCache[entry.key] = entry.value;
        newResolved.add(entry.key);
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
      await _cacheStore.write(
        pageKeys: pageKeys,
        sizeCache: state.sizeCache,
        resolvedIndices: state.resolvedIndices,
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
