import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/settings_hive_utils.dart';
import 'package:zephyr/util/sundry.dart';

import '../../../../util/json/json_dispose.dart';
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
    if (event.keyword.isEmpty) {
      emit(
        state.copyWith(
          status: JmSearchResultStatus.success,
          jmSearchResults: [],
          hasReachedMax: false,
          result: '请输入搜索关键词',
        ),
      );
      return;
    }

    if (event.status == JmSearchResultStatus.initial) {
      hasReachedMax = false;
      _searchResultList = [];
      page = 1;
      emit(state.copyWith(status: JmSearchResultStatus.initial));
    }

    if (hasReachedMax) return;

    if (event.status == JmSearchResultStatus.loadingMore) {
      emit(
        state.copyWith(
          status: JmSearchResultStatus.loadingMore,
          jmSearchResults: _searchResultList,
        ),
      );
    }

    try {
      // 神经，禁漫在没有结果的情况下，total字段是数字，而不是字符串
      final data = await search(event.keyword, event.sort, page)
          .let(replaceNestedNull)
          .let((d) => (d..['total'] = d['total'].toString()))
          .let(JmSearchResultJson.fromJson);

      _searchResultList = [..._searchResultList, ...data.content];

      hasReachedMax = _searchResultList.length == int.parse(data.total);

      emit(
        state.copyWith(
          status: JmSearchResultStatus.success,
          jmSearchResults: _searchResultList.let(deleteMaskedContent),
          hasReachedMax: hasReachedMax,
          result: data.total,
        ),
      );
      page++;
      return;
    } catch (e, s) {
      logger.e(e, stackTrace: s);
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
          jmSearchResults: _searchResultList.let(deleteMaskedContent),
          result: e.toString(),
        ),
      );
    }
  }

  List<Content> deleteMaskedContent(List<Content> contentList) {
    final maskedKeywords = SettingsHiveUtils.maskedKeywords
        .where((keyword) => keyword.trim().isNotEmpty)
        .toList();

    return contentList.where((content) {
      final allText = [
        content.name,
        content.author,
        content.category.title,
        content.categorySub.title,
      ].join().toLowerCase().let(t2s);

      final containsKeyword = maskedKeywords.any(
        (keyword) => allText.contains(keyword.toLowerCase().let(t2s)),
      );

      return !containsKeyword;
    }).toList();
  }
}
