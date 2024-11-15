import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/router/router.gr.dart';

@RoutePage()
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // 按钮被点击时的回调函数
            bikaSetting.deleteAuthorization(); // 调用删除授权的方法
            AutoRouter.of(context).pushAndPopUntil(
              LoginRoute(),
              predicate: (Route<dynamic> route) {
                return false;
              },
            );
          },
          child: const Text('退出登录'), // 按钮显示的文本
        ),
      ),
    );
  }
}
