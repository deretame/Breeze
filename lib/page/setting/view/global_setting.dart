import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';

@RoutePage()
class GlobalSettingPage extends StatelessWidget {
  const GlobalSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('全局设置'),
      ),
      body: Container(),
    );
  }
}
