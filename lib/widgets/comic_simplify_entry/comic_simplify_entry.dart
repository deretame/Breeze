import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../config/global.dart';
import '../../main.dart';
import '../../object_box/objectbox.g.dart';
import '../../util/router/router.gr.dart';
import '../comic_entry/comic_entry.dart';
import 'comic_simplify_entry_info.dart';
import 'cover.dart';

class ComicSimplifyEntry extends StatefulWidget {
  final List<ComicSimplifyEntryInfo> entries;
  final ComicEntryType type;
  final GestureTapCallback? refresh;

  const ComicSimplifyEntry({
    super.key,
    required this.entries,
    required this.type,
    this.refresh,
  });

  @override
  State<ComicSimplifyEntry> createState() => _ComicSimplifyEntryState();
}

class _ComicSimplifyEntryState extends State<ComicSimplifyEntry>
    with AutomaticKeepAliveClientMixin {
  late final List<ComicSimplifyEntryInfo> entries;
  late final ComicEntryType type;
  late final GestureTapCallback? refresh;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    entries = widget.entries;
    type = widget.type;
    refresh = widget.refresh;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var entry in entries)
          _ElementInfo(info: entry, type: type, refresh: refresh),
      ],
    );
  }
}

class _ElementInfo extends StatelessWidget {
  final ComicSimplifyEntryInfo info;
  final ComicEntryType type;
  final GestureTapCallback? refresh;

  const _ElementInfo({required this.info, required this.type, this.refresh});

  @override
  Widget build(BuildContext context) {
    if (info.title == "无数据") {
      return SizedBox(width: screenWidth * 0.3);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AutoRouter.of(
          context,
        ).push(ComicInfoRoute(comicId: info.id, type: type));
      },
      onLongPress: () {
        if (type == ComicEntryType.normal) {
          return;
        }
        deleteDialog(context);
      },
      child: SizedBox(
        width: screenWidth * 0.3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenWidth * 0.1 / 4), // 添加间距
            Stack(
              children: [
                CoverWidget(
                  fileServer: info.fileServer,
                  path: info.path,
                  id: info.id,
                  pictureType: info.pictureType,
                  from: info.from,
                ),
                Positioned(
                  left: 5,
                  right: 5,
                  bottom: 5,
                  child: Stack(
                    children: [
                      Text(
                        info.title,
                        style: TextStyle(
                          fontSize: 12,
                          foreground:
                              Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 3
                                ..color = globalSetting.backgroundColor,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // 填充文字
                      Text(
                        info.title,
                        style: TextStyle(
                          fontSize: 12,
                          color: globalSetting.textColor,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future deleteDialog(BuildContext context) {
    var title = "";
    if (type == ComicEntryType.history) {
      title = "删除历史记录";
    } else if (type == ComicEntryType.download) {
      title = "删除下载记录";
    }
    var content = "确定要删除（${info.title}）的";
    if (type == ComicEntryType.history) {
      content += "历史记录吗？";
    } else if (type == ComicEntryType.download) {
      content += "下载记录及文件吗？";
    }
    logger.d(type.toString());
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: Text("取消"),
              onPressed: () {
                // 执行操作1
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("确定"),
              onPressed: () {
                if (type == ComicEntryType.history) {
                  var temp =
                      objectbox.bikaHistoryBox
                          .query(BikaComicHistory_.comicId.equals(info.id))
                          .build()
                          .findFirst();
                  if (temp != null) {
                    temp.deleted = true;
                    temp.deletedAt = DateTime.now().toUtc();
                    objectbox.bikaHistoryBox.put(temp);
                    refresh!();
                  }
                }
                if (type == ComicEntryType.download) {
                  var temp =
                      objectbox.bikaDownloadBox
                          .query(BikaComicDownload_.comicId.equals(info.id))
                          .build()
                          .findFirst();
                  if (temp != null) {
                    objectbox.bikaDownloadBox.remove(temp.id);
                    refresh!();
                    deleteDirectory(info.id);
                  }
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteDirectory(String id) async {
    String path =
        '/data/data/com.zephyr.breeze/files/downloads/bika/original/$id';
    final directory = Directory(path);

    // 检查目录是否存在
    if (await directory.exists()) {
      try {
        // 删除目录及其内容
        await directory.delete(recursive: true);
        logger.d('目录已成功删除: $path');
      } catch (e) {
        logger.e('删除目录时发生错误: $e');
      }
    } else {
      logger.e('目录不存在: $path');
    }
  }
}

List<List<ComicSimplifyEntryInfo>> generateElements(
  List<ComicSimplifyEntryInfo> list,
) {
  List<List<ComicSimplifyEntryInfo>> elementsRows = [];
  int rowCount = list.length ~/ 3;
  int remainder = list.length % 3;
  if (remainder != 0) {
    rowCount++;
    for (int i = 0; i < 3 - remainder; i++) {
      list.add(
        ComicSimplifyEntryInfo(
          title: '无数据',
          id: Uuid().v4(),
          fileServer: '',
          path: '',
          pictureType: '',
          from: '',
        ),
      );
    }
  }

  for (int i = 0; i < rowCount; i++) {
    int start = i * 3;
    int end = start + 3;
    if (end > list.length) {
      end = list.length;
    }
    elementsRows.add(list.sublist(start, end));
  }

  return elementsRows;
}
