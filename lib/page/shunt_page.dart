import 'package:flutter/material.dart';
import 'package:zephyr/util/router.dart';

import '../config/global.dart';

class ShuntPage extends StatelessWidget {
  const ShuntPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分流设置'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 确保垂直居中
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text(
              '请选择分流',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 10),
            Text(
              '中国大陆用户优先选择2、3分流',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 40),
              ),
              onPressed: () {
                shunt = 1;
                navigateToNoReturn(context, "/init");
              },
              child: const Text('分流1'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 40),
              ),
              onPressed: () {
                shunt = 2;
                navigateToNoReturn(context, "/init");
              },
              child: const Text('分流2'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 40),
              ),
              onPressed: () {
                shunt = 3;
                navigateToNoReturn(context, "/init");
              },
              child: const Text('分流3'),
            ),
          ],
        ),
      ),
    );
  }
}
