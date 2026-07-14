import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_read/bloc/page_bloc.dart';

class ComicErrorWidget extends StatelessWidget {
  final PageState state;
  final PageEvent event;

  const ComicErrorWidget({super.key, required this.state, required this.event});

  @override
  Widget build(BuildContext context) {
    logger.d(state.errorMessage);
    if (state.errorMessage.toLowerCase().contains("no element")) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(t.reader.chapterNotDownloaded, style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: Text(t.common.back),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              t.reader.loadFailedWithResult(
                result: state.errorMessage.toString(),
              ),
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => context.read<PageBloc>().add(event),
              child: Text(t.common.retry),
            ),
          ],
        ),
      );
    }
  }
}
