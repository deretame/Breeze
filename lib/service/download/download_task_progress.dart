import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/service/download/models/download_task_json.dart';

/// 单章节任务的图片下载进度（0.0 ~ 1.0）。
///
/// 总数未知时返回 null，调用方回退显示任务 status 文字。
double? downloadTaskProgressFraction({
  required int completedImages,
  required int totalImages,
}) {
  if (totalImages <= 0) return null;
  return (completedImages.clamp(0, totalImages).toDouble() / totalImages)
      .clamp(0.0, 1.0)
      .toDouble();
}

double? downloadTaskPayloadProgressFraction(DownloadTaskJson payload) {
  return downloadTaskProgressFraction(
    completedImages: payload.completedImages,
    totalImages: payload.totalImages,
  );
}

/// 单章节任务的进度文案：只有拿到章节图片总数后才有，否则返回空字符串
/// 让调用方显示任务 status。
String downloadTaskProgressMessage({
  required int completedImages,
  required int totalImages,
}) {
  if (totalImages <= 0) return '';
  final percent = (completedImages.clamp(0, totalImages) / totalImages * 100)
      .floor();
  return t.download.statusDownloadProgress(percent: percent);
}

String downloadTaskPayloadProgressMessage(DownloadTaskJson payload) {
  return downloadTaskProgressMessage(
    completedImages: payload.completedImages,
    totalImages: payload.totalImages,
  );
}
