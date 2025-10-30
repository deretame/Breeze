import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/util/foreground_task/data/download_task_json.dart';
import 'package:zephyr/util/foreground_task/task/bika_download.dart';
import 'package:zephyr/util/foreground_task/task/jm_download.dart';
import 'package:zephyr/widgets/toast.dart';

// 下载任务列表
List<String> downloadTasks = [];

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  late final ObjectBox objectBox;
  // 下载任务列表
  late DownloadTaskJson downloadTasks;
  late String comicName;
  late String comicId;
  String message = '';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    objectBox = await ObjectBox.create();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    FlutterForegroundTask.updateService(
      notificationTitle: '$comicName 下载中...',
      notificationText: message,
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {
    downloadTasks = downloadTaskJsonFromJson(data as String);
    logger.d(data);
    if (downloadTasks.from == "bika") {
      comicName = downloadTasks.comicName;
      comicId = downloadTasks.comicId;
      bikaDownloadTask(this, downloadTasks).catchError((e, s) {
        logger.e(e, stackTrace: s);
        showErrorToast(e.toString());
        FlutterForegroundTask.stopService();
      });
    } else if (downloadTasks.from == "jm") {
      comicName = downloadTasks.comicName;
      comicId = downloadTasks.comicId;
      jmDownloadTask(this, downloadTasks).catchError((e, s) {
        logger.e(e, stackTrace: s);
        showErrorToast(e.toString());
        FlutterForegroundTask.stopService();
      });
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'cancel') {
      FlutterForegroundTask.sendDataToMain("clear");
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {
    FlutterForegroundTask.sendDataToMain("clear");
    FlutterForegroundTask.stopService();
  }
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
