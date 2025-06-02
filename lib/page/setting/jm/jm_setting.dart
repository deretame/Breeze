import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/router/router.gr.dart';

@RoutePage()
class JMSettingPage extends StatefulWidget {
  const JMSettingPage({super.key});

  @override
  State<JMSettingPage> createState() => _JMSettingPageState();
}

class _JMSettingPageState extends State<JMSettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('禁漫设置')),
      body: Column(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                jmSetting.deleteUserInfo();
                jmSetting.setLoginStatus(LoginStatus.logout);
                context.pushRoute(LoginRoute(from: From.jm));
              },
              child: Text("退出登录"),
            ),
          ),
        ],
      ),
    );
  }
}
