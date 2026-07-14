import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_read/controller/reader_volume_controller.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/method/jump_chapter.dart';
import 'package:zephyr/page/comic_read/widgets/dialogs/button_dialog.dart';
import 'package:zephyr/page/comic_read/widgets/image/read_image_widget.dart';
import 'package:zephyr/page/comic_read/widgets/layout/read_layout.dart';
import 'package:zephyr/page/comic_read/widgets/modes/read_mode_utils.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/widgets/picture_bloc/models/picture_info.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/i18n/strings.g.dart';

class RowModeWidget extends StatefulWidget {
  final List<RowModeEntry> entries;
  final String comicId;
  final PageController pageController;
  final ScrollPhysics scrollPhysics;
  final VoidCallback? onPageDragStart;
  final String from;
  final JumpChapter jumpChapter;
  final ReaderVolumeController volumeController;
  final bool havePrev;
  final bool haveNext;
  final ValueChanged<int>? onSlotChanged;
  final Future<void> Function()? onEdgePrevious;
  final Future<void> Function()? onEdgeNext;
  final ValueChanged<int>? onTransitionAction;

  const RowModeWidget({
    super.key,
    required this.entries,
    required this.comicId,
    required this.pageController,
    this.scrollPhysics = const BouncingScrollPhysics(),
    this.onPageDragStart,
    required this.from,
    required this.jumpChapter,
    required this.volumeController,
    required this.havePrev,
    required this.haveNext,
    this.onSlotChanged,
    this.onEdgePrevious,
    this.onEdgeNext,
    this.onTransitionAction,
  });

  @override
  State<RowModeWidget> createState() => _RowModeWidgetState();
}

class _RowModeWidgetState extends State<RowModeWidget> {
  Timer? _pageChangedTimer;
  bool isJumping = false;

  @override
  void dispose() {
    _pageChangedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final readMode = globalSettingState.readSetting.readMode;
    final readSetting = globalSettingState.readSetting;
    final isDoublePage = readSetting.doublePageMode;
    final doublePageSlots = isDoublePage
        ? _buildDoublePageSlots(widget.entries)
        : const <ReadModeDoublePageSlot>[];
    final slotCount = isDoublePage
        ? doublePageSlots.length
        : widget.entries.length;
    final backgroundColor = readSetting.resolveReaderBackgroundColor(
      Theme.of(context).brightness,
    );
    final jumpChapter = widget.jumpChapter;
    const offset = 4;

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollStartNotification &&
            notification.dragDetails != null) {
          widget.onPageDragStart?.call();
        }

        void jumpToPrev() {
          isJumping = true;
          if (widget.onEdgePrevious != null) {
            widget.onEdgePrevious!().whenComplete(() {
              isJumping = false;
            });
            return;
          }
          logger.d("👋 检测到在第一页尝试获取【上一话】 (Overscroll Start)");
          buttonDialog(
            context,
            t.reader.jumpToChapterTitle,
            t.reader.jumpToChapterMessage(chapter: t.reader.previousChapter),
          ).then((value) {
            if (value && context.mounted) {
              jumpChapter.jumpToChapter(context, true);
            }
            isJumping = false;
          });
        }

        void jumpToNext() {
          isJumping = true;
          if (widget.onEdgeNext != null) {
            widget.onEdgeNext!().whenComplete(() {
              isJumping = false;
            });
            return;
          }
          logger.d("🛑 检测到在最后一页尝试获取【下一话】 (Overscroll End)");
          buttonDialog(
            context,
            t.reader.jumpToChapterTitle,
            t.reader.jumpToChapterMessage(chapter: t.reader.nextChapter),
          ).then((value) {
            if (value && context.mounted) {
              jumpChapter.jumpToChapter(context, false);
            }
            isJumping = false;
          });
        }

        if (notification is ScrollUpdateNotification && !isJumping) {
          final metrics = notification.metrics;
          final currentPixels = metrics.pixels;
          final maxPixels = metrics.maxScrollExtent;

          if (currentPixels < 0) {
            if (currentPixels < -context.screenWidth / offset &&
                widget.havePrev) {
              jumpToPrev();
            }
          }

          if (currentPixels > maxPixels) {
            if (currentPixels > maxPixels + context.screenWidth / offset &&
                widget.haveNext) {
              jumpToNext();
            }
          }
        }

        return false;
      },
      child: PageView.custom(
        physics: widget.scrollPhysics,
        reverse: isReverseRowReadMode(readMode),
        controller: widget.pageController,
        onPageChanged: (page) {
          if (context.read<ReaderCubit>().state.isSliderRolling) {
            _pageChangedTimer?.cancel();
            _pageChangedTimer = Timer(const Duration(milliseconds: 100), () {
              _onPageChanged(page);
            });
          } else {
            _onPageChanged(page);
          }
        },
        childrenDelegate: SliverChildBuilderDelegate(
          (context, index) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final pageWidth = constraints.maxWidth;
                final contentWidth = getConstrainedImageWidth(
                  containerWidth: pageWidth,
                  enableSidePadding: readSetting.sidePaddingEnabled,
                  sidePaddingPercent: readSetting.sidePaddingPercent,
                );

                if (!isDoublePage) {
                  return _buildSinglePage(
                    index: index,
                    pageWidth: pageWidth,
                    contentWidth: contentWidth,
                    backgroundColor: backgroundColor,
                  );
                }

                return _buildDoublePage(
                  slot: doublePageSlots[index],
                  slotIndex: index,
                  pageWidth: pageWidth,
                  contentWidth: contentWidth,
                  backgroundColor: backgroundColor,
                  isRtl: isReverseRowReadMode(readMode),
                );
              },
            );
          },
          childCount: slotCount,
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
        ),
        scrollDirection: Axis.horizontal,
        pageSnapping: true,
        allowImplicitScrolling: true,
        restorationId: null,
        clipBehavior: Clip.none,
        hitTestBehavior: HitTestBehavior.opaque,
        scrollBehavior: const MaterialScrollBehavior(),
        padEnds: true,
      ),
    );
  }

  void _onPageChanged(int page) {
    final cubit = context.read<ReaderCubit>();
    cubit.updatePageIndex(page);
    widget.onSlotChanged?.call(page);
    if (!cubit.state.isComicRolling) {
      final maxIndex = (cubit.state.totalSlots - 1).clamp(
        0,
        double.maxFinite.toInt(),
      );
      cubit.updateSliderChanged(
        (cubit.state.pageIndex).clamp(0, maxIndex).toDouble(),
      );
      cubit.updateMenuVisible(visible: false);
      widget.volumeController.enableInterception();
    }
  }

  Widget _buildSinglePage({
    required int index,
    required double pageWidth,
    required double contentWidth,
    required Color backgroundColor,
  }) {
    final entry = widget.entries[index];
    if (entry.type == ReadModeEntryType.transition) {
      return buildReadModeTransitionItem(
        entry: entry,
        backgroundColor: backgroundColor,
        onTap: () => widget.onTransitionAction?.call(entry.chapterOrder),
        containerWidth: pageWidth,
      );
    }

    return Container(
      color: backgroundColor,
      width: pageWidth,
      alignment: Alignment.center,
      child: SizedBox(
        width: contentWidth,
        child: _buildReadImage(
          slotItem: ReadModeSlotItem(entryIndex: index, entry: entry),
          slotIndex: index,
        ),
      ),
    );
  }

  Widget _buildDoublePage({
    required ReadModeDoublePageSlot slot,
    required int slotIndex,
    required double pageWidth,
    required double contentWidth,
    required Color backgroundColor,
    required bool isRtl,
  }) {
    if (slot.transition != null) {
      final transition = slot.transition!.entry;
      return buildReadModeTransitionItem(
        entry: transition,
        backgroundColor: backgroundColor,
        onTap: () => widget.onTransitionAction?.call(transition.chapterOrder),
        containerWidth: pageWidth,
      );
    }

    final panelWidth = ((contentWidth - kDoublePageGap) / 2).clamp(
      1.0,
      contentWidth,
    );

    final leftChild = SizedBox(
      width: panelWidth,
      child: slot.left != null
          ? _buildReadImage(slotItem: slot.left!, slotIndex: slotIndex)
          : const SizedBox.shrink(),
    );
    final rightChild = SizedBox(
      width: panelWidth,
      child: slot.right != null
          ? _buildReadImage(slotItem: slot.right!, slotIndex: slotIndex)
          : const SizedBox.shrink(),
    );

    final children = isRtl
        ? [rightChild, const SizedBox(width: kDoublePageGap), leftChild]
        : [leftChild, const SizedBox(width: kDoublePageGap), rightChild];

    return Container(
      color: backgroundColor,
      width: pageWidth,
      alignment: Alignment.center,
      child: SizedBox(
        width: contentWidth,
        child: Row(children: children),
      ),
    );
  }

  Widget _buildReadImage({
    required ReadModeSlotItem slotItem,
    required int slotIndex,
  }) {
    final entry = slotItem.entry;
    if (entry.type != ReadModeEntryType.image ||
        entry.doc == null ||
        entry.chapterId == null) {
      return const SizedBox.shrink();
    }

    final chapterLocalPageIndex = entry.chapterLocalPageIndex ?? 0;
    final resolvedChapterId = entry.doc!.storageChapterId.trim().isNotEmpty
        ? entry.doc!.storageChapterId
        : entry.chapterId!;
    return ReadImageWidget(
      pictureInfo: PictureInfo(
        from: widget.from,
        url: entry.doc!.fileServer,
        path: entry.doc!.path,
        cartoonId: widget.comicId,
        chapterId: resolvedChapterId,
        pictureType: PictureType.page,
        extern: entry.doc!.extern,
      ),
      index: slotIndex,
      cacheIndex: slotItem.entryIndex,
      displayNumber: chapterLocalPageIndex + 1,
      isColumn: false,
    );
  }

  List<ReadModeDoublePageSlot> _buildDoublePageSlots(
    List<RowModeEntry> entries,
  ) {
    return buildReadModeDoublePageSlots(entries);
  }
}
