import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/object_box/model.dart';

part 'comic_follow_state.freezed.dart';

enum ComicFollowStatus { initial, loading, success, failure }

enum ComicFollowFilter { all, unread }

enum ComicFollowSort { lastRead, update }

@freezed
abstract class ComicFollowState with _$ComicFollowState {
  const ComicFollowState._();

  const factory ComicFollowState({
    @Default(ComicFollowStatus.initial) ComicFollowStatus status,
    @Default(<ComicFollow>[]) List<ComicFollow> items,
    @Default(false) bool isCheckingUpdates,
    @Default('') String result,
    @Default(0) int revision,
    @Default(<String, UnifiedComicHistory>{})
    Map<String, UnifiedComicHistory> histories,
    @Default(ComicFollowFilter.all) ComicFollowFilter filter,
    @Default(ComicFollowSort.lastRead) ComicFollowSort sort,
  }) = _ComicFollowState;

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
}
