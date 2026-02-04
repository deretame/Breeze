import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/page/search_result/json/bika/advanced_search.dart';
import 'package:zephyr/page/search_result/json/jm/jm_search_result_json.dart';

import '../../../widgets/comic_entry/comic_entry_info.dart' as comic_entry_info;

part 'comic_number.freezed.dart';
part 'comic_number.g.dart';

@freezed
abstract class ComicNumber with _$ComicNumber {
  const factory ComicNumber({
    required int buildNumber,
    required ComicInfo comicInfo,
  }) = _ComicNumber;

  factory ComicNumber.fromJson(Map<String, dynamic> json) =>
      _$ComicNumberFromJson(json);
}

@freezed
sealed class ComicInfo with _$ComicInfo {
  const factory ComicInfo.bika(Doc comics) = Bika;
  const factory ComicInfo.jm(Content comics) = Jm;

  factory ComicInfo.fromJson(Map<String, dynamic> json) =>
      _$ComicInfoFromJson(json);
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
