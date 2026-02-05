import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/bika/http_request.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/page/search_result/json/bika/advanced_search.dart';
import 'package:zephyr/page/search_result/models/bloc_state.dart';
import 'package:zephyr/page/search_result/models/comic_number.dart';

Future<BlocState> getBikaResult(SearchEvent event, BlocState blocState) async {
  final sort = switch (event.searchStates.sortBy) {
    1 => 'dd',
    2 => 'da',
    3 => 'ld',
    4 => 'vd',
    _ => 'dd',
  };

  logger.d(event.page);

  final categories = event.searchStates.categories.entries
      .where((e) => e.value)
      .map((e) => e.key)
      .toList();

  final result = await search(
    url: event.url,
    keyword: event.searchStates.searchKeyword,
    sort: sort,
    categories: categories,
    pageCount: event.page,
  );

  return _processSearchResult(result, blocState);
}

Future<BlocState> _processSearchResult(
  Map<String, dynamic> result,
  BlocState blocState,
) async {
  if (result['data']['comics'] is List) {
    result['data'] = {
      "comics": {"docs": result['data']["comics"]},
    };
  }

  _setDefaultValues(result['data']['comics']);

  var temp = AdvancedSearch.fromJson(result);
  blocState.pagesCount = temp.data.comics.page;
  if (blocState.pagesCount >= temp.data.comics.pages) {
    blocState.hasReachedMax = true;
  }

  var tempList = temp.data.comics.docs
      .map(
        (doc) => ComicNumber(
          buildNumber: temp.data.comics.page,
          comicInfo: ComicInfo.bika(doc),
        ),
      )
      .toList();

  blocState.comics = [...blocState.comics, ...tempList];

  return blocState;
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
