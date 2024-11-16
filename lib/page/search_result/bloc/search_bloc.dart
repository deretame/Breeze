import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/network/http/http_request.dart';

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
  int page = -1;
  int pagesCount = 0;
  List<ComicNumber> comics = [];

  Future<void> _fetchComicList(
    FetchSearchResult event,
    Emitter<SearchState> emit,
  ) async {
    // // 如果屏蔽分类更新的话就去掉被屏蔽的漫画并返回结果
    // // 现阶段会出现漫画不见了但是封面不变的状态，搞不定，先搁置了
    // if (event.searchEnterConst.state == "updateShield") {
    //   final filteredComics = _filterShieldedComics(comics);
    //   emit(
    //     state.copyWith(
    //       status: SearchStatus.success,
    //       comics: filteredComics,
    //       hasReachedMax: false,
    //     ),
    //   );
    //   return;
    // }

    if (state.searchEnterConst == event.searchEnterConst && initial == false) {
      return; // 如果状态相同，直接返回，避免再次请求
    }

    if (event.searchEnterConst.pageCount == 1 ||
        event.searchEnterConst.state == "page skip") {
      comics = [];
      emit(
        state.copyWith(
          status: SearchStatus.initial,
        ),
      );
    }

    page = event.searchEnterConst.pageCount;

    if (state.hasReachedMax) return;

    try {
      if (event.searchEnterConst.pageCount != 1 &&
          initial == false &&
          event.searchEnterConst.state != "page skip") {
        emit(
          state.copyWith(
            status: SearchStatus.loadingMore,
            comics: comics,
          ),
        );
      }

      final result = await search(
        url: event.searchEnterConst.url,
        from: event.searchEnterConst.from,
        keyword: event.searchEnterConst.keyword,
        sort: event.searchEnterConst.sort,
        categories: event.searchEnterConst.categories,
        pageCount: event.searchEnterConst.pageCount,
      );

      final comicList = await _processSearchResult(result);
      final hasReachedMax =
          result['data']['comics']['page'] == result['data']['comics']['pages'];

      comics = [...comics, ...comicList];

      // 避免状态污染
      var cleanSearchEnterConst = SearchEnterConst(
        url: event.searchEnterConst.url,
        from: event.searchEnterConst.from,
        keyword: event.searchEnterConst.keyword,
        type: event.searchEnterConst.type,
        state: "",
        sort: event.searchEnterConst.sort,
        categories: event.searchEnterConst.categories,
        pageCount: event.searchEnterConst.pageCount,
        refresh: event.searchEnterConst.refresh,
      );

      emit(
        state.copyWith(
          status: SearchStatus.success,
          comics: comics,
          hasReachedMax: hasReachedMax,
          searchEnterConst: cleanSearchEnterConst,
          pagesCount: pagesCount,
        ),
      );
      initial = false;
    } catch (e) {
      if (comics.isNotEmpty) {
        emit(
          state.copyWith(
            status: SearchStatus.getMoreFailure,
            comics: comics,
            searchEnterConst: event.searchEnterConst,
            result: e.toString(),
          ),
        );
      }

      emit(
        state.copyWith(
          status: SearchStatus.failure,
          searchEnterConst: event.searchEnterConst,
          result: e.toString(),
        ),
      );
    }
  }

  List<ComicNumber> _filterShieldedComics(List<ComicNumber> comics) {
    // 获取所有被屏蔽的分类
    List<String> shieldedCategoriesList = bikaSetting.shieldCategoryMap.entries
        .where((entry) => entry.value) // 只选择值为 true 的条目
        .map((entry) => entry.key) // 提取键（分类名）
        .toList();

    // 过滤掉包含屏蔽分类的漫画
    return comics.where((comic) {
      // 检查该漫画的分类是否与屏蔽分类列表中的任何分类匹配
      return !comic.doc.categories
          .any((category) => shieldedCategoriesList.contains(category));
    }).toList();
  }

  Future<List<ComicNumber>> _processSearchResult(
      Map<String, dynamic> result) async {
    if (result['data']['comics'] is List) {
      result['data'] = {
        "comics": {"docs": result['data']["comics"]}
      };
    }

    _setDefaultValues(result['data']['comics']);

    var results = AdvancedSearch.fromJson(result);

    pagesCount = results.data.comics.pages;

    return _filterShieldedComics(results.data.comics.docs
        .map((doc) => ComicNumber(buildNumber: page, doc: doc))
        .toList());
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