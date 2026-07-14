import 'package:flutter/material.dart';
import 'package:zephyr/page/comic_read/widgets/image/read_image_widget.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/page/comic_read/widgets/modes/read_mode_utils.dart';
import 'package:zephyr/widgets/picture_bloc/models/picture_info.dart';

/// 构造列/行模式共用的图片 widget。
///
/// - [slotIndex] 会作为 [ReadImageWidget] 的 `pageSlotIndex`。
/// - [cacheIndex] 会作为 [ReadImageWidget] 的 `sizeCacheIndex`。
/// - [displayNumber] 用于行模式等需要显式页号的场景；为 null 时使用 [slotIndex] + 1。
Widget buildReadModeImage({
  required BuildContext context,
  required ReadModeEntry entry,
  required String comicId,
  required String from,
  required int slotIndex,
  required int cacheIndex,
  required bool isColumn,
  int? displayNumber,
}) {
  if (entry.type != ReadModeEntryType.image ||
      entry.doc == null ||
      entry.chapterId == null) {
    return const SizedBox.shrink();
  }

  final resolvedChapterId = entry.doc!.storageChapterId.trim().isNotEmpty
      ? entry.doc!.storageChapterId
      : entry.chapterId!;

  return ReadImageWidget(
    pictureInfo: PictureInfo(
      from: from,
      url: entry.doc!.fileServer,
      path: entry.doc!.path,
      cartoonId: comicId,
      chapterId: resolvedChapterId,
      pictureType: PictureType.page,
      extern: entry.doc!.extern,
    ),
    index: slotIndex,
    cacheIndex: cacheIndex,
    displayNumber: displayNumber,
    isColumn: isColumn,
  );
}
