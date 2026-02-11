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

class ColumnModeWidget extends StatefulWidget {
  final int length;
  final List<Doc> docs;
  final String comicId;
  final String epsId;
  final ListObserverController observerController;
  final ScrollController scrollController;
  final From from;
  final ScrollPhysics? parentPhysics;

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
  });

  @override
  State<ColumnModeWidget> createState() => _ColumnModeWidgetState();
}

class _ColumnModeWidgetState extends State<ColumnModeWidget> {
  @override
  Widget build(BuildContext context) {
    final physics = widget.parentPhysics != null
        ? widget.parentPhysics!.applyTo(const AlwaysScrollableScrollPhysics())
        : const AlwaysScrollableScrollPhysics();

    Widget listView;

    if (useSkia) {
      // 带分隔符的版本
      listView = ListView.separated(
        physics: physics,
        itemCount: widget.length + 2,
        itemBuilder: itemBuilder,
        separatorBuilder: (_, _) => Container(height: 2, color: Colors.black),
        cacheExtent: context.screenHeight * 0.5,
        controller: widget.scrollController,
      );
    } else {
      // 不带分隔符的版本
      listView = ListView.builder(
        physics: physics,
        itemCount: widget.length + 2,
        itemBuilder: itemBuilder,
        cacheExtent: context.screenHeight * 0.5,
        controller: widget.scrollController,
      );
    }

    return ListViewObserver(
      controller: widget.observerController,
      onObserve: (resultMap) {
        final all = resultMap.displayingChildIndexList;
        if (all.isEmpty) return;

        final int middleValue = all[(all.length - 1) ~/ 2];

        final pageIndex = middleValue.clamp(1, widget.docs.length);

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
  }

  Widget itemBuilder(BuildContext context, int index) {
    final hideTop = context
        .read<GlobalSettingCubit>()
        .state
        .comicReadTopContainer;
    return BlocSelector<ImageSizeCubit, ImageSizeState, Size>(
      selector: (state) {
        return state.getSizeValue(index);
      },
      builder: (itemContext, currentSize) {
        final height = currentSize.height;
        final width = currentSize.width;
        if (index == 0) {
          return Container(
            width: width,
            height: hideTop ? 0 : context.statusBarHeight,
            color: Colors.black,
          );
        } else if (index == widget.length + 1) {
          return Container(
            height: height,
            width: width,
            alignment: Alignment.center,
            color: Colors.black,
            child: const Text(
              "章节结束",
              style: TextStyle(fontSize: 20, color: Color(0xFFCCCCCC)),
            ),
          );
        } else {
          return Container(
            color: Colors.black,
            height: height,
            width: width,
            child: ReadImageWidget(
              pictureInfo: PictureInfo(
                from: widget.from.toString().split('.').last,
                url: widget.docs[index - 1].fileServer,
                path: widget.docs[index - 1].path,
                cartoonId: widget.comicId,
                chapterId: widget.epsId,
                pictureType: 'comic',
              ),
              index: index - 1,
              isColumn: true,
            ),
          );
        }
      },
    );
  }
}
