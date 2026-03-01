// 状态类：只保存缓存 Map
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ImageSizeState {
  final Map<int, Size> sizeCache;
  final Set<int> resolvedIndices;
  final List<int> visibleIndices;
  final double defaultWidth;
  final double defaultHeight;

  ImageSizeState({
    required this.sizeCache,
    required this.resolvedIndices,
    required this.visibleIndices,
    required this.defaultWidth,
    required this.defaultHeight,
  });

  // 把逻辑移到这里，方便 Selector 调用
  Size getSizeValue(int index) {
    return sizeCache[index] ?? Size(defaultWidth, defaultHeight);
  }
}

class ImageSizeCubit extends Cubit<ImageSizeState> {
  final int count;
  final double defaultWidth;
  final double defaultHeight;

  // 构造函数：初始化默认数据
  ImageSizeCubit({
    required this.count,
    required this.defaultWidth,
    required this.defaultHeight,
    required Map<int, Size> initialCache,
    required Set<int> initialResolved,
    required List<int> initialVisibleIndices,
  }) : super(
         ImageSizeState(
           sizeCache: initialCache,
           resolvedIndices: initialResolved,
           visibleIndices: initialVisibleIndices,
           defaultWidth: defaultWidth,
           defaultHeight: defaultHeight,
         ),
       );

  factory ImageSizeCubit.create({
    required double defaultWidth,
    required int count,
  }) {
    final double defaultHeight = defaultWidth * 1.2;

    final initialCache = <int, Size>{};
    final initialResolved = <int>{};
    final initialVisibleIndices = <int>[];

    for (int i = 0; i < count; i++) {
      double currentHeight;

      currentHeight = defaultHeight;

      initialCache[i] = Size(defaultWidth, currentHeight);
    }

    return ImageSizeCubit(
      count: count,
      defaultWidth: defaultWidth,
      defaultHeight: defaultHeight,
      initialCache: initialCache,
      initialResolved: initialResolved,
      initialVisibleIndices: initialVisibleIndices,
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
          visibleIndices: state.visibleIndices,
          defaultWidth: state.defaultWidth,
          defaultHeight: state.defaultHeight,
        ),
      );
    }
  }

  void updateVisibleIndices(List<int> visibleIndices) {
    emit(
      ImageSizeState(
        sizeCache: state.sizeCache,
        resolvedIndices: state.resolvedIndices,
        visibleIndices: visibleIndices,
        defaultWidth: state.defaultWidth,
        defaultHeight: state.defaultHeight,
      ),
    );
  }
}
