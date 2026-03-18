import 'package:zephyr/page/comic_info/json/bika/comic_info/comic_info.dart'
    as bika;
import 'package:zephyr/page/comic_info/json/bika/eps/eps.dart' as bika_eps;
import 'package:zephyr/page/comic_info/json/jm/jm_comic_info_json.dart'
    as jm;
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/page/comic_info/models/all_info.dart';
import 'package:zephyr/type/enum.dart';

class UnifiedComicDownloadChapter {
  const UnifiedComicDownloadChapter({
    required this.id,
    required this.title,
    required this.order,
    required this.taskChapterId,
    required this.persistedKey,
  });

  final String id;
  final String title;
  final int order;
  final String taskChapterId;
  final String persistedKey;
}

class UnifiedComicDownloadInfo {
  const UnifiedComicDownloadInfo({
    required this.source,
    required this.comicId,
    required this.title,
    required this.chapters,
  });

  final String source;
  final String comicId;
  final String title;
  final List<UnifiedComicDownloadChapter> chapters;

  factory UnifiedComicDownloadInfo.fromPluginSource(
    PluginComicDetailSource source,
  ) {
    final chapters = resolveUnifiedComicChapters(source, source.from)
        .map(
          (chapter) => UnifiedComicDownloadChapter(
            id: chapter.id,
            title: chapter.name,
            order: chapter.sort,
            taskChapterId: source.isBika
                ? chapter.sort.toString()
                : chapter.routeOrder.toString(),
            persistedKey: source.isBika ? chapter.name : chapter.id,
          ),
        )
        .toList();

    if (source.isJm && chapters.isEmpty) {
      return UnifiedComicDownloadInfo(
        source: 'jm',
        comicId: source.comicId,
        title: source.title,
        chapters: [
          UnifiedComicDownloadChapter(
            id: source.comicId,
            title: source.title,
            order: _toInt(source.comicId, 1),
            taskChapterId: source.comicId,
            persistedKey: source.comicId,
          ),
        ],
      );
    }

    return UnifiedComicDownloadInfo(
      source: source.from.name,
      comicId: source.comicId,
      title: source.normalInfo.comicInfo.title,
      chapters: chapters,
    );
  }

  factory UnifiedComicDownloadInfo.fromBikaLegacy(
    bika.Comic comicInfo,
    List<bika_eps.Doc> epsInfo,
  ) {
    return UnifiedComicDownloadInfo(
      source: 'bika',
      comicId: comicInfo.id,
      title: comicInfo.title,
      chapters: epsInfo
          .map(
            (ep) => UnifiedComicDownloadChapter(
              id: ep.id,
              title: ep.title,
              order: ep.order,
              taskChapterId: ep.order.toString(),
              persistedKey: ep.title,
            ),
          )
          .toList(),
    );
  }

  factory UnifiedComicDownloadInfo.fromJmLegacy(jm.JmComicInfoJson comicInfo) {
    final series = comicInfo.series.isEmpty
        ? [
            jm.Series(
              id: comicInfo.id.toString(),
              name: comicInfo.name,
              sort: '1',
            ),
          ]
        : comicInfo.series;

    return UnifiedComicDownloadInfo(
      source: 'jm',
      comicId: comicInfo.id.toString(),
      title: comicInfo.name,
      chapters: series
          .map(
            (chapter) => UnifiedComicDownloadChapter(
              id: chapter.id,
              title: chapter.name,
              order: _toInt(chapter.sort, _toInt(chapter.id, 1)),
              taskChapterId: chapter.id,
              persistedKey: chapter.id,
            ),
          )
          .toList(),
    );
  }
}

UnifiedComicDownloadInfo resolveUnifiedDownloadInfo(
  dynamic comicInfo,
  From from,
) {
  if (comicInfo is PluginComicDetailSource) {
    return UnifiedComicDownloadInfo.fromPluginSource(comicInfo);
  }

  if (from == From.bika && comicInfo is AllInfo) {
    return UnifiedComicDownloadInfo.fromBikaLegacy(
      comicInfo.comicInfo,
      comicInfo.eps,
    );
  }

  if (from == From.jm && comicInfo is jm.JmComicInfoJson) {
    return UnifiedComicDownloadInfo.fromJmLegacy(comicInfo);
  }

  throw StateError('无法解析下载信息: ${comicInfo.runtimeType}');
}

int _toInt(String value, int fallback) {
  return int.tryParse(value) ?? fallback;
}
