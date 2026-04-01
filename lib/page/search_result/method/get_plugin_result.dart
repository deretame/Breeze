import 'package:zephyr/model/unified_comic_list_item_mapper.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/plugin/plugin_constants.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/page/search_result/models/bloc_state.dart';
import 'package:zephyr/page/search_result/models/comic_number.dart';

Future<BlocState> getPluginSearchResult(
  SearchEvent event,
  BlocState blocState,
) async {
  final extern = Map<String, dynamic>.from(event.searchStates.pluginExtern);
  final pluginId = sanitizePluginId(
    extern['_pluginId']?.toString().trim().isNotEmpty == true
        ? extern['_pluginId'].toString().trim()
        : sanitizePluginId(event.searchStates.from),
  );
  extern['_pluginId'] = pluginId;
  final response = await callUnifiedComicPlugin(
    pluginId: pluginId,
    fnPath: 'searchComic',
    core: {'keyword': event.searchStates.searchKeyword, 'page': event.page},
    extern: extern,
  );
  final parsed = UnifiedPluginSearchResponse.fromMap(response);

  final list = parsed.items
      .map((item) => _toUnifiedComic(item, event.page, parsed.source))
      .toList();

  blocState.pagesCount = parsed.paging.page;
  blocState.hasReachedMax = parsed.paging.hasReachedMax;
  blocState.comics = [...blocState.comics, ...list];
  blocState.pluginExtern = parsed.extern;
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
