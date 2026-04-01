import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/object_box/model.dart';

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

  throw StateError('无法解析阅读 comicId: ${comicInfo.runtimeType}');
}

int resolveReadEpsCount(dynamic comicInfo, String _, {required bool isDownload}) {
  if (!isDownload && comicInfo is PluginComicDetailSource) {
    return comicInfo.normalInfo.eps.length;
  }

  if (comicInfo is UnifiedComicDownload) {
    return comicInfo.chapters?.length ?? 0;
  }

  throw StateError('无法解析阅读章节数: ${comicInfo.runtimeType}');
}
