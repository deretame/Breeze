import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_read/controller/reader_volume_controller.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/method/jump_chapter.dart';
import 'package:zephyr/page/comic_read/widgets/button_dialog.dart';
import 'package:zephyr/page/comic_read/widgets/read_image_widget.dart';
import 'package:zephyr/util/context/context_extensions.dart';

import '../../../type/enum.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';
import '../json/common_ep_info_json/common_ep_info_json.dart';
import 'read_layout.dart';

class RowModeWidget extends StatefulWidget {
  final List<Doc> docs;
  final String comicId;
  final String epsId;
  final PageController pageController;
  final ScrollPhysics scrollPhysics;
  final VoidCallback? onPageDragStart;
  final From from;
  final JumpChapter jumpChapter;
  final ReaderVolumeController volumeController;

  const RowModeWidget({
    super.key,
    required this.docs,
    required this.comicId,
    required this.epsId,
    required this.pageController,
    this.scrollPhysics = const BouncingScrollPhysics(),
    this.onPageDragStart,
    required this.from,
    required this.jumpChapter,
    required this.volumeController,
  });

  @override
  State<RowModeWidget> createState() => _RowModeWidgetState();
}

class _RowModeWidgetState extends State<RowModeWidget> {
  Timer? _pageChangedTimer;

  bool isJumping = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageChangedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final readMode = globalSettingState.readMode;
    final readSetting = globalSettingState.readSetting;
    final isDoublePage = readSetting.doublePageMode;
    final slotCount = getReadModeSlotCount(
      imageCount: widget.docs.length,
      enableDoublePage: isDoublePage,
    );
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
          logger.d("👋 检测到在第一页尝试获取【上一话】 (Overscroll Start)");
          buttonDialog(context, '跳转', '是否要跳转到上一章？').then((value) {
            if (value && context.mounted) {
              jumpChapter.jumpToChapter(context, true);
            }
            isJumping = false;
          });
        }

        void jumpToNext() {
          isJumping = true;
          logger.d("🛑 检测到在最后一页尝试获取【下一话】 (Overscroll End)");
          buttonDialog(context, '跳转', '是否要跳转到下一章？').then((value) {
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
                jumpChapter.havePrev) {
              jumpToPrev();
            }
          }

          if (currentPixels > maxPixels) {
            if (currentPixels > maxPixels + context.screenWidth / offset &&
                jumpChapter.haveNext) {
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
            _pageChangedTimer = Timer(Duration(milliseconds: 100), () {
              _onPageChanged(page, isDoublePage);
            });
          } else {
            _onPageChanged(page, isDoublePage);
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
                  slotIndex: index,
                  pageWidth: pageWidth,
                  contentWidth: contentWidth,
                  backgroundColor: backgroundColor,
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

  void _onPageChanged(int page, bool isDoublePage) {
    final cubit = context.read<ReaderCubit>();
    cubit.updatePageIndex(page);
    if (!cubit.state.isComicRolling) {
      // 确保 clamp 的最大值不小于最小值，避免 Invalid argument 错误
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
    return Container(
      color: backgroundColor,
      width: pageWidth,
      alignment: Alignment.center,
      child: SizedBox(
        width: contentWidth,
        child: _buildReadImage(docIndex: index, slotIndex: index),
      ),
    );
  }

  Widget _buildDoublePage({
    required int slotIndex,
    required double pageWidth,
    required double contentWidth,
    required Color backgroundColor,
  }) {
    const double panelGap = 6;
    final panelWidth = ((contentWidth - panelGap) / 2).clamp(1.0, contentWidth);
    final leftDocIndex = slotIndex * 2;
    final rightDocIndex = leftDocIndex + 1;

    return Container(
      color: backgroundColor,
      width: pageWidth,
      alignment: Alignment.center,
      child: SizedBox(
        width: contentWidth,
        child: Row(
          children: [
            SizedBox(
              width: panelWidth,
              child: _buildReadImage(
                docIndex: leftDocIndex,
                slotIndex: slotIndex,
              ),
            ),
            const SizedBox(width: panelGap),
            SizedBox(
              width: panelWidth,
              child: rightDocIndex < widget.docs.length
                  ? _buildReadImage(
                      docIndex: rightDocIndex,
                      slotIndex: slotIndex,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadImage({required int docIndex, required int slotIndex}) {
    return ReadImageWidget(
      pictureInfo: PictureInfo(
        from: widget.from,
        url: widget.docs[docIndex].fileServer,
        path: widget.docs[docIndex].path,
        cartoonId: widget.comicId,
        chapterId: widget.epsId,
        pictureType: PictureType.comic,
      ),
      index: slotIndex,
      isColumn: false,
    );
  }
}
