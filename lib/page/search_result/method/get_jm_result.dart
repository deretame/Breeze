import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/page/search_result/json/jm/jm_search_result_json.dart';
import 'package:zephyr/page/search_result/models/bloc_state.dart';
import 'package:zephyr/page/search_result/models/comic_number.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/json/json_dispose.dart';

Future<BlocState> getJMResult(SearchEvent event, BlocState blocState) async {
  final sort = switch (event.searchStates.sortBy) {
    1 => '',
    2 => 'mv',
    3 => 'mp',
    4 => 'tf',
    _ => '',
  };

  // 禁漫这个接口真是问题一堆的还要什么没什么
  final data = await search(event.searchStates.searchKeyword, sort, event.page)
      .let(replaceNestedNull)
      .let((d) => (d..['total'] = d['total'].toString()))
      .let(JmSearchResultJson.fromJson);

  if (data.content.isEmpty) {
    blocState.hasReachedMax = true;
    return blocState;
  }

  var tempList = data.content
      .map(
        (e) => ComicNumber(buildNumber: event.page, comicInfo: ComicInfo.jm(e)),
      )
      .toList();

  if (blocState.comics.any(
    (c) => c.comicInfo.id == tempList.first.comicInfo.id,
  )) {
    blocState.hasReachedMax = true;
    return blocState;
  }

  blocState.pagesCount = event.page;

  blocState.comics = [...blocState.comics, ...tempList];

  return blocState;
}

extension ComicInfoX on ComicInfo {
  String get id => when(bika: (b) => b.id, jm: (j) => j.id);
}
