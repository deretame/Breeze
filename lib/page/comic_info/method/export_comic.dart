import 'package:zephyr/page/comic_info/method/export_bika.dart';
import 'package:zephyr/page/comic_info/method/export_jm.dart';
import 'package:zephyr/type/enum.dart';

Future<void> exportComic(String comicId, ExportType type, From from) async {
  if (from == From.bika) {
    if (type == ExportType.folder) {
      bikaExportComicAsFolder(comicId);
    } else {
      bikaExportComicAsZip(comicId);
    }
  } else {
    if (type == ExportType.folder) {
      jmExportComicAsFolder(comicId);
    } else {
      jmExportComicAsZip(comicId);
    }
  }
}
