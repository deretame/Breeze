import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;
import 'package:zephyr/service/comic_follow/comic_follow_service.dart';

enum ComicFollowStatus { initial, loading, success, failure }

enum ComicFollowFilter { all, unread }

enum ComicFollowSort { lastRead, update }

class ComicFollowState extends Equatable {
  final ComicFollowStatus status;
  final List<ComicFollow> items;
  final bool isCheckingUpdates;
  final String result;
  final int revision;
  final Map<String, UnifiedComicHistory> histories;
  final ComicFollowFilter filter;
  final ComicFollowSort sort;

  const ComicFollowState({
    this.status = ComicFollowStatus.initial,
    this.items = const <ComicFollow>[],
    this.isCheckingUpdates = false,
    this.result = '',
    this.revision = 0,
    this.histories = const <String, UnifiedComicHistory>{},
    this.filter = ComicFollowFilter.all,
    this.sort = ComicFollowSort.lastRead,
  });

  int get updateCount => items.where(hasUnreadUpdate).length;

  List<ComicFollow> get visibleItems {
    final result = items
        .where(
          (item) => filter == ComicFollowFilter.all || hasUnreadUpdate(item),
        )
        .toList();
    result.sort(_compareItems);
    return result;
  }

  UnifiedComicHistory? historyFor(ComicFollow follow) =>
      histories[follow.uniqueKey];

  bool hasUnreadUpdate(ComicFollow follow) {
    if (!follow.hasUpdate ||
        follow.detectedChapterCount <= follow.lastChapterCount) {
      return false;
    }

    final history = historyFor(follow);
    if (history == null || history.chapterOrder <= 0) {
      return true;
    }
    return history.chapterOrder < follow.detectedChapterCount;
  }

  int unreadChapterCount(ComicFollow follow) {
    if (!hasUnreadUpdate(follow)) return 0;

    final history = historyFor(follow);
    final readChapterOrder = history?.chapterOrder ?? 0;
    final readBaseline = readChapterOrder > follow.lastChapterCount
        ? readChapterOrder
        : follow.lastChapterCount;
    return (follow.detectedChapterCount - readBaseline).clamp(
      0,
      follow.detectedChapterCount,
    );
  }

  int _compareItems(ComicFollow left, ComicFollow right) {
    if (filter == ComicFollowFilter.unread) {
      final rightUnread = hasUnreadUpdate(right);
      final leftUnread = hasUnreadUpdate(left);
      final unreadCompare = rightUnread == leftUnread
          ? 0
          : (rightUnread ? 1 : -1);
      if (unreadCompare != 0) return unreadCompare;
    }

    if (sort == ComicFollowSort.lastRead) {
      final leftTime = historyFor(left)?.lastReadAt;
      final rightTime = historyFor(right)?.lastReadAt;
      if (leftTime == null && rightTime != null) return 1;
      if (leftTime != null && rightTime == null) return -1;
      if (leftTime != null && rightTime != null) {
        final timeCompare = rightTime.compareTo(leftTime);
        if (timeCompare != 0) return timeCompare;
      }
    } else {
      final timeCompare = right.updateTime.compareTo(left.updateTime);
      if (timeCompare != 0) return timeCompare;
    }

    return right.createdAt.compareTo(left.createdAt);
  }

  bool isFollowing(String source, String comicId) {
    final key = '${source.trim()}:${comicId.trim()}';
    return items.any((item) => item.uniqueKey == key && !item.deleted);
  }

  ComicFollowState copyWith({
    ComicFollowStatus? status,
    List<ComicFollow>? items,
    bool? isCheckingUpdates,
    String? result,
    int? revision,
    Map<String, UnifiedComicHistory>? histories,
    ComicFollowFilter? filter,
    ComicFollowSort? sort,
  }) {
    final shouldIncrementRevision =
        items != null && !identical(items, this.items);
    return ComicFollowState(
      status: status ?? this.status,
      items: items ?? this.items,
      isCheckingUpdates: isCheckingUpdates ?? this.isCheckingUpdates,
      result: result ?? this.result,
      revision:
          revision ??
          (shouldIncrementRevision ? this.revision + 1 : this.revision),
      histories: histories ?? this.histories,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    isCheckingUpdates,
    result,
    revision,
    histories,
    filter,
    sort,
  ];
}

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
    final latestChapterTitle = info.eps.isEmpty
        ? ''
        : info.eps
              .reduce((left, right) => left.order >= right.order ? left : right)
              .name;

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
    emit(state.copyWith(status: ComicFollowStatus.success, items: newItems));
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
    emit(state.copyWith(items: newItems));
  }

  /// 检测全部追更漫画
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
    emit(state.copyWith(items: newItems));

    return state.hasUnreadUpdate(updated) && !wasUnread;
  }
}
