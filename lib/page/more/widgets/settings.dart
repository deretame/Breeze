import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../config/global/global.dart';
import '../../../util/router/router.gr.dart';

Widget settings(BuildContext context) {
  return Row(
    children: [
      SizedBox(width: 16),
      Column(
        children: [
          GestureDetector(
            onTap: () => context.pushRoute(GlobalSettingRoute()),
            behavior: HitTestBehavior.opaque, // 使得所有透明区域也可以响应点击
            child: SizedBox(
              width: screenWidth - 16 - 16,
              height: 40, // 设置固定高度
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 10),
                  Text("全局设置", style: TextStyle(fontSize: 22)),
                  Spacer(), // 填充剩余空间，但不影响点击
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.pushRoute(AboutRoute()),
            behavior: HitTestBehavior.opaque, // 使得所有透明区域也可以响应点击
            child: SizedBox(
              width: screenWidth - 16 - 16,
              height: 40, // 设置固定高度
              child: Row(
                children: [
                  Icon(Icons.info),
                  SizedBox(width: 10),
                  Text("关于", style: TextStyle(fontSize: 22)),
                  Spacer(), // 填充剩余空间，但不影响点击
                ],
              ),
            ),
          ),
        ],
      ),
      SizedBox(width: 16),
    ],
  );
}
