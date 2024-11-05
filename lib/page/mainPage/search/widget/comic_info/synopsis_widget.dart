// 简介组件
import 'package:flutter/cupertino.dart';
import 'package:zephyr/main.dart';

import '../../../../../config/global.dart';
import '../../../../../json/comic/comic_info.dart';

class SynopsisWidget extends StatefulWidget {
  final ComicInfo comicInfo;

  const SynopsisWidget({super.key, required this.comicInfo});

  @override
  State<SynopsisWidget> createState() => _SynopsisWidgetState();
}

class _SynopsisWidgetState extends State<SynopsisWidget> {
  ComicInfo get comicInfo => widget.comicInfo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // 使 Row 尽可能小
      mainAxisAlignment: MainAxisAlignment.start, // 子组件之间的间距平均分布
      crossAxisAlignment: CrossAxisAlignment.start, // 子组件在交叉轴（垂直轴）上靠起始位置对齐
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center, // 设置主轴对齐为居中
          children: <Widget>[
            Expanded(
              child: Container(
                width: screenWidth * (20 / 50),
                height: 1.0,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: globalSetting.textColor,
                      width: 1.0, // 颜色条的宽度
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            const Text("描述"),
            const SizedBox(width: 5),
            Expanded(
              child: Container(
                width: screenWidth * (20 / 50),
                height: 1.0,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: globalSetting.textColor,
                      width: 1.0, // 颜色条的宽度
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Text(comicInfo.comic.description),
      ],
    );
  }
}
