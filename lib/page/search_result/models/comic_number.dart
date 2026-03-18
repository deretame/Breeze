import 'package:zephyr/model/unified_comic_list_item.dart';

class ComicNumber {
  ComicNumber({required this.buildNumber, required this.comic});

  final int buildNumber;
  final UnifiedComicListItem comic;

  factory ComicNumber.fromJson(Map<String, dynamic> json) {
    final comicRaw = json['comic'];
    return ComicNumber(
      buildNumber: _toInt(json['buildNumber'], 0),
      comic: UnifiedComicListItem.fromJson(
        comicRaw is Map
            ? Map<String, dynamic>.from(
                comicRaw.map((key, value) => MapEntry(key.toString(), value)),
              )
            : const <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'buildNumber': buildNumber,
    'comic': comic.toJson(),
  };
}

int _toInt(dynamic value, int fallback) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
