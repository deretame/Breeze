// 通用的标签/分类 Widget
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

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
    return Observer(
      builder: (context) {
        return Column(
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
              padding: const EdgeInsets.only(top: 5, right: 0),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(
                  items.length,
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
                            if (title == "分类") {
                              AutoRouter.of(context).push(
                                SearchResultRoute(
                                  searchEnterConst: SearchEnterConst(
                                    from: "bika",
                                    type: title,
                                    categories: [items[index]],
                                  ),
                                ),
                              );
                            } else if (title == "标签") {
                              AutoRouter.of(context).push(
                                SearchResultRoute(
                                  searchEnterConst: SearchEnterConst(
                                    from: "bika",
                                    type: title,
                                    keyword: items[index],
                                  ),
                                ),
                              );
                            }
                          },
                          onLongPress: () {
                            Clipboard.setData(
                              ClipboardData(text: processText(items[index])),
                            );
                            EasyLoading.showSuccess(
                              "已将${items[index]}复制到剪贴板",
                            );
                          },
                          child: Text(
                            processText(items[index]),
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
              ),
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
