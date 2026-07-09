import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/widgets/toast.dart';

const _kMaxRetryCount = 3;
const _kComicUpdateChannelId = 'comic_update_channel';
const _kComicUpdateChannelName = '漫画更新提醒';
const _kComicUpdateChannelDesc = '追更漫画检测到新章节时推送';

class ComicFollowService {
  static final ComicFollowService instance = ComicFollowService._();

  ComicFollowService._();

  String uniqueKey(String source, String comicId) {
    return '${source.trim()}:${comicId.trim()}';
  }

  /// 保存或更新追更记录（直接写入数据库）
  void putFollow(ComicFollow follow) {
    objectbox.comicFollowBox.put(follow);
  }

  /// 查询全部未删除的追更记录
  List<ComicFollow> listActiveFollows() {
    final query = objectbox.comicFollowBox
        .query(ComicFollow_.deleted.equals(false))
        .order(ComicFollow_.hasUpdate, flags: Order.descending)
        .order(ComicFollow_.updateTime, flags: Order.descending)
        .build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  /// 检测单部漫画的当前章节数，失败时返回 null，最多重试 3 次
  Future<int?> detectChapterCount(ComicFollow follow) async {
    for (var attempt = 0; attempt < _kMaxRetryCount; attempt++) {
      try {
        final result = await getComicDetailByPlugin(
          follow.comicId,
          follow.source,
        );
        return result.normalInfo.eps.length;
      } catch (e, s) {
        logger.w(
          '追更检测失败 ${follow.source}:${follow.comicId} (attempt ${attempt + 1}/$_kMaxRetryCount)',
          error: e,
          stackTrace: s,
        );
        if (attempt < _kMaxRetryCount - 1) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
    return null;
  }

  /// 发送更新通知与应用内提示
  Future<void> notifyUpdate(int updateCount) async {
    final title = '追更更新';
    final body = updateCount == 1 ? '有 1 部追更漫画更新了' : '有 $updateCount 部追更漫画更新了';

    try {
      await flutterLocalNotificationsPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch % 2147483647,
        title: title,
        body: body,
        notificationDetails: _notificationDetails(),
      );
    } catch (e, s) {
      logger.e('追更通知发送失败', error: e, stackTrace: s);
    }

    try {
      eventBus.fire(
        ToastEvent(
          type: ToastType.info,
          title: title,
          message: body,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e, s) {
      logger.e('追更 Toast 发送失败', error: e, stackTrace: s);
    }
  }

  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      _kComicUpdateChannelId,
      _kComicUpdateChannelName,
      channelDescription: _kComicUpdateChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwinDetails = DarwinNotificationDetails();
    final linuxDetails = LinuxNotificationDetails(
      urgency: LinuxNotificationUrgency.normal,
    );
    const windowsDetails = WindowsNotificationDetails();
    return NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
      windows: windowsDetails,
    );
  }
}
