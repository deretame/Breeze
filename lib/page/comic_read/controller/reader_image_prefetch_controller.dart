import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/comic_read/widgets/modes/read_mode_utils.dart';
import 'package:zephyr/type/enum.dart';

/// 负责把当前阅读位置之后的图片提前写入图片缓存。
///
/// 预加载只负责网络/文件缓存，不直接创建图片 Widget，避免把大量图片加入
/// 当前页面的布局树；真正显示时仍由阅读模式 Widget 负责加载和布局。
class ReaderImagePrefetchController {
  final Set<String> _requestedKeys = <String>{};
  bool _disposed = false;

  Future<void> prefetch({
    required List<ReadModeEntry> entries,
    required String comicId,
    required String from,
    required int count,
  }) async {
    if (_disposed || count <= 0 || entries.isEmpty) return;

    for (final entry in entries.take(count)) {
      if (_disposed) return;
      final doc = entry.doc;
      final chapterId = entry.chapterId;
      if (entry.type != ReadModeEntryType.image ||
          doc == null ||
          chapterId == null ||
          chapterId.isEmpty) {
        continue;
      }

      final resolvedChapterId = doc.storageChapterId.trim().isNotEmpty
          ? doc.storageChapterId
          : chapterId;
      final key = _buildKey(
        from: from,
        comicId: comicId,
        chapterId: resolvedChapterId,
        path: doc.path,
      );
      if (!_requestedKeys.add(key)) continue;

      try {
        final cachedPath = await getCachePicture(
          from: from,
          url: doc.fileServer,
          path: doc.path,
          cartoonId: comicId,
          chapterId: resolvedChapterId,
          pictureType: PictureType.page,
          extern: doc.extern,
        );
        if (cachedPath == '404') {
          _requestedKeys.remove(key);
        }
      } catch (_) {
        _requestedKeys.remove(key);
      }
    }
  }

  void dispose() {
    _disposed = true;
    _requestedKeys.clear();
  }

  String _buildKey({
    required String from,
    required String comicId,
    required String chapterId,
    required String path,
  }) => '$from|$comicId|$chapterId|$path';
}
