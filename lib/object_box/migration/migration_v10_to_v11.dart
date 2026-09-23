import 'package:zephyr/main.dart';

/// v10 -> v11：清理旧的多章节下载任务记录。
///
/// 单章节任务模型（taskKey 精确到章节）与老的多章节 payload 不兼容，
/// 直接拆分容易把“已完成一半”的旧任务算错，因此整表清理 DownloadTask。
/// 已下载完的漫画记录、书架链接和磁盘上的图片均不受影响；
/// 未下完的章节按失败处理，用户在详情页点对应章节会重新下载
///（已落盘的图片会被直接复用，不会重复耗流量）。
Future<void> migrateV10ToV11() async {
  final count = objectbox.downloadTaskBox.removeAll();
  logger.i('[migration_v10_to_v11] 已清理 $count 条旧下载任务记录');
}
