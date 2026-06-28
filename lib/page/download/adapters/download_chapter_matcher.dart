import 'package:zephyr/page/download/models/download_chapter.dart';

/// 统一的 [DownloadChapter] 匹配器。
///
/// 外部查询条件可能是 canonical id、requestId 或 order，
/// 这里统一处理，避免业务代码里重复写各种 fallback 判断。
class DownloadChapterMatcher {
  const DownloadChapterMatcher();

  /// 判断 [chapter] 是否匹配 [target]。
  ///
  /// [target] 可能是：
  /// - [DownloadChapter.id]
  /// - [DownloadChapter.effectiveRequestId]
  /// - [DownloadChapter.order] 的字符串形式
  bool matches(DownloadChapter chapter, String target) {
    final normalized = target.trim();
    if (normalized.isEmpty) return false;

    return chapter.id == normalized ||
        chapter.effectiveRequestId == normalized ||
        chapter.order.toString() == normalized;
  }

  /// 在列表中查找第一个匹配的章节。
  DownloadChapter? find(
    List<DownloadChapter> chapters,
    String target, {
    bool fallbackToFirst = false,
  }) {
    for (final chapter in chapters) {
      if (matches(chapter, target)) return chapter;
    }
    if (fallbackToFirst && chapters.isNotEmpty) {
      return chapters.first;
    }
    return null;
  }

  /// 按 order 查找章节。
  DownloadChapter? findByOrder(List<DownloadChapter> chapters, int order) {
    for (final chapter in chapters) {
      if (chapter.order == order) return chapter;
    }
    return null;
  }
}
