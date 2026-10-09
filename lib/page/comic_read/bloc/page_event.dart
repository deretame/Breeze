import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/page/comic_read/type/chapter_extern.dart';
import 'package:zephyr/type/enum.dart';

part 'page_event.freezed.dart';

@freezed
abstract class PageEvent with _$PageEvent {
  const factory PageEvent(
    String comicId,
    int epsId,
    String chapterId,
    String requestId,
    String storageChapterId,
    String logicalKey,
    ChapterExtern chapterExtern,
    String from,
    ComicEntryType type, {
    dynamic comicInfo,
  }) = _PageEvent;
}
