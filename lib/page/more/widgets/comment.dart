import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../config/global.dart';
import '../../../util/router/router.gr.dart';

Widget buildCommentWidget(BuildContext context) {
  final router = AutoRouter.of(context);

  return GestureDetector(
    onTap: () {
      router.push(UserCommentsRoute());
      debugPrint("全局设置");
    },
    behavior: HitTestBehavior.opaque, // 使得所有透明区域也可以响应点击
    child: Row(
      children: [
        SizedBox(width: 6),
        SizedBox(
          width: screenWidth - 34,
          height: 40, // 设置固定高度
          child: Row(
            children: [
              Icon(Icons.comment),
              SizedBox(width: 10),
              Text("我的评论", style: TextStyle(fontSize: 22)),
              Spacer(), // 填充剩余空间，但不影响点击
            ],
          ),
        ),
      ],
    ),
  );
}
