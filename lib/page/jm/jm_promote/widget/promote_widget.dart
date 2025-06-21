import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/jm/jm_promote/json/promote/jm_promote_json.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

class PromoteWidget extends StatelessWidget {
  final JmPromoteJson element;

  const PromoteWidget({super.key, required this.element});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        height: 33 + screenWidth * 0.3 / 0.75 + 14,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: materialColorScheme.outline.withValues(alpha: 0.5),
              width: 1,
            ),
            bottom: BorderSide(
              color: materialColorScheme.outline.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  Text(
                    element.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: materialColorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      if (element.title != "连载更新→右滑看更多→" &&
                          element.title != "禁漫汉化组" &&
                          element.title != "其他更新" &&
                          element.title != "韩漫更新") {
                        int id = element.id.toString().let(toInt);
                        context.pushRoute(
                          JmPromoteListRoute(id: id, name: element.title),
                        );
                        return;
                      }
                    },
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: materialColorScheme.onSurface.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: materialColorScheme.outline.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: element.content.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(5),
                      child: ComicSimplifyEntry(
                        info: ComicSimplifyEntryInfo(
                          title: element.content[index].name,
                          id: element.content[index].id,
                          fileServer: getJmCoverUrl(element.content[index].id),
                          path: '${element.content[index].id}.jpg',
                          pictureType: 'cover',
                          from: 'jm',
                        ),
                        type: ComicEntryType.normal,
                        topPadding: false,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
