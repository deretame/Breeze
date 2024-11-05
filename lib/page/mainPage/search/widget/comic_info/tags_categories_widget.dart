import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/router.dart';

import '../../../../../config/global.dart';
import '../../../../../json/comic/comic_info.dart';
import '../../../../../type/search_enter.dart';

// 通用的标签/分类 Widget
class TagsAndCategoriesWidget extends StatefulWidget {
  final ComicInfo comicInfo;
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
  ComicInfo get comicInfo => widget.comicInfo;

  List<String> get items => widget.type == 'categories'
      ? comicInfo.comic.categories
      : comicInfo.comic.tags;

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
                      var enter = SearchEnter();
                      if (widget.type == 'categories') {
                        enter.categories = [items[index]];
                      } else {
                        enter.keyword = items[index];
                      }
                      navigateTo(context, '/search', extra: enter);
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
