import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/network/http/bika/http_request.dart';

import '../../../main.dart';
import '../json/advanced_search.dart';
import '../models/models.dart';

part 'search_event.dart';
part 'search_state.dart';

const throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class SearchBloc extends Bloc<FetchSearchResult, SearchState> {
  SearchBloc() : super(SearchState()) {
    on<FetchSearchResult>(
      _fetchComicList,
      transformer: throttleDroppable(throttleDuration),
    );
  }

  bool initial = true;
  bool hasReachedMax = false;
  int pagesCount = 0;
  List<ComicNumber> comics = [];

  Future<void> _fetchComicList(
    FetchSearchResult event,
    Emitter<SearchState> emit,
  ) async {
    if (event.searchEnter.state == "更新屏蔽列表") {
      emit(
        state.copyWith(
          status: SearchStatus.success,
          comics: _filterShieldedComics(comics),
          hasReachedMax: hasReachedMax,
          searchEnter: event.searchEnter.copyWith(state: ""),
          pagesCount: pagesCount,
        ),
      );
      return;
    }

    if (event.searchStatus == SearchStatus.initial) {
      comics = [];
      hasReachedMax = false;
      emit(
        state.copyWith(
          status: SearchStatus.initial,
          searchEnter: event.searchEnter,
        ),
      );
    }

    if (hasReachedMax) return;

    if (event.searchStatus == SearchStatus.loadingMore) {
      emit(
        state.copyWith(
          status: SearchStatus.loadingMore,
          comics: _filterShieldedComics(comics),
          hasReachedMax: hasReachedMax,
          searchEnter: event.searchEnter,
          pagesCount: pagesCount,
        ),
      );
    }

    try {
      final result = await search(
        url: event.searchEnter.url,
        from: event.searchEnter.from,
        keyword: event.searchEnter.keyword,
        sort: event.searchEnter.sort,
        categories: event.searchEnter.categories,
        pageCount: event.searchEnter.pageCount,
      );

      final processedResult = await _processSearchResult(result);
      hasReachedMax =
          result['data']['comics']['page'] >= result['data']['comics']['pages'];

      comics = [...comics, ...processedResult];

      emit(
        state.copyWith(
          status: SearchStatus.success,
          comics: _filterShieldedComics(comics),
          hasReachedMax: hasReachedMax,
          searchEnter: event.searchEnter,
          pagesCount: pagesCount,
        ),
      );
      initial = false;
    } catch (e) {
      if (comics.isNotEmpty) {
        emit(
          state.copyWith(
            status: SearchStatus.getMoreFailure,
            comics: _filterShieldedComics(comics),
            searchEnter: event.searchEnter,
            pagesCount: pagesCount,
            result: e.toString(),
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: SearchStatus.failure,
          searchEnter: event.searchEnter,
          result: e.toString(),
        ),
      );
    }
  }

  List<ComicNumber> _filterShieldedComics(List<ComicNumber> comics) {
    // 获取有效屏蔽关键词（非空）
    final maskedKeywords =
        globalSetting.maskedKeywords
            .where((keyword) => keyword.trim().isNotEmpty)
            .toList();

    // 获取屏蔽分类
    final shieldedCategories =
        bikaSetting.shieldCategoryMap.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    return comics.where((comic) {
      // 1. 检查屏蔽分类
      final hasShieldedCategory = comic.doc.categories.any(
        (category) => shieldedCategories.contains(category),
      );
      if (hasShieldedCategory) return false;

      // 2. 检查屏蔽关键词
      final allText =
          [
            comic.doc.title,
            comic.doc.author,
            comic.doc.chineseTeam,
            comic.doc.categories.join(),
            comic.doc.tags.join(),
            comic.doc.description,
          ].join().toLowerCase();

      final containsKeyword = maskedKeywords.any(
        (keyword) => allText.contains(keyword.toLowerCase()),
      );

      return !containsKeyword;
    }).toList();
  }

  Future<List<ComicNumber>> _processSearchResult(
    Map<String, dynamic> result,
  ) async {
    if (result['data']['comics'] is List) {
      result['data'] = {
        "comics": {"docs": result['data']["comics"]},
      };
    }

    _setDefaultValues(result['data']['comics']);

    var results = AdvancedSearch.fromJson(result);

    pagesCount = results.data.comics.pages;

    return results.data.comics.docs
        .map(
          (doc) => ComicNumber(buildNumber: results.data.comics.page, doc: doc),
        )
        .toList();
  }

  void _setDefaultValues(Map<String, dynamic> comicsData) {
    comicsData['limit'] ??= 20;
    comicsData['page'] ??= 1;
    comicsData['pages'] ??= 1;
    comicsData['total'] ??= 40;

    for (var doc in comicsData['docs']) {
      doc['id'] ??= doc['_id'];
      doc['updated_at'] ??= '1970-01-01T00:00:00.000Z';
      doc['created_at'] ??= '1970-01-01T00:00:00.000Z';
      doc['description'] ??= '';
      doc['chineseTeam'] ??= '';
      doc['tags'] ??= [];
      doc['author'] ??= "";
      if (doc['likesCount'] is String) {
        doc['likesCount'] = int.parse(doc['likesCount']);
      }
      if (doc['totalLikes'] is String) {
        doc['totalLikes'] = int.parse(doc['totalLikes']);
      }
    }
  }
}
