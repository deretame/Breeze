import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:zephyr/page/comic_read/widgets/read_image_widget.dart';

import '../../../config/global/global.dart';
import '../../../main.dart';
import '../json/common_ep_info_json/common_ep_info_json.dart';

class ColumnModeWidget extends StatelessWidget {
  final int length;
  final List<Doc> docs;
  final String comicId;
  final String epsId;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;

  const ColumnModeWidget({
    super.key,
    required this.length,
    required this.docs,
    required this.comicId,
    required this.epsId,
    required this.itemScrollController,
    required this.itemPositionsListener,
  });

  @override
  Widget build(BuildContext context) {
    return useSkia
        ? ScrollablePositionedList.separated(
          // 带分隔符的版本
          itemCount: length + 2,
          itemBuilder: itemBuilder,
          separatorBuilder:
              (_, __) => Container(height: 2, color: Colors.black),
          itemScrollController: itemScrollController,
          itemPositionsListener: itemPositionsListener,
        )
        : ScrollablePositionedList.builder(
          // 不带分隔符的版本
          itemCount: length + 2,
          itemBuilder: itemBuilder,
          itemScrollController: itemScrollController,
          itemPositionsListener: itemPositionsListener,
        );
  }

  Widget itemBuilder(BuildContext context, int index) {
    if (index == 0) {
      return Container(
        width: screenWidth,
        height: globalSetting.comicReadTopContainer ? statusBarHeight : 0,
        color: Colors.black,
      );
    } else if (index == length + 1) {
      return Container(
        height: 75,
        width: screenWidth,
        alignment: Alignment.center,
        color: Colors.black,
        child: Text(
          "章节结束",
          style: TextStyle(fontSize: 20, color: Color(0xFFCCCCCC)),
        ),
      );
    } else {
      return Container(
        color: Colors.black,
        child: ReadImageWidget(
          doc: docs[index - 1],
          comicId: comicId,
          epsId: epsId,
          index: index - 1,
          isColumn: true,
        ),
      );
    }
  }
}
