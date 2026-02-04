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

  final data = await search(event.searchStates.searchKeyword, sort, event.page)
      .let(replaceNestedNull)
      .let((d) => (d..['total'] = d['total'].toString()))
      .let(JmSearchResultJson.fromJson);
  if (data.content.isEmpty) {
    blocState.hasReachedMax = true;
  }
  var tempList = data.content
      .map(
        (e) => ComicNumber(buildNumber: event.page, comicInfo: ComicInfo.jm(e)),
      )
      .toList();

  blocState.comics = [...blocState.comics, ...tempList];

  return blocState;
}
