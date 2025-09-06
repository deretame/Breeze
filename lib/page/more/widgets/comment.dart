import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../util/router/router.gr.dart';

Widget buildCommentWidget(BuildContext context) {
  final router = AutoRouter.of(context);

  return GestureDetector(
    onTap: () {
      router.push(UserCommentsRoute());
    },
    behavior: HitTestBehavior.opaque,
    child: Row(
      children: [
        SizedBox(width: 6),
        Expanded(
          child: SizedBox(
            height: 40,
            child: Row(
              children: [
                Icon(Icons.comment),
                SizedBox(width: 10),
                Text("我的评论", style: TextStyle(fontSize: 22)),
                Spacer(),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
