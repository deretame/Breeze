import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
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
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 10),
                    Text("哔咔设置", style: TextStyle(fontSize: 22))
                  ],
                ),
                onTap: () {
                  router.push(BikaSettingRoute());
                  debugPrint("哔咔设置");
                },
              ),
              // SizedBox(height: 10),
              // GestureDetector(
              //   child: Row(
              //     children: [
              //       Icon(Icons.settings),
              //       SizedBox(width: 10),
              //       Text("全局设置", style: TextStyle(fontSize: 22)),
              //     ],
              //   ),
              //   onTap: () {
              //     router.push(GlobalSettingRoute());
              //     debugPrint("全局设置");
              //   },
              // ),
            ],
          ),
        ],
      ),
    );
  }
}
