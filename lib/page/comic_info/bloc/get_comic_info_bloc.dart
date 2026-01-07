import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';
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

      if (event.from == From.bika) {
        comicInfo = await getBikaComicAllInfo(event.comicId, event.type);
        normalComicInfo = bika2NormalComicAllInfo(comicInfo);
      } else {
        comicInfo = await getJmComicAllInfo(event.comicId, event.type);
        normalComicInfo = jm2NormalComicAllInfo(comicInfo);
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
