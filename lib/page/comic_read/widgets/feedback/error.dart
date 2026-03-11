import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_read/bloc/page_bloc.dart';

class ComicErrorWidget extends StatelessWidget {
  final PageState state;
  final PageEvent event;

  const ComicErrorWidget({super.key, required this.state, required this.event});

  @override
  Widget build(BuildContext context) {
    logger.d(state.result);
    if (state.result.toLowerCase().contains("no element")) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('章节未下载', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            ElevatedButton(onPressed: () => context.pop(), child: Text('返回')),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${state.result.toString()}\n加载失败',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => context.read<PageBloc>().add(event),
              child: Text('点击重试'),
            ),
          ],
        ),
      );
    }
  }
}
