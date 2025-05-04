import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/type/pipe.dart';

import '../../../../../util/json_dispose.dart';
import '../../json/jm_comic_info/jm_comic_info_json.dart';

part 'jm_comic_info_event.dart';
part 'jm_comic_info_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class JmComicInfoBloc extends Bloc<JmComicInfoEvent, JmComicInfoState> {
  JmComicInfoBloc() : super(JmComicInfoState()) {
    on<JmComicInfoEvent>(
      _fetchData,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  Future<void> _fetchData(
    JmComicInfoEvent event,
    Emitter<JmComicInfoState> emit,
  ) async {
    if (event.status == JmComicInfoStatus.initial) {
      emit(state.copyWith(status: JmComicInfoStatus.initial));
    }

    String str;

    try {
      final comicInfo = await getComicInfo(event.comicId)
          .let(replaceNestedNull)
          .debug((d) => str = jsonEncode(d))
          .let(JmComicInfoJson.fromJson)
          .let((d) {
            var series = d.series.toList();
            series.removeWhere((s) => s.sort == '0');
            final newSeries =
                series
                    .map((s) => s.copyWith(name: '第${s.sort}话 ${s.name}'))
                    .toList();
            return d.copyWith(series: newSeries);
          });

      emit(
        state.copyWith(status: JmComicInfoStatus.success, comicInfo: comicInfo),
      );
    } catch (e) {
      logger.e(e);
      emit(
        state.copyWith(status: JmComicInfoStatus.failure, result: e.toString()),
      );
    }
  }
}
