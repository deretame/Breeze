import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/page/jm/jm_week_ranking/json/jm_week_ranking_json.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/json/json_dispose.dart';

part 'week_ranking_event.dart';
part 'week_ranking_state.dart';
part 'week_ranking_bloc.freezed.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class WeekRankingBloc extends Bloc<WeekRankingEvent, WeekRankingState> {
  WeekRankingBloc() : super(WeekRankingState()) {
    on<WeekRankingEvent>(
      _fetchList,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  List<ListElement> list = [];
  int total = 0;
  bool hasReachedMax = false;

  Future<void> _fetchList(
    WeekRankingEvent event,
    Emitter<WeekRankingState> emit,
  ) async {
    if (event.status == JmRankingStatus.initial) {
      emit(state.copyWith(status: JmRankingStatus.initial));
      list = [];
      hasReachedMax = false;
    }

    if (hasReachedMax) return;

    if (event.status == JmRankingStatus.loadingMore) {
      emit(state.copyWith(status: JmRankingStatus.loadingMore, list: list));
    }

    try {
      // 神经，禁漫在没有结果的情况下，total字段是数字，而不是字符串
      final response = await getWeekRanking(event.date, event.type, event.page);
      if (response['error'] == '没有资料') {
        hasReachedMax = true;
        emit(
          state.copyWith(
            hasReachedMax: hasReachedMax,
            status: JmRankingStatus.success,
          ),
        );
        return;
      }

      final data = response
          .let(replaceNestedNull)
          .let((d) => (d..['total'] = d['total'].toString()))
          .let(jsonEncode)
          .let(jmWeekRankingJsonFromJson);
      list = [...list, ...data.list];

      emit(
        state.copyWith(
          status: JmRankingStatus.success,
          list: list,
          hasReachedMax: hasReachedMax,
          result: event.page.toString(),
        ),
      );
    } catch (e, stackTrace) {
      logger.e(e, stackTrace: stackTrace);
      if (list.isNotEmpty) {
        emit(
          state.copyWith(
            status: JmRankingStatus.loadingMoreFailure,
            list: list,
            hasReachedMax: hasReachedMax,
            result: e.toString(),
          ),
        );
        return;
      }

      emit(
        state.copyWith(status: JmRankingStatus.failure, result: e.toString()),
      );
    }
  }
}
