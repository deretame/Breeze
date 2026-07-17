import 'dart:convert';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

/// Android 前台服务处理器。
///
/// 下载逻辑统一在主 Isolate 的 [DownloadQueueManager] 中执行，
/// 前台服务仅用于：
/// 1. 提升应用进程优先级，防止系统杀后台
/// 2. 接收主 Isolate 发送的进度/状态更新并刷新通知栏
/// 3. 接收通知栏取消事件并转发给主 Isolate
class MyTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // 初始通知文案由主 Isolate startService 指定
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // 进度更新由主 Isolate 通过 onReceiveData 驱动
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // 清理工作由主 Isolate 负责
  }

  @override
  void onReceiveData(Object data) {
    // 接收主 Isolate 发送的进度/状态更新（JSON 字符串）
    if (data is String) {
      try {
        final map = jsonDecode(data) as Map<String, dynamic>;
        final title = map['title'] as String?;
        final message = map['message'] as String?;
        if (title != null && message != null) {
          FlutterForegroundTask.updateService(
            notificationTitle: title,
            notificationText: message,
          );
        }
      } catch (_) {
        // 忽略解析失败的异常数据
      }
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'cancel') {
      _sendCancelToMain();
    }
  }

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {
    // 前台服务通知一般为 ongoing，正常无法划掉；
    // 若系统边界情况下触发，仅在有下载时取消下载（主 Isolate 侧无任务则空操作）
    _sendCancelToMain();
  }

  void _sendCancelToMain() {
    FlutterForegroundTask.sendDataToMain(const {'action': 'cancel_download'});
  }
}
