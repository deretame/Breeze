import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_read/widgets/read_image_widget.dart';

import '../../../type/enum.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';
import '../json/common_ep_info_json/common_ep_info_json.dart';

class RowModeWidget extends StatefulWidget {
  final List<Doc> docs;
  final String comicId;
  final String epsId;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final bool isSliderRolling;
  final From from;

  const RowModeWidget({
    super.key,
    required this.docs,
    required this.comicId,
    required this.epsId,
    required this.pageController,
    required this.onPageChanged,
    required this.isSliderRolling,
    required this.from,
  });

  @override
  State<RowModeWidget> createState() => _RowModeWidgetState();
}

class _RowModeWidgetState extends State<RowModeWidget> {
  Timer? _timer;

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
    return PageView.custom(
      reverse: globalSetting.readMode != 1,
      controller: widget.pageController,
      onPageChanged: (page) {
        if (widget.isSliderRolling) {
          // 如果 isSliderRolling 为真，重置定时器
          _timer?.cancel(); // 取消之前的定时器
          _timer = Timer(Duration(milliseconds: 100), () {
            // 400 毫秒后触发 onPageChanged
            widget.onPageChanged(page);
          });
        } else {
          // 如果 isSliderRolling 为假，直接触发 onPageChanged
          widget.onPageChanged(page);
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
        addAutomaticKeepAlives: true, // 保持页面状态，以便预加载
        addRepaintBoundaries: true, // 为每个孩子添加重绘边界，有助于性能
      ),
      scrollDirection: Axis.horizontal,
      physics: const PageScrollPhysics(),
      // 可以根据需要自定义物理效果
      pageSnapping: true,
      allowImplicitScrolling: true,
      // 允许隐式滚动，有助于预加载
      restorationId: null,
      // 根据需要设置
      clipBehavior: Clip.none,
      hitTestBehavior: HitTestBehavior.opaque,
      scrollBehavior: const MaterialScrollBehavior(),
      // 根据需要设置
      padEnds: true,
    );
  }
}
