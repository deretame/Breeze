/// 下载进度报告抽象接口
///
/// 用于将下载逻辑与平台特定的进度报告机制解耦。
/// Android 端通过前台服务通知栏报告进度，桌面端通过 Stream 通知 UI。
abstract class DownloadProgressReporter {
  /// 当前正在下载的漫画名称
  String comicName = '';

  /// 当前进度消息
  String message = '';

  /// 更新进度消息
  void updateMessage(String msg) {
    message = msg;
  }

  /// 发送系统通知（下载完成/失败）
  Future<void> sendNotification(String title, String body);
}
