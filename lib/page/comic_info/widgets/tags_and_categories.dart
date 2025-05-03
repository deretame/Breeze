// 通用的标签/分类 Widget
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../main.dart';
import '../../../util/router/router.gr.dart';
import '../../search_result/models/search_enter.dart';
import '../json/bika/comic_info/comic_info.dart';

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
    return Observer(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              // runSpacing: 10,
              children: List.generate(items.length + 1, (index) {
                if (index == 0) {
                  return Chip(
                    backgroundColor: globalSetting.backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(color: globalSetting.textColor),
                    label: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: globalSetting.textColor,
                      ),
                    ),
                  );
                }
                return GestureDetector(
                  onTap: () {
                    if (title == "分类") {
                      AutoRouter.of(context).push(
                        SearchResultRoute(
                          searchEnterConst: SearchEnterConst(
                            from: "bika",
                            type: title,
                            categories: [items[index - 1]],
                          ),
                        ),
                      );
                    } else if (title == "标签") {
                      AutoRouter.of(context).push(
                        SearchResultRoute(
                          searchEnterConst: SearchEnterConst(
                            from: "bika",
                            type: title,
                            keyword: items[index - 1],
                          ),
                        ),
                      );
                    }
                  },
                  onLongPress: () {
                    Clipboard.setData(
                      ClipboardData(text: processText(items[index - 1])),
                    );
                    showSuccessToast("已将${items[index - 1]}复制到剪贴板");
                  },
                  child: Chip(
                    backgroundColor: globalSetting.backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    label: Text(
                      processText(items[index - 1]),
                      style: TextStyle(
                        fontSize: 12,
                        color: materialColorScheme.primary,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
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
