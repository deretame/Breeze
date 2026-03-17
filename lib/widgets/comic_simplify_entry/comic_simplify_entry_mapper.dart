import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/type/enum.dart';

import 'comic_simplify_entry_info.dart';

ComicSimplifyEntryInfo createBikaComicSimplifyEntryInfo({
  required String title,
  required String id,
  required String fileServer,
  required String path,
  PictureType pictureType = PictureType.cover,
}) {
  return ComicSimplifyEntryInfo(
    title: title,
    id: id,
    fileServer: fileServer,
    path: path,
    pictureType: pictureType,
    from: From.bika,
  );
}

ComicSimplifyEntryInfo createJmComicSimplifyEntryInfo({
  required String title,
  required String id,
  PictureType pictureType = PictureType.cover,
}) {
  return ComicSimplifyEntryInfo(
    title: title,
    id: id,
    fileServer: getJmCoverUrl(id),
    path: '$id.jpg',
    pictureType: pictureType,
    from: From.jm,
  );
}

List<ComicSimplifyEntryInfo> mapToBikaComicSimplifyEntryInfoList<T>(
  Iterable<T> items, {
  required String Function(T item) title,
  required String Function(T item) id,
  required String Function(T item) fileServer,
  required String Function(T item) path,
  PictureType pictureType = PictureType.cover,
}) {
  return items
      .map(
        (item) => createBikaComicSimplifyEntryInfo(
          title: title(item),
          id: id(item),
          fileServer: fileServer(item),
          path: path(item),
          pictureType: pictureType,
        ),
      )
      .toList();
}

List<ComicSimplifyEntryInfo> mapToJmComicSimplifyEntryInfoList<T>(
  Iterable<T> items, {
  required String Function(T item) title,
  required String Function(T item) id,
  PictureType pictureType = PictureType.cover,
}) {
  return items
      .map(
        (item) => createJmComicSimplifyEntryInfo(
          title: title(item),
          id: id(item),
          pictureType: pictureType,
        ),
      )
      .toList();
}

List<ComicSimplifyEntryInfo> mapToUnifiedComicSimplifyEntryInfoList(
  Iterable<Map<String, dynamic>> items,
) {
  return items.map((item) {
    final source = item['source']?.toString() ?? '';
    final id = item['id']?.toString() ?? '';
    final title = item['title']?.toString() ?? '';

    if (source == 'bika') {
      final cover = (item['cover'] is Map)
          ? Map<String, dynamic>.from(
              (item['cover'] as Map).map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            )
          : const <String, dynamic>{};

      return createBikaComicSimplifyEntryInfo(
        title: title,
        id: id,
        fileServer: cover['url']?.toString() ?? '',
        path: cover['path']?.toString() ?? '',
      );
    }

    return createJmComicSimplifyEntryInfo(title: title, id: id);
  }).toList();
}
