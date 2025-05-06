import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';

import '../../../../../network/http/bika/http_request.dart';
import '../../../json/bika/comic_info/comic_info.dart';

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

      var comicInfo = await _getComicInfo(event.comicId);

      emit(
        state.copyWith(
          status: GetComicInfoStatus.success,
          comicInfo: comicInfo.data.comic,
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

  Future<ComicInfo> _getComicInfo(String comicId) async {
    var result = await getComicInfo(comicId);

    // 打补丁
    result['data']['comic']['_creator']['slogan'] ??= "";
    result['data']['comic']['_creator']['title'] ??= '';
    result['data']['comic']['_creator']['verified'] ??= false;
    result['data']['comic']['chineseTeam'] ??= "";
    result['data']['comic']['description'] ??= "";
    result['data']['comic']['totalComments'] ??=
        result['data']['comic']['commentsCount'] ?? 0;
    result['data']['comic']['author'] ??= '';
    result['data']['comic']['_creator']['avatar'] ??= {
      "fileServer": "",
      "path": "",
      "originalName": "",
    };

    var comicInfo = ComicInfo.fromJson(result);
    return comicInfo;
  }
}
