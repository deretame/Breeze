import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/jm/jm_promote/json/promote/jm_promote_json.dart';
import 'package:zephyr/type/enum.dart';
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
        height: 233,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: materialColorScheme.outline, width: 1),
            bottom: BorderSide(color: materialColorScheme.outline, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
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
                  // GestureDetector(
                  //   onTap: () {
                  //     // TODO：添加跳转到详情页的功能
                  //   },
                  //   child: Icon(
                  //     Icons.arrow_forward_ios,
                  //     size: 16,
                  //     color: materialColorScheme.primary,
                  //   ),
                  // ),
                  const SizedBox(width: 5),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: materialColorScheme.outline,
                      width: 1,
                    ),
                  ),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: element.content.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
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
