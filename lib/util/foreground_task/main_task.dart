import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/util/foreground_task/data/download_task_json.dart';
import 'package:zephyr/util/foreground_task/task/bika_download.dart'; // 导入你的 ObjectBox 帮助类

// @pragma 这个注解告诉编译器，即使这个函数看起来没有被直接调用，也不要把它优化掉（摇树优化 Tree Shaking）
// 'vm:entry-point' 表示这是Dart虚拟机的一个入口点，对于后台 isolate (隔离区/独立线程) 来说是必需的喵！
// 当启动前台服务时，这个函数会在一个新的 isolate 中被执行。
@pragma('vm:entry-point')
void startCallback() {
  // 这行代码是关键喵！它告诉 flutter_foreground_task 插件，
  // 在这个新的后台 isolate 中，应该使用哪个 TaskHandler 来处理任务逻辑。
  // MyTaskHandler 就是我们下面定义的那个类啦。
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  late final ObjectBox objectBox;
  // 下载任务列表
  late DownloadTaskJson downloadTasks;

  // 当任务第一次启动时，这个方法会被调用喵。
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    objectBox = await ObjectBox.create();
  }

  // 这个方法会根据你在 ForegroundTaskOptions 中设置的 eventAction 来重复调用。
  // 比如，如果设置了每5秒重复一次，那这个方法就会每5秒执行一次喵。
  @override
  void onRepeatEvent(DateTime timestamp) {
    final downloadingComic = downloadTasks.comicName;
    FlutterForegroundTask.updateService(
      notificationTitle: '下载任务',
      notificationText: '$downloadingComic 下载中...',
    );
  }

  // 当任务被销毁时（比如调用了 stopService() 或者系统停止了服务），这个方法会被调用喵。
  // 可以在这里进行一些清理工作，比如关闭数据库连接、取消监听等。
  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  // 当主 isolate (UI线程) 通过 FlutterForegroundTask.sendDataToTask 发送数据给这个后台任务时，
  // 这个方法会被调用喵。
  // data: 从主 isolate 发送过来的数据。
  @override
  void onReceiveData(Object data) {
    try {
      downloadTasks = downloadTaskJsonFromJson(data as String);
      if (downloadTasks.from == "bika") {
        bikaDownloadTask(downloadTasks);
      }
    } catch (e, s) {
      logger.e(
        'Error receiving data: ${e.toString()}',
        error: e,
        stackTrace: s,
      );
    }

    FlutterForegroundTask.stopService();
  }

  // 如果你在前台服务的通知上添加了按钮 (NotificationButton)，
  // 当用户点击这些按钮时，这个方法会被调用喵。
  // id: 被点击的按钮的唯一标识符 (在创建 NotificationButton 时指定的)。
  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'cancel') {
      FlutterForegroundTask.stopService();
    }
  }

  // 当用户点击通知本身（而不是通知上的按钮）时，这个方法会被调用喵。
  // 通常点击通知会打开App。
  @override
  void onNotificationPressed() {}

  // 当用户从通知栏中清除或划掉这个服务的通知时，这个方法会被调用喵。
  @override
  void onNotificationDismissed() {
    FlutterForegroundTask.updateService(
      notificationTitle: '下载任务',
      notificationText: '下载任务已取消',
    );
    FlutterForegroundTask.stopService();
  }
}
