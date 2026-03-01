import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/comic_read/cubit/image_size_cubit.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/widgets/read_image_widget.dart';
import 'package:zephyr/util/context/context_extensions.dart';

import '../../../config/global/global.dart';
import '../../../type/enum.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';
import '../json/common_ep_info_json/common_ep_info_json.dart';

double getConstrainedImageWidth(double containerWidth) {
  bool isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  if (!isDesktop) return containerWidth;
  final double target = math.max(containerWidth * 0.6, 600.0);
  return math.min(containerWidth, target);
}

class ColumnModeWidget extends StatefulWidget {
  final int length;
  final List<Doc> docs;
  final String comicId;
  final String epsId;
  final ListObserverController observerController;
  final ScrollController scrollController;
  final From from;
  final ScrollPhysics? parentPhysics;
  final bool disableScroll;

  const ColumnModeWidget({
    super.key,
    required this.length,
    required this.docs,
    required this.comicId,
    required this.epsId,
    required this.observerController,
    required this.scrollController,
    required this.from,
    this.parentPhysics,
    this.disableScroll = false,
  });

  @override
  State<ColumnModeWidget> createState() => _ColumnModeWidgetState();
}

class _ColumnModeWidgetState extends State<ColumnModeWidget> {
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
          (GlobalSettingCubit c) => !c.state.comicReadTopContainer,
        );
        final mediaQuery = MediaQuery.of(context);
        final topInset = mediaQuery.padding.top > 0
            ? mediaQuery.padding.top
            : mediaQuery.viewPadding.top;
        final bottomInset = mediaQuery.padding.bottom > 0
            ? mediaQuery.padding.bottom
            : mediaQuery.viewPadding.bottom;

        final double topPadding = hideTop ? 0 : topInset;
        final double bottomPadding = bottomInset + 50;

        final containerWidth = constraints.maxWidth;
        final imageWidth = getConstrainedImageWidth(containerWidth);

        Widget listView;

        Widget currentItemBuilder(BuildContext ctx, int index) {
          return _itemBuilder(ctx, index, containerWidth, imageWidth);
        }

        if (useSkia) {
          listView = ListView.separated(
            padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
            physics: physics,
            itemCount: widget.length,
            itemBuilder: currentItemBuilder,
            separatorBuilder: (_, _) =>
                Container(height: 2, color: Colors.black),
            cacheExtent: context.screenHeight * 2,
            controller: widget.scrollController,
          );
        } else {
          listView = ListView.builder(
            padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
            physics: physics,
            itemCount: widget.length,
            itemBuilder: currentItemBuilder,
            cacheExtent: context.screenHeight * 2,
            controller: widget.scrollController,
          );
        }

        return ListViewObserver(
          controller: widget.observerController,
          onObserve: (resultMap) {
            final all = resultMap.displayingChildIndexList;
            if (all.isEmpty) return;

            var visibleIndices = List<int>.from(all);

            for (int i = 1; i <= 5; i++) {
              int prevIndex = all.first - i;
              if (prevIndex >= 0) {
                visibleIndices.insert(0, prevIndex);
              } else {
                break;
              }
            }

            for (int i = 1; i <= 5; i++) {
              int nextIndex = all.last + i;
              if (nextIndex < widget.length) {
                visibleIndices.add(nextIndex);
              } else {
                break;
              }
            }

            context.read<ImageSizeCubit>().updateVisibleIndices(visibleIndices);

            final int middleValue = all[(all.length - 1) ~/ 2];

            final pageIndex = middleValue.clamp(0, widget.docs.length - 1);

            final cubit = context.read<ReaderCubit>();
            if (cubit.state.pageIndex != pageIndex) {
              cubit.updatePageIndex(pageIndex);
            }

            if (cubit.state.isMenuVisible) {
              cubit.updateMenuVisible(visible: false);
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
  ) {
    return BlocSelector<ImageSizeCubit, ImageSizeState, Size>(
      selector: (state) {
        return state.getSizeValue(index);
      },
      builder: (itemContext, cachedSize) {
        double finalHeight;
        double finalWidth = containerWidth;

        if ((cachedSize.width - imageWidth).abs() < 0.1) {
          finalHeight = cachedSize.height;
        } else {
          if (cachedSize.width > 0 && cachedSize.height > 0) {
            final aspectRatio = cachedSize.height / cachedSize.width;
            finalHeight = imageWidth * aspectRatio;
          } else {
            finalHeight = cachedSize.height;
          }
        }

        return Container(
          color: Colors.black,
          height: finalHeight,
          width: finalWidth,
          alignment: Alignment.center,
          child: SizedBox(
            width: imageWidth,
            height: finalHeight,
            child: BlocSelector<ImageSizeCubit, ImageSizeState, bool>(
              selector: (state) => state.visibleIndices.contains(index),
              builder: (context, isVisible) {
                return ReadImageWidget(
                  isVisible: isVisible,
                  pictureInfo: PictureInfo(
                    from: widget.from,
                    url: widget.docs[index].fileServer,
                    path: widget.docs[index].path,
                    cartoonId: widget.comicId,
                    chapterId: widget.epsId,
                    pictureType: PictureType.comic,
                  ),
                  index: index,
                  isColumn: true,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
