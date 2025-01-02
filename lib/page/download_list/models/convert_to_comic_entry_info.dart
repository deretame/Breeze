import '../../../object_box/model.dart';
import '../../../widgets/comic_entry/comic_entry_info.dart';

ComicEntryInfo convertToComicEntryInfo(BikaComicDownload comicDownload) {
  return ComicEntryInfo(
    updatedAt: comicDownload.updatedAt,
    thumb: Thumb(
      originalName: comicDownload.thumbOriginalName,
      path: comicDownload.thumbPath,
      fileServer: comicDownload.thumbFileServer,
    ),
    author: comicDownload.author,
    description: comicDownload.description,
    chineseTeam: comicDownload.chineseTeam,
    createdAt: comicDownload.createdAt,
    finished: comicDownload.finished,
    categories: comicDownload.categories,
    title: comicDownload.title,
    tags: comicDownload.tags,
    id: comicDownload.comicId,
    likesCount: comicDownload.likesCount,
  );
}
