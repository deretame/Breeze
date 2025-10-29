import 'package:flutter/material.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/jm/jm_comic_info/json/jm_comic_info_json.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

class RecommendWidget extends StatelessWidget {
  final JmComicInfoJson comicInfo;

  const RecommendWidget({super.key, required this.comicInfo});

  @override
  Widget build(BuildContext context) {
    final comicInfoList = comicInfo.relatedList
        .map(
          (e) => ComicSimplifyEntryInfo(
            title: e.name,
            id: e.id,
            fileServer: getJmCoverUrl(e.id),
            path: "${e.id}.jpg",
            pictureType: "cover",
            from: "jm",
          ),
        )
        .toList();

    return Container(
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
    );
  }
}
