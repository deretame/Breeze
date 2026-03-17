import 'package:auto_route/auto_route.dart';
import 'package:zephyr/util/ui/fluent_compat.dart';

import '../../../util/router/router.gr.dart';

Widget buildCommentWidget(BuildContext context) {
  final router = AutoRouter.of(context);

  return ListTile(
    leading: const Icon(Icons.comment_outlined),
    title: const Text('我的评论'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      router.push(UserCommentsRoute());
    },
  );
}


