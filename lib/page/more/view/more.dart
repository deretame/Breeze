import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/more/more.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('更多')),
      body: RefreshIndicator(
        onRefresh: () async {
          eventBus.fire(RefreshEvent());
        },
        child: ListView.builder(
          itemCount: 2, // 这里固定为2，因为你有两个widget要显示
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                constraints: BoxConstraints(minHeight: 155),
                child: BikaUserInfoWidget(),
              );
            } else {
              return settings(context);
            }
          },
        ),
      ),
    );
  }
}
