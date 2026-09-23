import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/comic_info.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;
import 'package:zephyr/page/download/adapters/download_chapter_adapter.dart';
import 'package:zephyr/page/download/models/download_chapter.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/error_filter.dart';

part 'get_comic_info_event.dart';
part 'get_comic_info_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class GetComicInfoBloc extends Bloc<GetComicInfoEvent, GetComicInfoState> {
  GetComicInfoBloc() : super(GetComicInfoState()) {
    on<GetComicInfoEvent>(
      _fetchComicInfo,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  Future<void> _fetchComicInfo(
    GetComicInfoEvent event,
    Emitter<GetComicInfoState> emit,
  ) async {
    try {
      emit(state.copyWith(status: GetComicInfoStatus.initial));

      late normal.NormalComicAllInfo normalComicInfo;
      late String resolvedComicId;
      dynamic comicInfo;

      if (event.type == ComicEntryType.download) {
        comicInfo = objectbox.unifiedDownloadBox
            .query(
              UnifiedComicDownload_.uniqueKey.equals(
                '${event.from}:${event.comicId}',
              ),
            )
            .build()
            .findFirst();
      }

      if (comicInfo == null) {
        final pluginResult = await getComicDetailByPlugin(
          event.comicId,
          event.from,
          extern: event.extern,
        );
        comicInfo = pluginResult.source;
        normalComicInfo = pluginResult.normalInfo;
        resolvedComicId = pluginResult.comicId;
      } else {
        final download = comicInfo as UnifiedComicDownload;
        var localized = _localizeDownloadDetail(download);
        // 下载入口用记录里的目录快照给已下载章节排序（内存里排，不写库）。
        // 快照缺失的章节缀在最后，保证入口不丢。
        final catalog = readChapterCatalog(download);
        if (catalog.isNotEmpty) {
          localized = localized.copyWith(
            eps: _sortEpsByCatalog(localized.eps, catalog),
          );
        }
        normalComicInfo = localized;
        resolvedComicId = download.comicId;
      }

      emit(
        state.copyWith(
          status: GetComicInfoStatus.success,
          allInfo: normalComicInfo,
          comicInfo: comicInfo,
          comicId: resolvedComicId,
        ),
      );
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      emit(
        state.copyWith(
          status: GetComicInfoStatus.failure,
          result: normalizeSearchErrorMessage(e),
        ),
      );
    }
  }

  /// 按目录快照顺序排列本地 eps，快照里没有的缀在最后（保持原相对顺序）。
  List<normal.Ep> _sortEpsByCatalog(
    List<normal.Ep> localEps,
    List<DownloadChapter> catalog,
  ) {
    if (localEps.isEmpty || catalog.isEmpty) return localEps;
    const adapter = DownloadChapterAdapter();
    final chapters = localEps.map(adapter.fromEp).toList();
    final sorted = sortDownloadChaptersByCatalog(chapters, catalog);
    if (identical(sorted, chapters)) return localEps;
    return sorted.map((c) => localEps[chapters.indexOf(c)]).toList();
  }

  normal.NormalComicAllInfo _localizeDownloadDetail(
    UnifiedComicDownload comicInfo,
  ) {
    var normalComicInfo = normal.NormalComicAllInfo.fromJson(
      jsonDecode(comicInfo.detailJson) as Map<String, dynamic>,
    );
    final localCover = _deepCopyMap(normalComicInfo.comicInfo.cover.toJson());

    final localCreator = _deepCopyMap(
      normalComicInfo.comicInfo.creator.toJson(),
    );

    final localComicInfo = _deepCopyMap(normalComicInfo.comicInfo.toJson())
      ..['cover'] = localCover
      ..['creator'] = localCreator;

    return normalComicInfo.copyWith(
      comicInfo: normal.ComicInfo.fromJson(localComicInfo),
    );
  }

  Map<String, dynamic> _deepCopyMap(Object value) {
    final encoded = jsonEncode(value);
    final decoded = jsonDecode(encoded) as Map;
    return Map<String, dynamic>.from(decoded);
  }
}
