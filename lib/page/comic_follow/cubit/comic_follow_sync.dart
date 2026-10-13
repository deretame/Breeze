import 'package:zephyr/object_box/model.dart';

/// 纯的“进详情即确认”计算：不碰数据库，供单测直接覆盖。
///
/// 进一次在线详情 = 用户看到了当前最新章节：把 [onlineChapterCount] 记为
/// 已确认（[ComicFollow.lastChapterCount]），同时把 detected 系列对齐到它，
/// `hasUpdate` 清掉。只增不减——下载快照/旧缓存偏小（`<= last`）时返回 null，
/// 不会写坏基线。老数据没有额外字段也能用。
ComicFollow? resolveFollowSyncFromDetail({
  required ComicFollow? follow,
  required int onlineChapterCount,
  required String onlineLatestTitle,
  required DateTime now,
}) {
  if (follow == null || follow.deleted) return null;
  if (onlineChapterCount <= 0) return null;
  if (onlineChapterCount <= follow.lastChapterCount) return null;
  return follow.copyWith(
    lastChapterCount: onlineChapterCount,
    detectedChapterCount: onlineChapterCount,
    detectedChapterTitle: onlineLatestTitle,
    hasUpdate: false,
    lastCheckFailed: false,
    updateTime: now,
    updatedAt: now,
  );
}
