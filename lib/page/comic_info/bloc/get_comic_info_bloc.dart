import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/comic_info.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;

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
      late dynamic comicInfo;

      if (event.type == ComicEntryType.download) {
        comicInfo =
            objectbox.unifiedDownloadBox
                .query(
                  UnifiedComicDownload_.uniqueKey.equals(
                    '${event.pluginId}:${event.comicId}',
                  ),
                )
                .build()
                .findFirst() ??
            objectbox.unifiedDownloadBox
                .query(
                  UnifiedComicDownload_.uniqueKey.equals(
                    '${event.from}:${event.comicId}',
                  ),
                )
                .build()
                .findFirst();
        if (comicInfo == null) {
          final pluginResult = await getComicDetailByPlugin(
            event.comicId,
            event.from,
            pluginId: event.pluginId,
          );
          comicInfo = pluginResult.source;
          normalComicInfo = pluginResult.normalInfo;
        } else {
          normalComicInfo = _localizeDownloadDetail(
            comicInfo as UnifiedComicDownload,
          );
        }
      } else {
        final pluginResult = await getComicDetailByPlugin(
          event.comicId,
          event.from,
          pluginId: event.pluginId,
        );
        comicInfo = pluginResult.source;
        normalComicInfo = pluginResult.normalInfo;
      }

      emit(
        state.copyWith(
          status: GetComicInfoStatus.success,
          allInfo: normalComicInfo,
          comicInfo: comicInfo,
        ),
      );
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      emit(
        state.copyWith(
          status: GetComicInfoStatus.failure,
          result: e.toString(),
        ),
      );
    }
  }

  normal.NormalComicAllInfo _localizeDownloadDetail(
    UnifiedComicDownload comicInfo,
  ) {
    var normalComicInfo = normal.NormalComicAllInfo.fromJson(
      jsonDecode(comicInfo.detailJson) as Map<String, dynamic>,
    );
    final localCover = _deepCopyMap(normalComicInfo.comicInfo.cover.toJson());
    final coverPath = localCover['path']?.toString().trim() ?? '';
    if (coverPath.isNotEmpty) {
      localCover['path'] = p.join(comicInfo.storageRoot, coverPath);
    }

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
