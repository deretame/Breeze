// 通用的标签/分类 Widget
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../config/global.dart';
import '../../../main.dart';
import '../../../util/router/router.gr.dart';
import '../../search_result/models/search_enter.dart';
import '../json/comic_info/comic_info.dart';

class TagsAndCategoriesWidget extends StatefulWidget {
  final Comic comicInfo;
  final String type; // "categories" 或 "tags"

  const TagsAndCategoriesWidget({
    super.key,
    required this.comicInfo,
    required this.type,
  });

  @override
  State<TagsAndCategoriesWidget> createState() =>
      _TagsAndCategoriesWidgetState();
}

class _TagsAndCategoriesWidgetState extends State<TagsAndCategoriesWidget> {
  Comic get comicInfo => widget.comicInfo;

  List<String> get items =>
      widget.type == 'categories' ? comicInfo.categories : comicInfo.tags;

  String get title => widget.type == 'categories' ? '分类' : '标签';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: screenWidth * (48 / 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // 设置主轴对齐为居中
            children: <Widget>[
              Expanded(
                child: Container(
                  width: screenWidth * (20 / 50),
                  height: 1.0,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: globalSetting.textColor,
                        width: 1.0, // 颜色条的宽度
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(title),
              const SizedBox(width: 5),
              Expanded(
                child: Container(
                  width: screenWidth * (20 / 50),
                  height: 1.0,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: globalSetting.textColor,
                        width: 1.0, // 颜色条的宽度
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3, right: 0),
            child: Wrap(
              spacing: 10,
              runSpacing: 5,
              children: List.generate(
                items.length,
                (index) {
                  return ElevatedButton(
                    onPressed: () {
                      AutoRouter.of(context).push(
                        SearchResultRoute(
                          searchEnterConst: SearchEnterConst(
                            from: "bika",
                            type: title,
                            categories: [items[index]],
                            keyword: items[index],
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
                      processText(items[index]),
                      // style: TextStyle(
                      //   color: defaultTextColor,
                      // ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String processText(String text) {
    if (text.contains('\r')) {
      text = text.replaceAll('\r', '');
    }

    if (text.contains(' ')) {
      text = text.replaceAll(' ', '');
    }

    return text;
  }
}
