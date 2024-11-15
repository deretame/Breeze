import 'package:flutter/cupertino.dart';

import '../../../config/global.dart';
import '../../../main.dart';
import '../json/comic_info/comic_info.dart';

// 描述，或者说介绍？我不太清楚这玩意儿到底怎么分类
class SynopsisWidget extends StatelessWidget {
  final Comic comicInfo;

  const SynopsisWidget({super.key, required this.comicInfo});

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
        Text(comicInfo.description),
      ],
    );
  }
}
