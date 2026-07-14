import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/comic_read/cubit/image_size_cubit.dart';
import 'package:zephyr/page/comic_read/widgets/layout/read_layout.dart';
import 'package:zephyr/page/comic_read/widgets/modes/read_mode_image_builder.dart';
import 'package:zephyr/page/comic_read/widgets/modes/read_mode_transition_style.dart';
import 'package:zephyr/page/comic_read/widgets/modes/read_mode_utils.dart';

/// 阅读模式渲染轴。
enum ReadModeAxis { column, row }

/// 把单个显示槽位渲染为 Widget，不关心外层滚动容器。
///
/// [singleItem] 与 [doublePageSlot] 有且仅有一个非 null：
/// - 单页模式使用 [singleItem]；
/// - 双页模式使用 [doublePageSlot]。
Widget buildReadModeSlot({
  required BuildContext context,
  required int slotIndex,
  required ReadModeSlotItem? singleItem,
  required ReadModeDoublePageSlot? doublePageSlot,
  required ReadModeAxis axis,
  required double containerWidth,
  required double contentWidth,
  required Color backgroundColor,
  required bool isRtl,
  required String comicId,
  required String from,
  required ValueChanged<int>? onTransitionAction,
  required ReadModeTransitionStyle transitionStyle,
}) {
  assert(
    (singleItem == null) != (doublePageSlot == null),
    '必须且只能传入 singleItem 或 doublePageSlot 之一',
  );

  if (singleItem != null) {
    final entry = singleItem.entry;
    if (entry.type == ReadModeEntryType.transition) {
      return buildReadModeTransitionItem(
        entry: entry,
        backgroundColor: backgroundColor,
        onTap: () => onTransitionAction?.call(entry.chapterOrder),
        containerWidth: containerWidth,
        fixedCardSize: transitionStyle.fixedCardSize,
        outerPadding: transitionStyle.outerPadding,
        cardPadding: transitionStyle.cardPadding,
        minHeight: transitionStyle.minHeight,
        lineSpacing: transitionStyle.lineSpacing,
      );
    }

    if (axis == ReadModeAxis.column) {
      return _buildColumnSingleImage(
        context: context,
        item: singleItem,
        containerWidth: containerWidth,
        contentWidth: contentWidth,
        backgroundColor: backgroundColor,
        comicId: comicId,
        from: from,
      );
    }

    return _buildRowSingleImage(
      context: context,
      slotIndex: slotIndex,
      item: singleItem,
      containerWidth: containerWidth,
      contentWidth: contentWidth,
      backgroundColor: backgroundColor,
      comicId: comicId,
      from: from,
    );
  }

  final slot = doublePageSlot!;
  if (slot.transition != null) {
    final entry = slot.transition!.entry;
    return buildReadModeTransitionItem(
      entry: entry,
      backgroundColor: backgroundColor,
      onTap: () => onTransitionAction?.call(entry.chapterOrder),
      containerWidth: containerWidth,
      fixedCardSize: transitionStyle.fixedCardSize,
      outerPadding: transitionStyle.outerPadding,
      cardPadding: transitionStyle.cardPadding,
      minHeight: transitionStyle.minHeight,
      lineSpacing: transitionStyle.lineSpacing,
    );
  }

  if (axis == ReadModeAxis.column) {
    return _buildColumnDoublePageImage(
      context: context,
      slot: slot,
      slotIndex: slotIndex,
      containerWidth: containerWidth,
      contentWidth: contentWidth,
      backgroundColor: backgroundColor,
      isRtl: isRtl,
      comicId: comicId,
      from: from,
    );
  }

  return _buildRowDoublePageImage(
    context: context,
    slot: slot,
    slotIndex: slotIndex,
    containerWidth: containerWidth,
    contentWidth: contentWidth,
    backgroundColor: backgroundColor,
    isRtl: isRtl,
    comicId: comicId,
    from: from,
  );
}

Widget _buildColumnSingleImage({
  required BuildContext context,
  required ReadModeSlotItem item,
  required double containerWidth,
  required double contentWidth,
  required Color backgroundColor,
  required String comicId,
  required String from,
}) {
  final entry = item.entry;
  final cacheIndex = _resolveImageCacheIndex(entry, item.entryIndex);

  return BlocSelector<ImageSizeCubit, ImageSizeState, Size>(
    selector: (state) => state.getSizeValue(cacheIndex),
    builder: (context, cachedSize) {
      final finalHeight = _resolveDisplayHeight(
        cachedSize: cachedSize,
        targetWidth: contentWidth,
      );

      return Container(
        color: backgroundColor,
        height: finalHeight,
        width: containerWidth,
        alignment: Alignment.center,
        child: SizedBox(
          width: contentWidth,
          height: finalHeight,
          child: buildReadModeImage(
            context: context,
            entry: entry,
            comicId: comicId,
            from: from,
            slotIndex: entry.chapterPageIndex ?? item.entryIndex,
            cacheIndex: cacheIndex,
            isColumn: true,
          ),
        ),
      );
    },
  );
}

Widget _buildRowSingleImage({
  required BuildContext context,
  required int slotIndex,
  required ReadModeSlotItem item,
  required double containerWidth,
  required double contentWidth,
  required Color backgroundColor,
  required String comicId,
  required String from,
}) {
  final entry = item.entry;

  return Container(
    color: backgroundColor,
    width: containerWidth,
    alignment: Alignment.center,
    child: SizedBox(
      width: contentWidth,
      child: buildReadModeImage(
        context: context,
        entry: entry,
        comicId: comicId,
        from: from,
        slotIndex: slotIndex,
        cacheIndex: item.entryIndex,
        displayNumber: (entry.chapterPageIndex ?? 0) + 1,
        isColumn: false,
      ),
    ),
  );
}

Widget _buildColumnDoublePageImage({
  required BuildContext context,
  required ReadModeDoublePageSlot slot,
  required int slotIndex,
  required double containerWidth,
  required double contentWidth,
  required Color backgroundColor,
  required bool isRtl,
  required String comicId,
  required String from,
}) {
  final left = slot.left;
  final right = slot.right;
  if (left == null) return const SizedBox.shrink();

  final panelWidth = ((contentWidth - kDoublePageGap) / 2).clamp(
    1.0,
    contentWidth,
  );

  return BlocSelector<ImageSizeCubit, ImageSizeState, (Size, Size)>(
    selector: (state) => (
      state.getSizeValue(_resolveImageCacheIndex(left.entry, left.entryIndex)),
      right != null
          ? state.getSizeValue(
              _resolveImageCacheIndex(right.entry, right.entryIndex),
            )
          : const Size(0, 0),
    ),
    builder: (context, pairSize) {
      final leftHeight = _resolveDisplayHeight(
        cachedSize: pairSize.$1,
        targetWidth: panelWidth,
      );
      final rightHeight = right != null
          ? _resolveDisplayHeight(
              cachedSize: pairSize.$2,
              targetWidth: panelWidth,
            )
          : 0.0;
      final rowHeight = math
          .max(leftHeight, rightHeight)
          .clamp(1.0, double.infinity);

      final leftChild = SizedBox(
        width: panelWidth,
        height: rowHeight,
        child: buildReadModeImage(
          context: context,
          entry: left.entry,
          comicId: comicId,
          from: from,
          slotIndex: left.entry.chapterPageIndex ?? left.entryIndex,
          cacheIndex: _resolveImageCacheIndex(left.entry, left.entryIndex),
          isColumn: true,
        ),
      );
      final rightChild = SizedBox(
        width: panelWidth,
        height: rowHeight,
        child: right != null
            ? buildReadModeImage(
                context: context,
                entry: right.entry,
                comicId: comicId,
                from: from,
                slotIndex: right.entry.chapterPageIndex ?? right.entryIndex,
                cacheIndex: _resolveImageCacheIndex(
                  right.entry,
                  right.entryIndex,
                ),
                isColumn: true,
              )
            : const SizedBox.shrink(),
      );

      final children = isRtl
          ? [rightChild, const SizedBox(width: kDoublePageGap), leftChild]
          : [leftChild, const SizedBox(width: kDoublePageGap), rightChild];

      return Container(
        color: backgroundColor,
        width: containerWidth,
        height: rowHeight,
        alignment: Alignment.center,
        child: SizedBox(
          width: contentWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      );
    },
  );
}

Widget _buildRowDoublePageImage({
  required BuildContext context,
  required ReadModeDoublePageSlot slot,
  required int slotIndex,
  required double containerWidth,
  required double contentWidth,
  required Color backgroundColor,
  required bool isRtl,
  required String comicId,
  required String from,
}) {
  final panelWidth = ((contentWidth - kDoublePageGap) / 2).clamp(
    1.0,
    contentWidth,
  );

  final leftChild = SizedBox(
    width: panelWidth,
    child: slot.left != null
        ? buildReadModeImage(
            context: context,
            entry: slot.left!.entry,
            comicId: comicId,
            from: from,
            slotIndex: slotIndex,
            cacheIndex: slot.left!.entryIndex,
            displayNumber: (slot.left!.entry.chapterPageIndex ?? 0) + 1,
            isColumn: false,
          )
        : const SizedBox.shrink(),
  );
  final rightChild = SizedBox(
    width: panelWidth,
    child: slot.right != null
        ? buildReadModeImage(
            context: context,
            entry: slot.right!.entry,
            comicId: comicId,
            from: from,
            slotIndex: slotIndex,
            cacheIndex: slot.right!.entryIndex,
            displayNumber: (slot.right!.entry.chapterPageIndex ?? 0) + 1,
            isColumn: false,
          )
        : const SizedBox.shrink(),
  );

  final children = isRtl
      ? [rightChild, const SizedBox(width: kDoublePageGap), leftChild]
      : [leftChild, const SizedBox(width: kDoublePageGap), rightChild];

  return Container(
    color: backgroundColor,
    width: containerWidth,
    alignment: Alignment.center,
    child: SizedBox(
      width: contentWidth,
      child: Row(children: children),
    ),
  );
}

int _resolveImageCacheIndex(ReadModeEntry entry, int fallbackIndex) {
  final localPageIndex = entry.chapterPageIndex;
  if (entry.type != ReadModeEntryType.image || localPageIndex == null) {
    return fallbackIndex;
  }
  return resolveStableSizeCacheIndex(
    chapterOrder: entry.chapterOrder,
    localPageIndex: localPageIndex,
  );
}

double _resolveDisplayHeight({
  required Size cachedSize,
  required double targetWidth,
}) {
  if (cachedSize.width <= 0 || cachedSize.height <= 0) {
    return 1;
  }

  if ((cachedSize.width - targetWidth).abs() < 0.1) {
    return cachedSize.height;
  }

  final aspectRatio = cachedSize.height / cachedSize.width;
  return (targetWidth * aspectRatio).clamp(1.0, double.infinity);
}
