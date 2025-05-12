import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/more/more.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [
      BikaUserInfoWidget(),
      Delimiter(),
      // TODO:这里需要添加JM的设置，以及登录什么之类的玩意儿
      settings(context),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('更多')),
      body: RefreshIndicator(
        onRefresh: () async {
          eventBus.fire(RefreshEvent());
        },
        child: ListView.builder(
          itemCount: widgets.length,
          itemBuilder: (context, index) {
            return widgets[index];
          },
        ),
      ),
    );
  }
}
