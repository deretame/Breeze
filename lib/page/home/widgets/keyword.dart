import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zephyr/page/search_result/models/search_enter.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/sundry.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../util/router/router.gr.dart';

class KeywordWidget extends StatelessWidget {
  final List<String> keywords;

  const KeywordWidget(this.keywords, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Wrap(
        spacing: 10,
        // runSpacing: 10,
        children: List.generate(keywords.length, (index) {
          return GestureDetector(
            onTap: () {
              context.pushRoute(
                SearchResultRoute(
                  searchEnter: SearchEnter.initial().copyWith(
                    from: "bika",
                    keyword: keywords[index],
                  ),
                ),
              );
            },
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: keywords[index]));
              showSuccessToast("${keywords[index].let(t2s)}已复制到剪贴板");
            },
            child: Chip(
              backgroundColor: context.backgroundColor, // 设置背景颜色
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // 设置圆角
              ),
              label: Text(
                keywords[index].let(t2s),
                style: TextStyle(
                  fontSize: 12,
                  color: context.theme.colorScheme.primary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
