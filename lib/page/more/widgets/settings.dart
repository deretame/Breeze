import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../config/global.dart';
import '../../../main.dart';
import '../../../util/router/router.gr.dart';

Widget settings(BuildContext context) {
  final router = AutoRouter.of(context);

  return Row(
    children: [
      SizedBox(width: 16),
      Column(
        children: [
          // SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              router.push(BikaSettingRoute());
              logger.d("哔咔设置");
            },
            behavior: HitTestBehavior.opaque, // 使得所有透明区域也可以响应点击
            child: SizedBox(
              width: screenWidth - 16 - 16,
              height: 40, // 设置固定高度
              child: Row(
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 10),
                  Text("哔咔设置", style: TextStyle(fontSize: 22)),
                  Spacer(), // 填充剩余空间，但不影响点击
                ],
              ),
            ),
          ),
          SizedBox(height: 15),
          GestureDetector(
            onTap: () {
              router.push(GlobalSettingRoute());
              logger.d("全局设置");
            },
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
          SizedBox(height: 15),
          GestureDetector(
            onTap: () {
              router.push(AboutRoute());
              logger.d("关于");
            },
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
