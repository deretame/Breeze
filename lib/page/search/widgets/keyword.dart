import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
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
      child: Wrap(
        spacing: 10,
        runSpacing: 5,
        children: List.generate(
          keywords.length,
          (index) {
            return ElevatedButton(
              onPressed: () {
                AutoRouter.of(context).push(
                  SearchResultRoute(
                    searchEnterConst: SearchEnterConst(
                      from: "bika",
                      keyword: keywords[index],
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: globalSetting.backgroundColor,
                // 背景颜色
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 10),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide(
                  color: globalSetting.themeType
                      ? Colors.grey[350]!
                      : Colors.grey[800]!,
                  width: 1, // 描边颜色和宽度
                ),
              ),
              child: Text(
                keywords[index],
                // style: TextStyle(
                //   color: defaultTextColor,
                // ),
              ),
            );
          },
        ),
      ),
    );
  }
}
