import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../../type/enum.dart';
import '../../json/keyword/keywords_json.dart';

part 'search_keyword_event.dart';

part 'search_keyword_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class SearchKeywordBloc extends Bloc<SearchKeywordEvent, SearchKeywordState> {
  SearchKeywordBloc() : super(SearchKeywordState()) {
    on<SearchKeywordEvent>(
      _fetchKeywords,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  Future<void> _fetchKeywords(
    SearchKeywordEvent event,
    Emitter<SearchKeywordState> emit,
  ) async {
    emit(state.copyWith(status: SearchKeywordStatus.initial));

    try {
      final response = await callUnifiedComicPlugin(
        from: From.bika,
        fnPath: 'getHomeData',
        core: const <String, dynamic>{},
        extern: const <String, dynamic>{'source': 'home'},
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      final keywords = KeywordsJson.fromJson(
        {
          'code': 200,
          'message': 'success',
          'data': {
            'keywords': asList(envelope.data['keywords'])
                .map((item) => item.toString())
                .toList(),
          },
        },
      ).data.keywords;

      emit(
        state.copyWith(status: SearchKeywordStatus.success, keywords: keywords),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SearchKeywordStatus.failure,
          result: e.toString(),
        ),
      );
    }
  }
}
