// 状态类：只保存缓存 Map
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  }) : super(
         ImageSizeState(
           sizeCache: initialCache,
           resolvedIndices: initialResolved,
           defaultWidth: defaultWidth,
           defaultHeight: defaultHeight,
         ),
       );

  factory ImageSizeCubit.create({
    required double statusBarHeight,
    required double defaultWidth,
    required int count,
  }) {
    final double defaultHeight = defaultWidth * 1.2;
    final double firstWidgetHeight = statusBarHeight;
    final double lastWidgetHeight = 75.0;

    final initialCache = <int, Size>{};
    final initialResolved = <int>{};

    for (int i = 0; i < count; i++) {
      double currentHeight;

      if (i == 0) {
        currentHeight = firstWidgetHeight;
        initialResolved.add(i);
      } else if (i == count - 1) {
        currentHeight = lastWidgetHeight;
        initialResolved.add(i);
      } else {
        currentHeight = defaultHeight;
      }

      initialCache[i] = Size(defaultWidth, currentHeight);
    }

    return ImageSizeCubit(
      count: count,
      defaultWidth: defaultWidth,
      defaultHeight: defaultHeight,
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
    }
  }
}
