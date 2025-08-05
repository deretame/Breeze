import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/json_dispose.dart';

import '../json/jm_promote_list_json.dart';

part 'jm_promote_list_event.dart';
part 'jm_promote_list_state.dart';
part 'jm_promote_list_bloc.freezed.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class JmPromoteListBloc extends Bloc<JmPromoteListEvent, JmPromoteListState> {
  JmPromoteListBloc() : super(JmPromoteListState()) {
    on<JmPromoteListEvent>(
      _fetchList,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  List<ListElement> list = [];
  int total = 0;
  bool hasReachedMax = false;

  Future<void> _fetchList(
    JmPromoteListEvent event,
    Emitter<JmPromoteListState> emit,
  ) async {
    if (event.status == JmPromoteListStatus.initial) {
      emit(
        state.copyWith(
          status: JmPromoteListStatus.initial,
          list: [],
          hasReachedMax: false,
        ),
      );
    }

    if (event.status == JmPromoteListStatus.loadingMore) {
      emit(state.copyWith(status: JmPromoteListStatus.loadingMore, list: list));
    }

    try {
      final data = await getPromoteList(event.id, event.page).let(jsonEncode);
      logger.d(data);

      final response = await getPromoteList(event.id, event.page)
          .let(replaceNestedNullList)
          .let(jsonEncode)
          .let(jmPromoteListJsonFromJson);
      list = [...list, ...response.list];
      total = response.total.let(toInt);
      if (total == list.length) hasReachedMax = true;

      emit(
        state.copyWith(
          status: JmPromoteListStatus.success,
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
            status: JmPromoteListStatus.loadingMoreFailure,
            list: list,
            hasReachedMax: hasReachedMax,
            result: e.toString(),
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: JmPromoteListStatus.failure,
          result: e.toString(),
        ),
      );
    }
  }
}
