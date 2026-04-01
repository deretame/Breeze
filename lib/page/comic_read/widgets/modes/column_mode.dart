import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/comic_read/controller/reader_volume_controller.dart';
import 'package:zephyr/page/comic_read/cubit/image_size_cubit.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/json/common_ep_info_json/common_ep_info_json.dart';
import 'package:zephyr/page/comic_read/widgets/image/read_image_widget.dart';
import 'package:zephyr/page/comic_read/widgets/layout/read_layout.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/widgets/picture_bloc/models/picture_info.dart';
import 'package:zephyr/type/enum.dart';

class ColumnModeWidget extends StatefulWidget {
  final int length;
  final List<Doc> docs;
  final bool enableDoublePage;
  final String comicId;
  final String epsId;
  final ListObserverController observerController;
  final ScrollController scrollController;
  final String from;
  final ScrollPhysics? parentPhysics;
  final bool disableScroll;
  final ReaderVolumeController volumeController;

  const ColumnModeWidget({
    super.key,
    required this.length,
    required this.docs,
    required this.enableDoublePage,
    required this.comicId,
    required this.epsId,
    required this.observerController,
    required this.scrollController,
    required this.from,
    this.parentPhysics,
    this.disableScroll = false,
    required this.volumeController,
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
          (GlobalSettingCubit c) => !c.state.comicReadTopContainer,
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

        Widget listView;

        Widget currentItemBuilder(BuildContext ctx, int index) {
          return _itemBuilder(
            ctx,
            index,
            containerWidth,
            contentWidth,
            backgroundColor,
          );
        }

        listView = ListView.builder(
          padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
          physics: physics,
          itemCount: widget.length,
          itemBuilder: currentItemBuilder,
          cacheExtent: context.screenHeight * 2,
          controller: widget.scrollController,
        );

        return ListViewObserver(
          controller: widget.observerController,
          onObserve: (resultMap) {
            final all = resultMap.displayingChildIndexList;
            if (all.isEmpty) return;

            final int middleValue = all[all.length ~/ 2];

            final clampedPageIndex = middleValue.clamp(0, widget.length - 1);

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
    Color backgroundColor,
  ) {
    if (_isDoublePage) {
      return _buildDoublePageItem(
        context,
        slotIndex: index,
        containerWidth: containerWidth,
        contentWidth: imageWidth,
        backgroundColor: backgroundColor,
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
            child: _buildColumnImage(index: index),
          ),
        );
      },
    );
  }

  Widget _buildDoublePageItem(
    BuildContext context, {
    required int slotIndex,
    required double containerWidth,
    required double contentWidth,
    required Color backgroundColor,
  }) {
    const panelGap = 6.0;
    final leftDocIndex = slotIndex * 2;
    final rightDocIndex = leftDocIndex + 1;
    final panelWidth = ((contentWidth - panelGap) / 2).clamp(1.0, contentWidth);

    return BlocSelector<ImageSizeCubit, ImageSizeState, (Size, Size)>(
      selector: (state) => (
        state.getSizeValue(leftDocIndex),
        rightDocIndex < widget.docs.length
            ? state.getSizeValue(rightDocIndex)
            : const Size(0, 0),
      ),
      builder: (itemContext, pairSize) {
        final leftHeight = _resolveDisplayHeight(
          cachedSize: pairSize.$1,
          targetWidth: panelWidth,
        );
        final rightHeight = rightDocIndex < widget.docs.length
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
                  child: _buildColumnImage(index: leftDocIndex),
                ),
                const SizedBox(width: panelGap),
                SizedBox(
                  width: panelWidth,
                  height: rowHeight,
                  child: rightDocIndex < widget.docs.length
                      ? _buildColumnImage(index: rightDocIndex)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildColumnImage({required int index}) {
    return ReadImageWidget(
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
