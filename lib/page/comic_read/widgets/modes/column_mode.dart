import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/comic_read/controller/reader_volume_controller.dart';
import 'package:zephyr/page/comic_read/cubit/image_size_cubit.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/json/common_ep_info_json/common_ep_info_json.dart';
import 'package:zephyr/page/comic_read/model/seamless_transition_state.dart';
import 'package:zephyr/page/comic_read/widgets/image/read_image_widget.dart';
import 'package:zephyr/page/comic_read/widgets/layout/read_layout.dart';
import 'package:zephyr/page/comic_read/widgets/transition/chapter_transition_card.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/widgets/picture_bloc/models/picture_info.dart';
import 'package:zephyr/type/enum.dart';

enum ColumnModeEntryType { image, transition }

class ColumnModeEntry {
  const ColumnModeEntry._({
    required this.type,
    required this.doc,
    required this.chapterId,
    required this.chapterOrder,
    required this.chapterTitle,
    required this.chapterLocalPageIndex,
    required this.chapterTotalPages,
    required this.transitionStatus,
    this.previousChapterOrder,
    this.previousChapterTitle,
  });

  const ColumnModeEntry.image({
    required Doc doc,
    required String chapterId,
    required int chapterOrder,
    required String chapterTitle,
    required int chapterLocalPageIndex,
    required int chapterTotalPages,
  }) : this._(
         type: ColumnModeEntryType.image,
         doc: doc,
         chapterId: chapterId,
         chapterOrder: chapterOrder,
         chapterTitle: chapterTitle,
         chapterLocalPageIndex: chapterLocalPageIndex,
         chapterTotalPages: chapterTotalPages,
         transitionStatus: SeamlessTransitionStatus.ready,
       );

  const ColumnModeEntry.transition({
    required int chapterOrder,
    required String chapterTitle,
    required int previousChapterOrder,
    required String previousChapterTitle,
    required SeamlessTransitionStatus transitionStatus,
  }) : this._(
         type: ColumnModeEntryType.transition,
         doc: null,
         chapterId: null,
         chapterOrder: chapterOrder,
         chapterTitle: chapterTitle,
         chapterLocalPageIndex: null,
         chapterTotalPages: null,
         previousChapterOrder: previousChapterOrder,
         previousChapterTitle: previousChapterTitle,
         transitionStatus: transitionStatus,
       );

  final ColumnModeEntryType type;
  final Doc? doc;
  final String? chapterId;
  final int chapterOrder;
  final String chapterTitle;
  final int? chapterLocalPageIndex;
  final int? chapterTotalPages;
  final int? previousChapterOrder;
  final String? previousChapterTitle;
  final SeamlessTransitionStatus transitionStatus;
}

class ColumnModeWidget extends StatefulWidget {
  final List<ColumnModeEntry> entries;
  final bool enableDoublePage;
  final String comicId;
  final ListObserverController observerController;
  final ScrollController scrollController;
  final String from;
  final ScrollPhysics? parentPhysics;
  final bool disableScroll;
  final ReaderVolumeController volumeController;
  final ValueChanged<int>? onMiddleSlotObserved;
  final ValueChanged<int>? onTransitionAction;

  const ColumnModeWidget({
    super.key,
    required this.entries,
    required this.enableDoublePage,
    required this.comicId,
    required this.observerController,
    required this.scrollController,
    required this.from,
    this.parentPhysics,
    this.disableScroll = false,
    required this.volumeController,
    this.onMiddleSlotObserved,
    this.onTransitionAction,
  });

  @override
  State<ColumnModeWidget> createState() => _ColumnModeWidgetState();
}

class _ColumnModeWidgetState extends State<ColumnModeWidget> {
  bool get _isDoublePage => widget.enableDoublePage;

  @override
  Widget build(BuildContext context) {
    final basePhysics = widget.parentPhysics != null
        ? widget.parentPhysics!.applyTo(const AlwaysScrollableScrollPhysics())
        : const AlwaysScrollableScrollPhysics();
    final physics = widget.disableScroll
        ? const NeverScrollableScrollPhysics()
        : basePhysics;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hideTop = context.select(
          (GlobalSettingCubit c) => !c.state.readSetting.comicReadTopContainer,
        );
        final mediaQuery = MediaQuery.of(context);
        final readSetting = context.select(
          (GlobalSettingCubit c) => c.state.readSetting,
        );
        final backgroundColor = readSetting.resolveReaderBackgroundColor(
          Theme.of(context).brightness,
        );
        final sidePaddingEnabled = readSetting.sidePaddingEnabled;
        final sidePaddingPercent = readSetting.sidePaddingPercent;
        final topInset = mediaQuery.padding.top > 0
            ? mediaQuery.padding.top
            : mediaQuery.viewPadding.top;
        final bottomInset = mediaQuery.padding.bottom > 0
            ? mediaQuery.padding.bottom
            : mediaQuery.viewPadding.bottom;

        final double topPadding = hideTop ? 0 : topInset;
        final double bottomPadding = bottomInset + 50;

        final containerWidth = constraints.maxWidth;
        final contentWidth = getConstrainedImageWidth(
          containerWidth: containerWidth,
          enableSidePadding: sidePaddingEnabled,
          sidePaddingPercent: sidePaddingPercent,
        );
        final viewportShortEdge = math.min(
          contentWidth,
          MediaQuery.of(context).size.height,
        );

        final doublePageSlots = _isDoublePage
            ? _buildDoublePageSlots(widget.entries)
            : const <_ColumnDoublePageSlot>[];
        final slotCount = _isDoublePage
            ? doublePageSlots.length
            : widget.entries.length;

        final listView = ListView.builder(
          padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
          physics: physics,
          itemCount: slotCount,
          itemBuilder: (ctx, index) => _itemBuilder(
            ctx,
            index,
            containerWidth,
            contentWidth,
            viewportShortEdge,
            backgroundColor,
            doublePageSlots: _isDoublePage ? doublePageSlots : null,
          ),
          cacheExtent: context.screenHeight * 2,
          controller: widget.scrollController,
        );

        return ListViewObserver(
          controller: widget.observerController,
          onObserve: (resultMap) {
            final all = resultMap.displayingChildIndexList;
            if (all.isEmpty) return;

            final int middleValue = all[all.length ~/ 2];
            if (slotCount <= 0) return;

            final clampedPageIndex = middleValue.clamp(0, slotCount - 1);
            widget.onMiddleSlotObserved?.call(clampedPageIndex);

            final cubit = context.read<ReaderCubit>();
            if (cubit.state.pageIndex != clampedPageIndex) {
              cubit.updatePageIndex(clampedPageIndex);
            }

            if (cubit.state.isMenuVisible) {
              cubit.updateMenuVisible(visible: false);
              widget.volumeController.enableInterception();
            }
          },
          child: listView,
        );
      },
    );
  }

  Widget _itemBuilder(
    BuildContext context,
    int index,
    double containerWidth,
    double imageWidth,
    double shortEdge,
    Color backgroundColor, {
    List<_ColumnDoublePageSlot>? doublePageSlots,
  }) {
    if (_isDoublePage) {
      final slot = doublePageSlots![index];
      return _buildDoublePageItem(
        context,
        slot: slot,
        containerWidth: containerWidth,
        contentWidth: imageWidth,
        shortEdge: shortEdge,
        backgroundColor: backgroundColor,
      );
    }

    final entry = widget.entries[index];
    if (entry.type == ColumnModeEntryType.transition) {
      return Container(
        color: backgroundColor,
        width: containerWidth,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: SizedBox(
          width: shortEdge,
          height: shortEdge,
          child: ChapterTransitionCard(
            previousChapterOrder: entry.previousChapterOrder,
            previousChapterTitle: entry.previousChapterTitle,
            nextChapterOrder: entry.chapterOrder,
            nextChapterTitle: entry.chapterTitle,
            transitionStatus: entry.transitionStatus,
            backgroundColor: backgroundColor,
            minHeight: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            lineSpacing: 24,
            onTap: () => widget.onTransitionAction?.call(entry.chapterOrder),
          ),
        ),
      );
    }

    return BlocSelector<ImageSizeCubit, ImageSizeState, Size>(
      selector: (state) => state.getSizeValue(index),
      builder: (itemContext, cachedSize) {
        final finalHeight = _resolveDisplayHeight(
          cachedSize: cachedSize,
          targetWidth: imageWidth,
        );

        return Container(
          color: backgroundColor,
          height: finalHeight,
          width: containerWidth,
          alignment: Alignment.center,
          child: SizedBox(
            width: imageWidth,
            height: finalHeight,
            child: _buildColumnImage(index: index, entry: entry),
          ),
        );
      },
    );
  }

  Widget _buildDoublePageItem(
    BuildContext context, {
    required _ColumnDoublePageSlot slot,
    required double containerWidth,
    required double contentWidth,
    required double shortEdge,
    required Color backgroundColor,
  }) {
    if (slot.transition != null) {
      final entry = slot.transition!.entry;
      return Container(
        color: backgroundColor,
        width: containerWidth,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: SizedBox(
          width: shortEdge,
          height: shortEdge,
          child: ChapterTransitionCard(
            previousChapterOrder: entry.previousChapterOrder,
            previousChapterTitle: entry.previousChapterTitle,
            nextChapterOrder: entry.chapterOrder,
            nextChapterTitle: entry.chapterTitle,
            transitionStatus: entry.transitionStatus,
            backgroundColor: backgroundColor,
            minHeight: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            lineSpacing: 24,
            onTap: () => widget.onTransitionAction?.call(entry.chapterOrder),
          ),
        ),
      );
    }

    const panelGap = 6.0;
    final panelWidth = ((contentWidth - panelGap) / 2).clamp(1.0, contentWidth);
    final left = slot.left;
    final right = slot.right;
    if (left == null) {
      return const SizedBox.shrink();
    }

    return BlocSelector<ImageSizeCubit, ImageSizeState, (Size, Size)>(
      selector: (state) => (
        state.getSizeValue(left.entryIndex),
        right != null ? state.getSizeValue(right.entryIndex) : const Size(0, 0),
      ),
      builder: (itemContext, pairSize) {
        final leftEntry = left.entry;
        final rightEntry = right?.entry;
        final leftHeight = _resolveDisplayHeight(
          cachedSize: pairSize.$1,
          targetWidth: panelWidth,
        );
        final rightHeight = rightEntry != null
            ? _resolveDisplayHeight(
                cachedSize: pairSize.$2,
                targetWidth: panelWidth,
              )
            : 0.0;
        final rowHeight = (leftHeight > rightHeight ? leftHeight : rightHeight)
            .clamp(1.0, double.infinity);

        return Container(
          color: backgroundColor,
          width: containerWidth,
          height: rowHeight,
          alignment: Alignment.center,
          child: SizedBox(
            width: contentWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: panelWidth,
                  height: rowHeight,
                  child: _buildColumnImage(
                    index: left.entryIndex,
                    entry: leftEntry,
                  ),
                ),
                const SizedBox(width: panelGap),
                SizedBox(
                  width: panelWidth,
                  height: rowHeight,
                  child: rightEntry != null
                      ? _buildColumnImage(
                          index: right!.entryIndex,
                          entry: rightEntry,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_ColumnDoublePageSlot> _buildDoublePageSlots(
    List<ColumnModeEntry> entries,
  ) {
    final slots = <_ColumnDoublePageSlot>[];
    var i = 0;
    while (i < entries.length) {
      final current = entries[i];
      if (current.type == ColumnModeEntryType.transition) {
        slots.add(
          _ColumnDoublePageSlot.transition(
            _ColumnSlotItem(entryIndex: i, entry: current),
          ),
        );
        i++;
        continue;
      }

      final left = _ColumnSlotItem(entryIndex: i, entry: current);
      i++;
      _ColumnSlotItem? right;
      if (i < entries.length && entries[i].type == ColumnModeEntryType.image) {
        right = _ColumnSlotItem(entryIndex: i, entry: entries[i]);
        i++;
      }
      slots.add(_ColumnDoublePageSlot.images(left: left, right: right));
    }
    return slots;
  }

  Widget _buildColumnImage({
    required int index,
    required ColumnModeEntry entry,
  }) {
    if (entry.type != ColumnModeEntryType.image ||
        entry.doc == null ||
        entry.chapterId == null) {
      return const SizedBox.shrink();
    }
    final localPageIndex = entry.chapterLocalPageIndex ?? 0;
    return ReadImageWidget(
      pictureInfo: PictureInfo(
        from: widget.from,
        url: entry.doc!.fileServer,
        path: entry.doc!.path,
        cartoonId: widget.comicId,
        chapterId: entry.chapterId!,
        pictureType: PictureType.page,
        extern: entry.doc!.extern,
      ),
      index: localPageIndex,
      cacheIndex: index,
      isColumn: true,
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
}

class _ColumnSlotItem {
  const _ColumnSlotItem({required this.entryIndex, required this.entry});

  final int entryIndex;
  final ColumnModeEntry entry;
}

class _ColumnDoublePageSlot {
  const _ColumnDoublePageSlot._({
    required this.transition,
    required this.left,
    required this.right,
  });

  const _ColumnDoublePageSlot.transition(_ColumnSlotItem transition)
    : this._(transition: transition, left: null, right: null);

  const _ColumnDoublePageSlot.images({
    required _ColumnSlotItem left,
    _ColumnSlotItem? right,
  }) : this._(transition: null, left: left, right: right);

  final _ColumnSlotItem? transition;
  final _ColumnSlotItem? left;
  final _ColumnSlotItem? right;
}
