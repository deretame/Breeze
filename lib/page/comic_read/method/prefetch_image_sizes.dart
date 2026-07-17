import 'package:flutter/widgets.dart' show Size;
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/comic_read/cubit/image_size_cubit.dart';
import 'package:zephyr/page/comic_read/json/common_ep_info_json/common_ep_info_json.dart';
import 'package:zephyr/page/comic_read/method/image_header_size.dart';
import 'package:zephyr/page/comic_read/widgets/layout/read_layout.dart';
import 'package:zephyr/type/enum.dart';

/// 后台预解析章节图片尺寸并写入 [ImageSizeCubit]。
///
/// 列表项在图片加载前使用默认占位高度（宽 × 1.2），图片解析出真实尺寸后
/// 高度突变会造成可见的布局跳动（自动平滑滚动时尤其明显）。
/// 本函数在章节就绪后主动解析**已存在于本地**（缓存/下载目录）的图片
/// 文件头尺寸，让列表项高度尽量提前就位；未下载的图片直接跳过
/// （不触发任何网络请求），其尺寸仍走图片显示时的原有上报路径。
Future<void> prefetchChapterImageSizes({
  required ImageSizeCubit imageSizeCubit,
  required List<Doc> docs,
  required String comicId,
  required String from,
  required String chapterId,
  required int chapterOrder,
  required double contentWidth,
}) async {
  for (var i = 0; i < docs.length; i++) {
    if (imageSizeCubit.isClosed) return;

    final cacheIndex = resolveStableSizeCacheIndex(
      chapterOrder: chapterOrder,
      localPageIndex: i,
    );
    if (imageSizeCubit.getSize(cacheIndex).isCached) continue;

    final doc = docs[i];
    final resolvedChapterId = doc.storageChapterId.trim().isNotEmpty
        ? doc.storageChapterId
        : chapterId;

    try {
      final filePath = await findCachedPicturePath(
        from: from,
        path: doc.path,
        cartoonId: comicId,
        chapterId: resolvedChapterId,
        pictureType: PictureType.page,
      );
      if (filePath.isEmpty) continue;

      final rawSize = await readImageHeaderSize(filePath);
      if (rawSize == null || rawSize.width <= 0 || rawSize.height <= 0) {
        continue;
      }
      if (imageSizeCubit.isClosed) return;

      // 与 ImageDisplay 上报保持一致：存渲染宽度 + 等比高度。
      final displayHeight = contentWidth * (rawSize.height / rawSize.width);
      imageSizeCubit.updateSize(
        cacheIndex,
        Size(contentWidth, displayHeight),
      );
    } catch (_) {
      // 单张失败不影响其余图片。
    }
  }
}
