import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/comic_follow/cubit/comic_follow_state.dart';
import 'package:zephyr/page/comic_follow/cubit/comic_follow_sync.dart';

ComicFollow _follow({
  String uniqueKey = 'src:1',
  int last = 10,
  int detected = 10,
  bool hasUpdate = false,
  bool deleted = false,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return ComicFollow(
    uniqueKey: uniqueKey,
    source: 'src',
    comicId: '1',
    title: 't',
    description: '',
    cover: '',
    creator: '',
    titleMeta: '',
    metadata: '',
    lastChapterCount: last,
    detectedChapterCount: detected,
    hasUpdate: hasUpdate,
    updateTime: now,
    deleted: deleted,
    createdAt: now,
    updatedAt: now,
    schemaVersion: 1,
  );
}

UnifiedComicHistory _history(String uniqueKey, int order) {
  final now = DateTime.utc(2026, 1, 1);
  return UnifiedComicHistory(
    uniqueKey: uniqueKey,
    source: 'src',
    comicId: '1',
    title: 't',
    description: '',
    cover: '',
    creator: '',
    titleMeta: '',
    metadata: '',
    chapterId: '',
    chapterTitle: '',
    chapterOrder: order,
    pageIndex: 0,
    createdAt: now,
    lastReadAt: now,
    updatedAt: now,
    deleted: false,
    schemaVersion: 2,
  );
}

void main() {
  group('resolveFollowSyncFromDetail（进详情即确认）', () {
    test('在线数没变大时返回 null，下载快照偏小不会写坏基线', () {
      final follow = _follow(last: 10, detected: 12, hasUpdate: true);
      expect(
        resolveFollowSyncFromDetail(
          follow: follow,
          onlineChapterCount: 9,
          onlineLatestTitle: '第9话',
          now: DateTime.utc(2026, 1, 2),
        ),
        isNull,
      );
      expect(
        resolveFollowSyncFromDetail(
          follow: follow,
          onlineChapterCount: 10,
          onlineLatestTitle: '第10话',
          now: DateTime.utc(2026, 1, 2),
        ),
        isNull,
      );
    });

    test('在线数为 0 或记录已删除时返回 null', () {
      expect(
        resolveFollowSyncFromDetail(
          follow: _follow(),
          onlineChapterCount: 0,
          onlineLatestTitle: '',
          now: DateTime.utc(2026, 1, 2),
        ),
        isNull,
      );
      expect(
        resolveFollowSyncFromDetail(
          follow: _follow(deleted: true),
          onlineChapterCount: 99,
          onlineLatestTitle: '第99话',
          now: DateTime.utc(2026, 1, 2),
        ),
        isNull,
      );
    });

    test('进详情把线上总数记为已确认基线并清掉红点', () {
      final updated = resolveFollowSyncFromDetail(
        follow: _follow(last: 10, detected: 12, hasUpdate: true),
        onlineChapterCount: 12,
        onlineLatestTitle: '第12话',
        now: DateTime.utc(2026, 1, 2),
      )!;
      expect(updated.lastChapterCount, 12);
      expect(updated.detectedChapterCount, 12);
      expect(updated.detectedChapterTitle, '第12话');
      expect(updated.hasUpdate, isFalse);
      expect(updated.lastCheckFailed, isFalse);
    });

    test('确认后未读口径归零：顶部不再计数、卡片不再标红', () {
      final updated = resolveFollowSyncFromDetail(
        follow: _follow(last: 10, detected: 12, hasUpdate: true),
        onlineChapterCount: 12,
        onlineLatestTitle: '第12话',
        now: DateTime.utc(2026, 1, 2),
      )!;
      final state = ComicFollowState(
        items: [updated],
        histories: {'src:1': _history('src:1', 1)},
      );
      expect(state.hasUnreadUpdate(updated), isFalse);
      expect(state.updateCount, 0);
      expect(state.unreadChapterCount(updated), 0);
    });
  });

  group('未读口径', () {
    test('顶部按部数、卡片按话数：1 部有更新、该部 2 话未读', () {
      final f1 = _follow(
        uniqueKey: 'src:1',
        last: 10,
        detected: 12,
        hasUpdate: true,
      );
      final f2 = _follow(uniqueKey: 'src:2', last: 5, detected: 5);
      final state = ComicFollowState(
        items: [f1, f2],
        histories: {'src:1': _history('src:1', 10)},
      );
      // 顶部：有更新的漫画部数。
      expect(state.updateCount, 1);
      // 卡片：单部未读话数。
      expect(state.unreadChapterCount(f1), 2);
      expect(state.unreadChapterCount(f2), 0);
    });

    test('无未读时部数为 0', () {
      final state = ComicFollowState(
        items: [_follow(last: 5, detected: 5)],
      );
      expect(state.updateCount, 0);
    });
  });
}
