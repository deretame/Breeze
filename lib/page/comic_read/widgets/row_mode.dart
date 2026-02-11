import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/method/jump_chapter.dart';
import 'package:zephyr/page/comic_read/widgets/button_dialog.dart';
import 'package:zephyr/page/comic_read/widgets/read_image_widget.dart';
import 'package:zephyr/util/context/context_extensions.dart';

import '../../../type/enum.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';
import '../json/common_ep_info_json/common_ep_info_json.dart';

class RowModeWidget extends StatefulWidget {
  final List<Doc> docs;
  final String comicId;
  final String epsId;
  final PageController pageController;
  final From from;
  final JumpChapter jumpChapter;

  const RowModeWidget({
    super.key,
    required this.docs,
    required this.comicId,
    required this.epsId,
    required this.pageController,
    required this.from,
    required this.jumpChapter,
  });

  @override
  State<RowModeWidget> createState() => _RowModeWidgetState();
}

class _RowModeWidgetState extends State<RowModeWidget> {
  Timer? _timer;

  bool isJumping = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final jumpChapter = widget.jumpChapter;
    const offset = 4;

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        // logger.d("isJumping: $isJumping");

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
        physics: const BouncingScrollPhysics(),
        reverse: globalSettingState.readMode != 1,
        controller: widget.pageController,
        onPageChanged: (page) {
          logger.d("page: $page");
          if (context.read<ReaderCubit>().state.isSliderRolling) {
            _timer?.cancel();
            _timer = Timer(Duration(milliseconds: 100), () {
              _onPageChanged(page);
            });
          } else {
            _onPageChanged(page);
          }
        },
        childrenDelegate: SliverChildBuilderDelegate(
          (context, index) {
            return Container(
              color: Colors.black,
              child: ReadImageWidget(
                pictureInfo: PictureInfo(
                  from: widget.from.toString().split('.').last,
                  url: widget.docs[index].fileServer,
                  path: widget.docs[index].path,
                  cartoonId: widget.comicId,
                  chapterId: widget.epsId,
                  pictureType: 'comic',
                ),
                index: index,
                isColumn: false,
              ),
            );
          },
          childCount: widget.docs.length,
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
    cubit.updatePageIndex(page + 1);
    if (!cubit.state.isComicRolling) {
      // 确保 clamp 的最大值不小于最小值，避免 Invalid argument 错误
      final maxSlot = (cubit.state.totalSlots - 1).clamp(
        0,
        double.maxFinite.toInt(),
      );
      cubit.updateSliderChanged(
        (cubit.state.pageIndex).clamp(0, maxSlot).toDouble() - 1,
      );
      cubit.updateMenuVisible(visible: false);
    }
  }
}
