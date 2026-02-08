import 'package:zephyr/widgets/comic_entry/comic_entry_info.dart'
    as comic_entry_info;

import '../json/favorite/favourite_json.dart';

class ComicNumber {
  final int buildNumber;
  final Doc doc;

  ComicNumber({required this.buildNumber, required this.doc});
}

extension DocConversion on Doc {
  comic_entry_info.ComicEntryInfo toComicEntryInfo() {
    return comic_entry_info.ComicEntryInfo(
      id: id,
      title: title,
      author: author,
      likesCount: likesCount,
      finished: finished,
      categories: categories,

      thumb: comic_entry_info.Thumb(
        fileServer: thumb.fileServer,
        path: thumb.path,
        originalName: thumb.originalName,
      ),

      description: "",
      chineseTeam: "",
      tags: [],
      updatedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }
}
