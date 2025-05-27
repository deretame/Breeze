import 'dart:convert';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/jm/download/download.dart';
import 'package:zephyr/page/jm/jm_comic_info/json/jm_comic_info_json.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/foreground_task/data/download_task_json.dart';
import 'package:zephyr/util/foreground_task/init.dart';

import '../../../../config/global/global.dart';
import '../../../../object_box/model.dart';
import '../../../comments/widgets/title.dart';

@RoutePage()
class JmDownloadPage extends StatefulWidget {
  final JmComicInfoJson jmComicInfoJson;

  const JmDownloadPage({super.key, required this.jmComicInfoJson});

  @override
  State<JmDownloadPage> createState() => _JmDownloadPageState();
}

class _JmDownloadPageState extends State<JmDownloadPage> {
  JmComicInfoJson get jmComicInfoJson => widget.jmComicInfoJson;

  late Map<int, bool> _downloadInfo;
  late JmDownload? jmDownloadInfo;
  int length = 0;

  void onUpdateDownloadInfo(int order) {
    setState(() {
      _downloadInfo[order] = !_downloadInfo[order]!;
    });
  }

  @override
  void initState() {
    super.initState();
    _downloadInfo = {};
    if (jmComicInfoJson.series.isEmpty) {
      _downloadInfo[jmComicInfoJson.id.let(toInt)] = false;
    } else {
      for (var ep in jmComicInfoJson.series) {
        _downloadInfo[ep.id.let(toInt)] = false;
      }
    }
    final query = objectbox.jmDownloadBox.query(
      JmDownload_.comicId.equals(jmComicInfoJson.id.toString()),
    );
    jmDownloadInfo = query.build().findFirst();
    if (jmDownloadInfo != null) {
      for (var epTitle in jmDownloadInfo!.epsTitle) {
        for (var ep in jmComicInfoJson.series) {
          if (ep.name == epTitle) {
            _downloadInfo[ep.id.let(toInt)] = true;
          }
        }
      }
    }
    length = _downloadInfo.length;
  }

  // 判断是否所有章节都被选中
  bool get isAllSelected {
    return jmComicInfoJson.series.every(
      (ep) => _downloadInfo[ep.id.let(toInt)] == true,
    );
  }

  // 切换全选或取消全选
  void toggleSelectAll() {
    setState(() {
      bool newState = !isAllSelected; // 如果当前是全选，则取消全选；反之亦然
      for (var ep in jmComicInfoJson.series) {
        _downloadInfo[ep.id.let(toInt)] = newState;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ScrollableTitle(text: jmComicInfoJson.name),
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
        itemCount: length, // 列表项的数量
        itemBuilder: (context, index) {
          if (jmComicInfoJson.series.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: EpsWidget(
                series: Series(
                  id: jmComicInfoJson.id.toString(),
                  name: jmComicInfoJson.name,
                  sort: "0",
                ),
                downloaded: _downloadInfo[jmComicInfoJson.id.let(toInt)]!,
                onUpdateDownloadInfo: onUpdateDownloadInfo,
              ),
            );
          }
          final series = jmComicInfoJson.series[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: EpsWidget(
              series: series,
              downloaded: _downloadInfo[series.id.let(toInt)]!,
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
    logger.d(_downloadInfo);
    await FlutterForegroundTask.stopService();
    await initForegroundTask(jmComicInfoJson.name);
    await Future.delayed(const Duration(seconds: 1));
    FlutterForegroundTask.sendDataToTask(
      DownloadTaskJson(
        from: "jm",
        comicId: jmComicInfoJson.id.toString(),
        comicName: jmComicInfoJson.name,
        bikaInfo: BikaInfo(authorization: "", proxy: ""),
        selectedChapters:
            _downloadInfo.entries
                .where((entry) => entry.value)
                .map((entry) => entry.key.toString())
                .toList(),
      ).toJson().let(jsonEncode),
    );
  }
}
