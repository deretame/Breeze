import '../../../widgets/comic_entry/comic_entry_info.dart' as comic_entry_info;
import '../json/advanced_search.dart';

class ComicNumber {
  final int buildNumber;
  final Doc doc;

  ComicNumber({required this.buildNumber, required this.doc});
}

comic_entry_info.ComicEntryInfo docToComicEntryInfo(Doc doc) {
  return comic_entry_info.ComicEntryInfo(
    updatedAt: doc.updatedAt,
    thumb: comic_entry_info.Thumb(
      originalName: doc.thumb.originalName,
      path: doc.thumb.path,
      fileServer: doc.thumb.fileServer,
    ),
    author: doc.author,
    description: doc.description,
    chineseTeam: doc.chineseTeam,
    createdAt: doc.createdAt,
    finished: doc.finished,
    categories: doc.categories,
    title: doc.title,
    tags: doc.tags,
    id: doc.id,
    likesCount: doc.likesCount,
  );
}
