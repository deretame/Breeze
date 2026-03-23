import 'package:zephyr/page/comic_info/json/jm/jm_comic_info_json.dart';
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/page/comic_info/models/all_info.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/type/enum.dart';

String resolveReadComicId(
  dynamic comicInfo,
  From from, {
  required bool isDownload,
}) {
  if (!isDownload && comicInfo is PluginComicDetailSource) {
    return comicInfo.comicId;
  }

  if (from == From.bika && comicInfo is AllInfo) {
    return comicInfo.comicInfo.id;
  }

  if (comicInfo is UnifiedComicDownload) {
    return comicInfo.comicId;
  }

  if (from == From.jm && comicInfo is JmComicInfoJson) {
    return comicInfo.id.toString();
  }

  throw StateError('无法解析阅读 comicId: ${comicInfo.runtimeType}');
}

int resolveReadEpsCount(
  dynamic comicInfo,
  From from, {
  required bool isDownload,
}) {
  if (!isDownload && comicInfo is PluginComicDetailSource) {
    return comicInfo.normalInfo.eps.length;
  }

  if (from == From.bika && comicInfo is AllInfo) {
    return comicInfo.comicInfo.epsCount;
  }

  if (comicInfo is UnifiedComicDownload) {
    return comicInfo.chapters?.length ?? 0;
  }

  if (from == From.jm && comicInfo is JmComicInfoJson) {
    return comicInfo.series.length;
  }

  throw StateError('无法解析阅读章节数: ${comicInfo.runtimeType}');
}
