import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/page/search_result/json/bika/advanced_search.dart' as bika;
import 'package:zephyr/page/search_result/json/jm/jm_search_result_json.dart' as jm;
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
    core: {
      'keyword': event.searchStates.searchKeyword,
      'page': event.page,
    },
    extern: {
      'url': event.url,
      'sortBy': event.searchStates.sortBy,
      'sort': _sortBySource(event.searchStates.from, event.searchStates.sortBy),
      'categories': event.searchStates.categories,
    },
  );
  final parsed = UnifiedPluginSearchResponse.fromMap(response);

  final source = event.searchStates.from;
  final list = source == From.bika
      ? _toBikaComicNumbers(parsed.items, event.page)
      : _toJmComicNumbers(parsed.items, event.page);

  if (source == From.jm && list.isNotEmpty) {
    final firstNewId = list.first.comicInfo.id;
    if (blocState.comics.any((item) => item.comicInfo.id == firstNewId)) {
      blocState.hasReachedMax = true;
      return blocState;
    }
  }

  blocState.pagesCount = parsed.paging.page;
  blocState.hasReachedMax = parsed.paging.hasReachedMax;
  blocState.comics = [...blocState.comics, ...list];
  return blocState;
}

List<ComicNumber> _toBikaComicNumbers(
  List<UnifiedPluginSearchItem> items,
  int page,
) {
  return items.map((item) {
    final doc = bika.Doc.fromJson(_normalizeBikaDoc(item.raw));
    return ComicNumber(buildNumber: page, comicInfo: ComicInfo.bika(doc));
  }).toList();
}

List<ComicNumber> _toJmComicNumbers(
  List<UnifiedPluginSearchItem> items,
  int page,
) {
  return items.map((item) {
    final content = jm.Content.fromJson(_normalizeJmContent(item.raw));
    return ComicNumber(buildNumber: page, comicInfo: ComicInfo.jm(content));
  }).toList();
}

Map<String, dynamic> _normalizeBikaDoc(Map<String, dynamic> doc) {
  return {
    'updated_at': doc['updated_at'] ?? '1970-01-01T00:00:00.000Z',
    'thumb': {
      'originalName': asMap(doc['thumb'])['originalName'] ?? '',
      'path': asMap(doc['thumb'])['path'] ?? '',
      'fileServer': asMap(doc['thumb'])['fileServer'] ?? '',
    },
    'author': doc['author'] ?? '',
    'description': doc['description'] ?? '',
    'chineseTeam': doc['chineseTeam'] ?? '',
    'created_at': doc['created_at'] ?? '1970-01-01T00:00:00.000Z',
    'finished': doc['finished'] == true,
    'categories': asList(doc['categories']).map((e) => e.toString()).toList(),
    'title': doc['title'] ?? '',
    'tags': asList(doc['tags']).map((e) => e.toString()).toList(),
    '_id': doc['_id'] ?? doc['id'] ?? '',
    'likesCount': (doc['likesCount'] as num?)?.toInt() ?? 0,
  };
}

Map<String, dynamic> _normalizeJmContent(Map<String, dynamic> raw) {
  final category = asMap(raw['category']);
  final categorySub = asMap(raw['category_sub']);
  return {
    'id': raw['id']?.toString() ?? '',
    'author': raw['author']?.toString() ?? '',
    'description': raw['description'] ?? '',
    'name': raw['name']?.toString() ?? '',
    'image': raw['image']?.toString() ?? '',
    'category': {
      'id': category['id']?.toString() ?? '',
      'title': category['title']?.toString() ?? '',
    },
    'category_sub': {
      'id': categorySub['id']?.toString(),
      'title': categorySub['title']?.toString(),
    },
    'liked': raw['liked'] == true,
    'is_favorite': raw['is_favorite'] == true,
    'update_at': (raw['update_at'] as num?)?.toInt() ?? 0,
  };
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

extension _ComicInfoX on ComicInfo {
  String get id => when(bika: (b) => b.id, jm: (j) => j.id);
}
