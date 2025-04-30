import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:zephyr/page/comic_read/widgets/read_image_widget.dart';

import '../../../config/global/global.dart';
import '../../../main.dart';
import '../json/page.dart';

class ColumnModeWidget extends StatelessWidget {
  final int length;
  final List<Media> medias;
  final String comicId;
  final String epsId;
  final String chapterId;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;

  const ColumnModeWidget({
    super.key,
    required this.length,
    required this.medias,
    required this.comicId,
    required this.epsId,
    required this.chapterId,
    required this.itemScrollController,
    required this.itemPositionsListener,
  });

  @override
  Widget build(BuildContext context) {
    final listBuild =
        useSkia
            ? ScrollablePositionedList.separated
            : ScrollablePositionedList.builder;

    return listBuild(
      itemCount: length + 2,
      itemBuilder: itemBuilder,
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      separatorBuilder:
          useSkia ? Container(height: 2, color: Colors.black) : null,
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
          media: medias[index - 1],
          comicId: comicId,
          epsId: epsId,
          index: index - 1,
          chapterId: chapterId,
          isColumn: true,
        ),
      );
    }
  }
}
