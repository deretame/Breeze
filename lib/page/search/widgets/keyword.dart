import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/page/search_result/models/search_enter.dart';

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
            runSpacing: 10,
            children: List.generate(
              keywords.length,
              (index) {
                return Container(
                  decoration: BoxDecoration(
                    color: globalSetting.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: globalSetting.themeType
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.4),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  // 移除固定长度，使用内部的 Text 组件直接决定外部 Container 的大小
                  child: Padding(
                    // 添加 Padding 以使内容不贴边
                    padding: const EdgeInsets.symmetric(
                      vertical: 5.0,
                      horizontal: 10.0,
                    ), // 适当的内边距
                    child: GestureDetector(
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
                        Clipboard.setData(
                          ClipboardData(text: keywords[index]),
                        );
                        EasyLoading.showSuccess(
                          "已将${keywords[index]}复制到剪贴板",
                        );
                      },
                      child: Text(
                        keywords[index],
                        style: TextStyle(
                          fontSize: 12,
                          color: globalSetting.themeType
                              ? Colors.pink.withValues(alpha: 0.8)
                              : Colors.blue,
                        ),
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
