import 'package:zephyr/page/comic_info/method/export_bika.dart';
import 'package:zephyr/page/comic_info/method/export_jm.dart';
import 'package:zephyr/type/enum.dart';

Future<void> exportComic(
  String comicId,
  ExportType type,
  From from, {
  String? path,
}) {
  if (from == From.bika) {
    if (type == ExportType.folder) {
      return bikaExportComicAsFolder(comicId, exportPath: path);
    } else {
      return bikaExportComicAsZip(comicId, exportPath: path);
    }
  } else {
    if (type == ExportType.folder) {
      return jmExportComicAsFolder(comicId, exportPath: path);
    } else {
      return jmExportComicAsZip(comicId, exportPath: path);
    }
  }
}
