import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

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
      body: const Center(child: Text('该页面已迁移到插件设置，请在首页插件卡片中打开对应插件设置。')),
    );
  }
}
