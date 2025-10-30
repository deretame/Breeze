import 'package:flutter/material.dart';
import 'package:zephyr/page/comic_info/json/bika/recommend/recommend_json.dart'
    show Comic;
import 'package:zephyr/util/context/context_extensions.dart';

import '../../../type/enum.dart';
import '../../../widgets/comic_simplify_entry/comic_simplify_entry.dart';
import '../../../widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

class RecommendWidget extends StatelessWidget {
  final List<Comic> comicList;

  const RecommendWidget({super.key, required this.comicList});

  @override
  Widget build(BuildContext context) {
    if (comicList.isEmpty) {
      return SizedBox.shrink();
    }
    final comicInfoList = comicList
        .map(
          (e) => ComicSimplifyEntryInfo(
            title: e.title,
            id: e.id,
            fileServer: e.thumb.fileServer,
            path: e.thumb.path,
            pictureType: "cover",
            from: "bika",
          ),
        )
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Container(
        height: context.screenWidth * 0.3 / 0.75,
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: context.theme.colorScheme.secondaryFixedDim,
              spreadRadius: 0,
              blurRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          // 使用ClipRRect来裁剪子组件
          borderRadius: BorderRadius.circular(10),
          // 设置与外层Container相同的圆角
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(comicInfoList.length, (index) {
                return ComicSimplifyEntry(
                  info: comicInfoList[index],
                  type: ComicEntryType.normal,
                  topPadding: false,
                  roundedCorner: false,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
