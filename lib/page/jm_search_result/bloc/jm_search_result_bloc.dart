import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/type/pipe.dart';

import '../../../util/json_dispose.dart';
import '../json/jm_search_result_json.dart';

part 'jm_search_result_event.dart';
part 'jm_search_result_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class JmSearchResultBloc
    extends Bloc<JmSearchResultEvent, JmSearchResultState> {
  JmSearchResultBloc() : super(JmSearchResultState()) {
    on<JmSearchResultEvent>(
      _fetchData,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  List<Content> _searchResultList = [];
  bool hasReachedMax = false;
  int page = 1;

  Future<void> _fetchData(
    JmSearchResultEvent event,
    Emitter<JmSearchResultState> emit,
  ) async {
    if (hasReachedMax) {
      return;
    }

    if (event.status == JmSearchResultStatus.initial) {
      _searchResultList = [];
      emit(state.copyWith(status: JmSearchResultStatus.initial));
    } else if (event.status == JmSearchResultStatus.loadingMore) {
      emit(
        state.copyWith(
          status: JmSearchResultStatus.loadingMore,
          jmSearchResults: _searchResultList,
        ),
      );
    }

    try {
      final data = await search(
        event.keyword,
        event.sort,
        page,
      ).pipe(replaceNestedNull).pipe(JmSearchResultJson.fromJson);

      _searchResultList = [..._searchResultList, ...data.content];

      hasReachedMax = _searchResultList.length == int.parse(data.total);

      emit(
        state.copyWith(
          status: JmSearchResultStatus.success,
          jmSearchResults: _searchResultList,
          hasReachedMax: hasReachedMax,
        ),
      );
      page++;
      return;
    } catch (e) {
      logger.e(e);
      if (_searchResultList.isEmpty) {
        emit(
          state.copyWith(
            status: JmSearchResultStatus.failure,
            result: e.toString(),
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: JmSearchResultStatus.loadingMoreFailure,
          jmSearchResults: _searchResultList,
          result: e.toString(),
        ),
      );
    }
  }
}
