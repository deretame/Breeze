import 'package:auto_route/auto_route.dart';
import 'package:zephyr/plugin/plugin_constants.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/page/comments/view/plugin_comments_scaffold.dart';

@RoutePage()
class JmCommentsPage extends StatelessWidget {
  const JmCommentsPage({
    super.key,
    required this.comicId,
    required this.comicTitle,
  });

  final String comicId;
  final String comicTitle;

  @override
  Widget build(BuildContext context) {
    return PluginCommentsScaffold(
      from: kJmPluginUuid,
      comicId: comicId,
      comicTitle: comicTitle,
    );
  }
}
