import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;
import 'package:zephyr/page/comic_info/method/chapter_group.dart';
import 'package:zephyr/page/comic_follow/cubit/comic_follow_state.dart';
import 'package:zephyr/page/comic_follow/cubit/comic_follow_sync.dart';
import 'package:zephyr/service/comic_follow/comic_follow_service.dart';

export 'package:zephyr/page/comic_follow/cubit/comic_follow_state.dart';

class ComicFollowCubit extends Cubit<ComicFollowState> {
  ComicFollowCubit() : super(const ComicFollowState()) {
    loadFromDatabase();
  }

  /// 从数据库加载到全局内存状态
  Future<void> loadFromDatabase() async {
    emit(state.copyWith(status: ComicFollowStatus.loading));
    try {
      final items = ComicFollowService.instance.listActiveFollows();
      final histories = ComicFollowService.instance.listActiveHistories();
      emit(
        state.copyWith(
          status: ComicFollowStatus.success,
          items: items,
          histories: histories,
          revision: state.revision + 1,
        ),
      );
    } catch (e, s) {
      logger.e('加载追更列表失败', error: e, stackTrace: s);
      emit(
        state.copyWith(status: ComicFollowStatus.failure, result: e.toString()),
      );
    }
  }

  String _uniqueKey(String source, String comicId) =>
      '${source.trim()}:${comicId.trim()}';

  bool isFollowing(String source, String comicId) {
    final key = _uniqueKey(source, comicId);
    return state.items.any((item) => item.uniqueKey == key && !item.deleted);
  }

  ComicFollow? getFollow(String source, String comicId) {
    final key = _uniqueKey(source, comicId);
    try {
      return state.items.firstWhere(
        (item) => item.uniqueKey == key && !item.deleted,
      );
    } on StateError {
      return null;
    }
  }

  void setFilter(ComicFollowFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  void setSort(ComicFollowSort sort) {
    emit(state.copyWith(sort: sort));
  }

  Future<void> refreshHistories() async {
    final histories = ComicFollowService.instance.listActiveHistories();
    emit(state.copyWith(histories: histories));
  }

  Future<void> addOrUpdateFollow({
    required String source,
    required String comicId,
    required normal.NormalComicAllInfo info,
    int? lastChapterCount,
  }) async {
    final now = DateTime.now().toUtc();
    final key = _uniqueKey(source, comicId);
    final comicInfo = info.comicInfo;
    final detected = lastChapterCount ?? info.eps.length;
    final latest = info.eps.isEmpty
        ? null
        : info.eps.reduce(
            (left, right) => left.order >= right.order ? left : right,
          );
    // 跨组消歧义：有组时 `组—标题`，无组/单组时原样。
    final latestChapterTitle = latest == null
        ? ''
        : chapterQualifiedName(
            name: latest.name,
            groupTitle: resolveChapterGroupTitle(groupTitle: latest.groupTitle),
          );

    // 直接从数据库查询，避免仅依赖内存状态导致重复插入违反唯一约束
    final existing = ComicFollowService.instance.getFollowByUniqueKey(key);
    ComicFollow follow;
    if (existing != null) {
      follow = existing.copyWith(
        source: source.trim(),
        comicId: comicId.trim(),
        title: comicInfo.title,
        description: comicInfo.description,
        cover: jsonEncode(comicInfo.cover.toJson()),
        creator: jsonEncode(comicInfo.creator.toJson()),
        titleMeta: jsonEncode(
          comicInfo.titleMeta.map((e) => e.toJson()).toList(),
        ),
        metadata: jsonEncode(
          comicInfo.metadata.map((e) => e.toJson()).toList(),
        ),
        lastChapterCount: detected,
        detectedChapterCount: detected,
        detectedChapterTitle: latestChapterTitle,
        hasUpdate: false,
        lastCheckFailed: false,
        updateTime: now,
        deleted: false,
        updatedAt: now,
      );
    } else {
      follow = ComicFollow(
        uniqueKey: key,
        source: source.trim(),
        comicId: comicId.trim(),
        title: comicInfo.title,
        description: comicInfo.description,
        cover: jsonEncode(comicInfo.cover.toJson()),
        creator: jsonEncode(comicInfo.creator.toJson()),
        titleMeta: jsonEncode(
          comicInfo.titleMeta.map((e) => e.toJson()).toList(),
        ),
        metadata: jsonEncode(
          comicInfo.metadata.map((e) => e.toJson()).toList(),
        ),
        lastChapterCount: detected,
        detectedChapterCount: detected,
        detectedChapterTitle: latestChapterTitle,
        hasUpdate: false,
        lastCheckFailed: false,
        updateTime: now,
        deleted: false,
        createdAt: now,
        updatedAt: now,
        schemaVersion: 1,
      );
    }

    ComicFollowService.instance.putFollow(follow);

    final newItems = List<ComicFollow>.from(state.items);
    final index = newItems.indexWhere(
      (item) => item.uniqueKey == follow.uniqueKey,
    );
    if (index >= 0) {
      newItems[index] = follow;
    } else {
      newItems.add(follow);
    }
    emit(
      state.copyWith(
        status: ComicFollowStatus.success,
        items: newItems,
        revision: state.revision + 1,
      ),
    );
  }

  /// 进在线详情即确认：把当前线上总数记为已确认基线并清掉红点。
  ///
  /// [onlineChapterCount]/[onlineLatestTitle] 必须来自**在线详情**
  /// （`PluginComicDetailSource.eps`），下载快照/本地记录不要传——
  /// 那是已下载数，语义不对，只增不减的守卫也救不了。
  /// 无需同步（未追更/已删除/数没变大）时返回 null。
  ComicFollow? syncFollowFromDetailAndPersist({
    required String source,
    required String comicId,
    required int onlineChapterCount,
    required String onlineLatestTitle,
  }) {
    final updated = resolveFollowSyncFromDetail(
      follow: getFollow(source, comicId),
      onlineChapterCount: onlineChapterCount,
      onlineLatestTitle: onlineLatestTitle,
      now: DateTime.now().toUtc(),
    );
    if (updated == null) return null;
    ComicFollowService.instance.putFollow(updated);
    final newItems = List<ComicFollow>.from(state.items);
    final index = newItems.indexWhere(
      (item) => item.uniqueKey == updated.uniqueKey,
    );
    if (index >= 0) {
      newItems[index] = updated;
    } else {
      newItems.add(updated);
    }
    emit(state.copyWith(items: newItems, revision: state.revision + 1));
    return updated;
  }

  Future<void> removeFollow(String source, String comicId) async {
    final existing = getFollow(source, comicId);
    if (existing == null) {
      return;
    }
    final now = DateTime.now().toUtc();
    final removed = existing.copyWith(deleted: true, updatedAt: now);
    ComicFollowService.instance.putFollow(removed);

    final newItems = state.items
        .where((item) => item.uniqueKey != removed.uniqueKey || item.deleted)
        .toList();
    emit(state.copyWith(items: newItems, revision: state.revision + 1));
  }

  /// 全部标为已读：把每条的 lastChapterCount 对齐到 detectedChapterCount，
  /// 清掉未读徽标。不碰 detected 数据，只是确认“我看到了当前最新”。
  Future<void> markAllAsRead() async {
    final now = DateTime.now().toUtc();
    final newItems = state.items.map((item) {
      if (item.deleted || !state.hasUnreadUpdate(item)) {
        return item;
      }
      final marked = item.copyWith(
        lastChapterCount: item.detectedChapterCount,
        hasUpdate: false,
        updatedAt: now,
      );
      ComicFollowService.instance.putFollow(marked);
      return marked;
    }).toList();
    emit(state.copyWith(items: newItems, revision: state.revision + 1));
  }

  Future<int> checkUpdates() async {
    if (state.isCheckingUpdates) {
      return 0;
    }
    emit(state.copyWith(isCheckingUpdates: true));

    int updateCount = 0;
    final follows = state.items.where((e) => !e.deleted).toList();

    for (final follow in follows) {
      final hasUpdate = await _checkSingleUpdate(follow);
      if (hasUpdate) {
        updateCount++;
      }
    }

    emit(state.copyWith(isCheckingUpdates: false));

    if (updateCount > 0) {
      await ComicFollowService.instance.notifyUpdate(updateCount);
    }

    return updateCount;
  }

  /// 检测单部追更漫画，返回是否真的有更新
  Future<bool> checkUpdateForItem(ComicFollow follow) async {
    final hasUpdate = await _checkSingleUpdate(follow);
    if (hasUpdate) {
      await ComicFollowService.instance.notifyUpdate(1);
    }
    return hasUpdate;
  }

  Future<bool> _checkSingleUpdate(ComicFollow follow) async {
    final wasUnread = state.hasUnreadUpdate(follow);
    final detection = await ComicFollowService.instance.detectChapter(follow);
    final detected = detection?.chapterCount;
    final now = DateTime.now().toUtc();

    ComicFollow updated;
    if (detected == null) {
      updated = follow.copyWith(
        lastCheckFailed: true,
        updateTime: now,
        updatedAt: now,
      );
    } else if (detected > follow.lastChapterCount) {
      final history = state.historyFor(follow);
      final readThroughLatest =
          history != null &&
          history.chapterOrder > 0 &&
          history.chapterOrder >= detected;
      updated = follow.copyWith(
        detectedChapterCount: detected,
        detectedChapterTitle: detection!.latestChapterTitle,
        hasUpdate: !readThroughLatest,
        lastCheckFailed: false,
        updateTime: now,
        updatedAt: now,
      );
    } else {
      updated = follow.copyWith(
        detectedChapterCount: detected,
        detectedChapterTitle: detection!.latestChapterTitle,
        hasUpdate: false,
        lastCheckFailed: false,
        updateTime: now,
        updatedAt: now,
      );
    }

    ComicFollowService.instance.putFollow(updated);

    final newItems = List<ComicFollow>.from(state.items);
    final index = newItems.indexWhere(
      (item) => item.uniqueKey == updated.uniqueKey,
    );
    if (index >= 0) {
      newItems[index] = updated;
    } else {
      newItems.add(updated);
    }
    emit(state.copyWith(items: newItems, revision: state.revision + 1));

    return state.hasUnreadUpdate(updated) && !wasUnread;
  }
}
