import 'package:flutter/material.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/util/context/context_extensions.dart';

import '../../../type/enum.dart';
import '../../../widgets/comic_simplify_entry/comic_simplify_entry.dart';
import '../../../widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

class RecommendWidget extends StatelessWidget {
  final List<Recommend> comicList;
  final From from;

  const RecommendWidget({
    super.key,
    required this.comicList,
    required this.from,
  });

  @override
  Widget build(BuildContext context) {
    if (comicList.isEmpty) {
      return SizedBox.shrink();
    }
    final comicInfoList = comicList.map((e) {
      if (from == From.bika) {
        return ComicSimplifyEntryInfo(
          title: e.title,
          id: e.id,
          fileServer: e.cover.url,
          path: e.cover.path,
          pictureType: "cover",
          from: "bika",
        );
      } else {
        return ComicSimplifyEntryInfo(
          title: e.title,
          id: e.id,
          fileServer: getJmCoverUrl(e.id),
          path: "${e.id}.jpg",
          pictureType: "cover",
          from: "jm",
        );
      }
    }).toList();

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
          borderRadius: BorderRadius.circular(10),
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
