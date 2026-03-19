import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/page/ranking_list/widgets/comic_picture.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/util/sundry.dart';

import '../../../type/enum.dart';
import '../json/leaderboard.dart';

class ComicEntryWidget extends StatefulWidget {
  final String type;
  final Comic comic;

  const ComicEntryWidget({super.key, required this.type, required this.comic});

  @override
  State<ComicEntryWidget> createState() => _ComicEntryWidgetState();
}

class _ComicEntryWidgetState extends State<ComicEntryWidget> {
  Comic get comic => widget.comic;

  @override
  Widget build(BuildContext context) {
    final materialColorScheme = context.theme.colorScheme;

    const double coverWidth = 100.0;
    const double coverHeight = 133.0;

    return GestureDetector(
      onTap: () {
        context.pushRoute(
          ComicInfoRoute(
            comicId: comic.id,
            type: ComicEntryType.normal,
            from: From.bika,
          ),
        );
      },
      child: Container(
        width: ((context.screenWidth / 10) * 9.5),
        margin: EdgeInsets.symmetric(
          horizontal: (context.screenWidth / 10) * 0.25,
          vertical: 6.0,
        ),
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: materialColorScheme.secondaryFixedDim,
              spreadRadius: 0,
              blurRadius: 2,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: coverWidth,
              height: coverHeight,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  bottomLeft: Radius.circular(10.0),
                ),
                child: ComicPictureWidget(
                  fileServer: comic.thumb.fileServer,
                  path: comic.thumb.path,
                  id: comic.id,
                  pictureType: PictureType.cover,
                ),
              ),
            ),

            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: coverHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comic.title,
                            style: TextStyle(
                              color: context.textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (comic.author.toString() != '') ...[
                            Text(
                              comic.author.toString(),
                              style: TextStyle(
                                color: materialColorScheme.primary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            _getCategories(comic.categories),
                            style: TextStyle(
                              color: context.textColor.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 2),
                      if (comic.finished)
                        Text(
                          "完结",
                          style: TextStyle(
                            color: materialColorScheme.tertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategories(List<String>? categories) {
    if (categories == null || categories.isEmpty) {
      return "";
    }
    String temp = "";
    for (var category in categories) {
      temp += "$category ";
    }
    return "分类: ${temp.let(t2s)}";
  }
}
