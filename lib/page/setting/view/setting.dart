import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/config/global.dart';
import 'package:zephyr/util/router/router.gr.dart';

@RoutePage()
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    var router = AutoRouter.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Row(
        children: [
          SizedBox(width: 16),
          Column(
            children: [
              GestureDetector(
                onTap: () {
                  router.push(BikaSettingRoute());
                  debugPrint("哔咔设置");
                },
                behavior: HitTestBehavior.opaque, // 使得所有透明区域也可以响应点击
                child: SizedBox(
                  width: screenWidth - 16 - 16,
                  height: 35, // 设置固定高度
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
              SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  router.push(GlobalSettingRoute());
                  debugPrint("全局设置");
                },
                behavior: HitTestBehavior.opaque, // 使得所有透明区域也可以响应点击
                child: SizedBox(
                  width: screenWidth - 16 - 16,
                  height: 35, // 设置固定高度
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
            ],
          ),
          SizedBox(width: 16),
        ],
      ),
    );
  }
}
