import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../config/global.dart';
import '../../../../main.dart';
import '../../../../util/router/router.gr.dart';

Widget divider() {
  return Align(
    alignment: Alignment.center,
    child: SizedBox(
      width: screenWidth * (48 / 50), // 设置宽度
      child: Divider(
        color: materialColorScheme.secondaryFixedDim,
        thickness: 1,
        height: 10,
      ),
    ),
  );
}

Widget changeThemeColor(BuildContext context) {
  final router = AutoRouter.of(context);
  return GestureDetector(
    onTap: () async {
      router.push(ThemeColorRoute());
    },
    behavior: HitTestBehavior.opaque, // 使得所有透明区域也可以响应点击
    child: Row(
      children: [
        SizedBox(width: 10),
        Text(
          "主题颜色",
          style: TextStyle(fontSize: 18),
        ),
        Expanded(child: Container()),
        Icon(Icons.chevron_right),
        SizedBox(width: 10),
      ],
    ),
  );
}

Widget webdavSync(BuildContext context) {
  final router = AutoRouter.of(context);
  return GestureDetector(
    onTap: () async {
      router.push(WebDavSyncRoute());
    },
    behavior: HitTestBehavior.opaque, // 使得所有透明区域也可以响应点击
    child: Row(
      children: [
        SizedBox(width: 10),
        Text(
          "webdav 同步",
          style: TextStyle(fontSize: 18),
        ),
        Expanded(child: Container()),
        Icon(Icons.chevron_right),
        SizedBox(width: 10),
      ],
    ),
  );
}
