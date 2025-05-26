import 'dart:convert';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/download/widgets/eps.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/foreground_task/data/download_task_json.dart';
import 'package:zephyr/util/foreground_task/init.dart';

import '../../../config/global/global.dart';
import '../../../object_box/model.dart';
import '../../comic_info/json/bika/comic_info/comic_info.dart';
import '../../comic_info/json/bika/eps/eps.dart';
import '../../comments/widgets/title.dart';

@RoutePage()
class DownloadPage extends StatefulWidget {
  final Comic comicInfo;
  final List<Doc> epsInfo;

  const DownloadPage({
    super.key,
    required this.comicInfo,
    required this.epsInfo,
  });

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  Comic get comicInfo => widget.comicInfo;

  List<Doc> get epsInfo => widget.epsInfo;

  late Map<int, bool> _downloadInfo;
  late BikaComicDownload? bikaComicDownloadInfo;

  void onUpdateDownloadInfo(int order) {
    setState(() {
      _downloadInfo[order] = !_downloadInfo[order]!;
    });
  }

  @override
  void initState() {
    super.initState();
    _downloadInfo = {};
    for (var ep in epsInfo) {
      _downloadInfo[ep.order] = false;
    }
    final query = objectbox.bikaDownloadBox.query(
      BikaComicDownload_.comicId.equals(comicInfo.id),
    );
    bikaComicDownloadInfo = query.build().findFirst();
    if (bikaComicDownloadInfo != null) {
      for (var epTitle in bikaComicDownloadInfo!.epsTitle) {
        for (var ep in epsInfo) {
          if (ep.title == epTitle) {
            _downloadInfo[ep.order] = true;
          }
        }
      }
    }
  }

  // 判断是否所有章节都被选中
  bool get isAllSelected {
    return epsInfo.every((ep) => _downloadInfo[ep.order] == true);
  }

  // 切换全选或取消全选
  void toggleSelectAll() {
    setState(() {
      bool newState = !isAllSelected; // 如果当前是全选，则取消全选；反之亦然
      for (var ep in epsInfo) {
        _downloadInfo[ep.order] = newState;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ScrollableTitle(text: comicInfo.title),
        actions: [
          // 动态切换全选/取消全选按钮
          IconButton(
            icon: Icon(isAllSelected ? Icons.deselect : Icons.select_all),
            onPressed: toggleSelectAll,
          ),
        ],
      ),
      body: ListView.builder(
        // 设置 ListView 的宽度为屏幕宽度
        padding: EdgeInsets.symmetric(horizontal: screenWidth / 50),
        itemCount: epsInfo.length, // 列表项的数量
        itemBuilder: (context, index) {
          final doc = epsInfo[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: EpsWidget(
              doc: doc,
              downloaded: _downloadInfo[doc.order]!,
              onUpdateDownloadInfo: onUpdateDownloadInfo,
            ),
          );
        },
      ),
      floatingActionButton: SizedBox(
        width: 100, // 设置容器宽度，以容纳更长的文本
        height: 56, // 设置容器高度，与默认的FloatingActionButton高度一致
        child: FloatingActionButton(
          onPressed: () {
            logger.d("开始下载");
            download();
          },
          child: Text("开始下载", overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ),
    );
  }

  Future<void> download() async {
    await initForegroundTask(comicInfo.title);
    await Future.delayed(const Duration(seconds: 1));
    FlutterForegroundTask.sendDataToTask(
      DownloadTaskJson(
        from: "bika",
        comicId: comicInfo.id,
        comicName: comicInfo.title,
        bikaInfo: BikaInfo(
          authorization: bikaSetting.authorization,
          proxy: bikaSetting.proxy.toString(),
        ),
        selectedChapters:
            _downloadInfo.entries
                .where((entry) => entry.value)
                .map((entry) => entry.key.toString())
                .toList(),
      ).toJson().let(jsonEncode),
    );
  }
}
