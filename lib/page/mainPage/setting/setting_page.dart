import 'package:flutter/material.dart';

import '../../../config/authorization.dart';
import '../../../util/router.dart';

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
            deleteAuthorization(); // 调用删除授权的方法
            navigateToLogin(context);
          },
          child: const Text('退出登录'), // 按钮显示的文本
        ),
      ),
    );
  }
}
