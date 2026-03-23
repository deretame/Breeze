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
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;
import 'package:zephyr/page/comic_info/models/to_normal_info.dart';
import 'package:zephyr/type/enum.dart';

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
        comicInfo = objectbox.unifiedDownloadBox
            .query(
              UnifiedComicDownload_.uniqueKey.equals(
                '${event.from.name}:${event.comicId}',
              ),
            )
            .build()
            .findFirst();
        if (comicInfo == null) {
          if (event.from == From.bika) {
            comicInfo = await getBikaComicAllInfo(event.comicId, event.type);
            normalComicInfo = bika2NormalComicAllInfo(comicInfo);
          } else {
            comicInfo = await getJmComicAllInfo(event.comicId, event.type);
            normalComicInfo = jm2NormalComicAllInfo(comicInfo);
          }
        } else {
          normalComicInfo = normal.NormalComicAllInfo.fromJson(
            jsonDecode((comicInfo as UnifiedComicDownload).detailJson)
                as Map<String, dynamic>,
          );
          final localCover = Map<String, dynamic>.from(
            jsonDecode(jsonEncode(normalComicInfo.comicInfo.cover.toJson()))
                as Map<String, dynamic>,
          );
          final localCoverExtension = Map<String, dynamic>.from(
            localCover['extension'] as Map? ?? const <String, dynamic>{},
          );
          final coverPath = localCoverExtension['path']?.toString() ??
              normalComicInfo.comicInfo.cover.name;
          if (coverPath.isNotEmpty) {
            localCoverExtension['path'] = p.join(
              comicInfo.storageRoot,
              'cover',
              coverPath,
            );
          }
          localCover['extension'] = localCoverExtension;

          final localCreator = Map<String, dynamic>.from(
            jsonDecode(jsonEncode(normalComicInfo.comicInfo.creator.toJson()))
                as Map<String, dynamic>,
          );
          localCreator['avatar'] = {
            'id': '',
            'url': '',
            'name': '',
            'extension': <String, dynamic>{},
          };

          final localComicInfo = Map<String, dynamic>.from(
            jsonDecode(jsonEncode(normalComicInfo.comicInfo.toJson()))
                as Map<String, dynamic>,
          )
            ..['cover'] = localCover
            ..['creator'] = localCreator;

          normalComicInfo = normalComicInfo.copyWith(
            comicInfo: normal.ComicInfo.fromJson(localComicInfo),
          );
        }
      } else {
        final pluginResult = await getComicDetailByPlugin(
          event.comicId,
          event.from,
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
}
