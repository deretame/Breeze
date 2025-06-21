import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/page/jm/jm_promote/json/promote/jm_promote_json.dart';
import 'package:zephyr/page/jm/jm_promote/json/suggestion/jm_suggestion_json.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/json_dispose.dart';

part 'promote_event.dart';
part 'promote_state.dart';
part 'promote_bloc.freezed.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class PromoteBloc extends Bloc<PromoteEvent, PromoteState> {
  PromoteBloc() : super(PromoteState()) {
    on<PromoteEvent>(
      _fetchPromote,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  List<JmPromoteJson> list = [];
  List<JmSuggestionJson> suggestionList = [];

  Future<void> _fetchPromote(
    PromoteEvent event,
    Emitter<PromoteState> emit,
  ) async {
    if (event.status == PromoteStatus.initial) {
      emit(
        state.copyWith(
          status: PromoteStatus.initial,
          list: [],
          suggestionList: [],
        ),
      );
    }

    int page = 0;
    if (event.page != -1) {
      page = event.page;
    }
    if (event.status == PromoteStatus.initial) {
      page = -1;
    }

    try {
      if (page == -1) {
        list = await getPromote()
            .let(replaceNestedNullList)
            .let((d) {
              var data =
                  (d).map((item) => item as Map<String, dynamic>).toList();

              data.removeWhere((e) => e['title'] == '禁漫书库');
              data.removeWhere((e) => e['title'] == '禁漫去码&全彩化');
              return data;
            })
            .let(jsonEncode)
            .let(jmPromoteJsonFromJson);
      } else {
        emit(
          state.copyWith(
            status: PromoteStatus.loadingMore,
            list: list,
            suggestionList: suggestionList,
          ),
        );
        final temp = await getSuggestion(page)
            .let(replaceNestedNullList)
            .let(jsonEncode)
            .let(jmSuggestionJsonFromJson);
        suggestionList = [...suggestionList, ...temp];
      }

      emit(
        state.copyWith(
          status: PromoteStatus.success,
          list: list,
          suggestionList: suggestionList,
          result: page.toString(),
        ),
      );
    } catch (e, stackTrace) {
      logger.e(e, stackTrace: stackTrace);

      if (list.isNotEmpty) {
        emit(
          state.copyWith(
            status: PromoteStatus.loadingMoreFailure,
            list: list,
            suggestionList: suggestionList,
            result: e.toString(),
          ),
        );
        return;
      }

      emit(state.copyWith(status: PromoteStatus.failure, result: e.toString()));
    }
  }
}
