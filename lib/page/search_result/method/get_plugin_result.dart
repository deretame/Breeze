import 'package:zephyr/model/unified_comic_list_item_mapper.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/page/search_result/models/bloc_state.dart';
import 'package:zephyr/page/search_result/models/comic_number.dart';
import 'package:zephyr/type/enum.dart';

Future<BlocState> getPluginSearchResult(
  SearchEvent event,
  BlocState blocState,
) async {
  final response = await callUnifiedComicPlugin(
    from: event.searchStates.from,
    fnPath: 'searchComic',
    core: {'keyword': event.searchStates.searchKeyword, 'page': event.page},
    extern: {
      'url': event.url,
      'sortBy': event.searchStates.sortBy,
      'sort': _sortBySource(event.searchStates.from, event.searchStates.sortBy),
      'categories': event.searchStates.categories,
    },
  );
  final parsed = UnifiedPluginSearchResponse.fromMap(response);

  final list = parsed.items
      .map((item) => _toUnifiedComic(item, event.page, parsed.source))
      .toList();

  blocState.pagesCount = parsed.paging.page;
  blocState.hasReachedMax = parsed.paging.hasReachedMax;
  blocState.comics = [...blocState.comics, ...list];
  return blocState;
}

ComicNumber _toUnifiedComic(
  UnifiedPluginSearchItem item,
  int page,
  String source,
) {
  return ComicNumber(
    buildNumber: page,
    comic: unifiedComicFromPluginSearchItem(item, source),
  );
}

String _sortBySource(From from, int sortBy) {
  if (from == From.bika) {
    return switch (sortBy) {
      1 => 'dd',
      2 => 'da',
      3 => 'ld',
      4 => 'vd',
      _ => 'dd',
    };
  }

  return switch (sortBy) {
    1 => '',
    2 => 'mv',
    3 => 'mp',
    4 => 'tf',
    _ => '',
  };
}
