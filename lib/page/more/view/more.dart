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
