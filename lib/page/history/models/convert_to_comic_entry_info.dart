import '../../../object_box/model.dart';
import '../../../widgets/comic_entry/comic_entry_info.dart';

ComicEntryInfo convertToComicEntryInfo(BikaComicHistory comicHistory) {
  return ComicEntryInfo(
    updatedAt: comicHistory.updatedAt,
    thumb: Thumb(
      originalName: comicHistory.thumbOriginalName,
      path: comicHistory.thumbPath,
      fileServer: comicHistory.thumbFileServer,
    ),
    author: comicHistory.author,
    description: comicHistory.description,
    chineseTeam: comicHistory.chineseTeam,
    createdAt: comicHistory.createdAt,
    finished: comicHistory.finished,
    categories: comicHistory.categories,
    title: comicHistory.title,
    tags: comicHistory.tags,
    id: comicHistory.comicId,
    likesCount: comicHistory.likesCount,
  );
}
