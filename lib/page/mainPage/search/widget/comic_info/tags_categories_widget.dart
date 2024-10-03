import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zephyr/util/dialog.dart';

import '../../../../../config/global.dart';
import '../../../../../json/comic/comic_info.dart';
import '../../../../../util/state_management.dart';

// 通用的标签/分类 Widget
class TagsAndCategoriesWidget extends ConsumerStatefulWidget {
  final ComicInfo comicInfo;
  final String type; // "categories" 或 "tags"

  const TagsAndCategoriesWidget({
    super.key,
    required this.comicInfo,
    required this.type,
  });

  @override
  ConsumerState<TagsAndCategoriesWidget> createState() =>
      _TagsAndCategoriesWidgetState();
}

class _TagsAndCategoriesWidgetState
    extends ConsumerState<TagsAndCategoriesWidget> {
  ComicInfo get comicInfo => widget.comicInfo;

  List<String> get items => widget.type == 'categories'
      ? comicInfo.comic.categories
      : comicInfo.comic.tags;

  String get title => widget.type == 'categories' ? '分类' : '标签';

  @override
  Widget build(BuildContext context) {
    final colorNotifier = ref.watch(defaultColorProvider);
    colorNotifier.initialize(context);

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
                        color: colorNotifier.defaultTextColor!,
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
                        color: colorNotifier.defaultTextColor!,
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
                      nothingDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorNotifier.defaultBackgroundColor,
                      // 背景颜色
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 10),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(
                        color: colorNotifier.themeType
                            ? Colors.grey[350]!
                            : Colors.grey[800]!,
                        width: 1, // 描边颜色和宽度
                      ),
                    ),
                    child: Text(
                      items[index],
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
