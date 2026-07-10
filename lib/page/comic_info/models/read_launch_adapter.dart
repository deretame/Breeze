import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/i18n/strings.g.dart';

String resolveReadComicId(
  dynamic comicInfo,
  String _, {
  required bool isDownload,
}) {
  if (!isDownload && comicInfo is PluginComicDetailSource) {
    return comicInfo.comicId;
  }

  if (comicInfo is UnifiedComicDownload) {
    return comicInfo.comicId;
  }

  throw StateError(
    t.comicInfo.resolveComicIdFailed(type: comicInfo.runtimeType.toString()),
  );
}

int resolveReadEpsCount(
  dynamic comicInfo,
  String _, {
  required bool isDownload,
}) {
  if (!isDownload && comicInfo is PluginComicDetailSource) {
    return comicInfo.normalInfo.eps.length;
  }

  if (comicInfo is UnifiedComicDownload) {
    return comicInfo.chapters.length;
  }

  throw StateError(
    t.comicInfo.resolveEpsCountFailed(type: comicInfo.runtimeType.toString()),
  );
}
