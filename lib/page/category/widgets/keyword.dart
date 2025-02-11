import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/page/search_result/models/search_enter.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../main.dart';
import '../../../util/router/router.gr.dart';

class KeywordWidget extends StatelessWidget {
  final List<String> keywords;

  const KeywordWidget(this.keywords, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Observer(
        builder: (context) {
          return Wrap(
            spacing: 10,
            // runSpacing: 10,
            children: List.generate(
              keywords.length,
              (index) {
                return GestureDetector(
                  onTap: () {
                    AutoRouter.of(context).push(
                      SearchResultRoute(
                        searchEnterConst: SearchEnterConst(
                          from: "bika",
                          keyword: keywords[index],
                        ),
                      ),
                    );
                  },
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: keywords[index]));
                    showSuccessToast("${keywords[index]}已复制到剪贴板");
                  },
                  child: Chip(
                    backgroundColor: globalSetting.backgroundColor, // 设置背景颜色
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // 设置圆角
                    ),
                    label: Text(
                      keywords[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: materialColorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
