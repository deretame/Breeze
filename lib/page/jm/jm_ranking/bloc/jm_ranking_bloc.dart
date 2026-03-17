import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/json/json_dispose.dart';

part 'jm_ranking_event.dart';
part 'jm_ranking_state.dart';
part 'jm_ranking_bloc.freezed.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class JmRankingBloc extends Bloc<JmRankingEvent, JmRankingState> {
  JmRankingBloc() : super(JmRankingState()) {
    on<JmRankingEvent>(
      _fetchList,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  List<Map<String, dynamic>> list = [];
  int total = 0;
  bool hasReachedMax = false;

  Future<void> _fetchList(
    JmRankingEvent event,
    Emitter<JmRankingState> emit,
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
      final pluginResponse = await callUnifiedComicPlugin(
        from: From.jm,
        fnPath: 'getRankingData',
        core: {'page': event.page},
        extern: {'type': event.type, 'order': event.order, 'source': 'ranking'},
      );
      final envelope = UnifiedPluginEnvelope.fromMap(pluginResponse);
      final data = asMap(envelope.data);
      final raw = replaceNestedNullList(asMap(data['raw']));
      final content = asList(raw['content'])
          .map((item) => asMap(item))
          .toList();

      list = [
        ...list,
        ...content.map((item) => Map<String, dynamic>.from(item)),
      ];
      total = toInt(raw['total']);
      hasReachedMax =
          data['hasReachedMax'] == true ||
          content.isEmpty ||
          (total > 0 && list.length >= total);

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
