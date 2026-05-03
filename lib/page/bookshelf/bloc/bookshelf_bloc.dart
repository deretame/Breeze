import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:worker_manager/worker_manager.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/bookshelf/models/search_enter.dart';
import 'package:zephyr/page/bookshelf/models/shelf_page_mode.dart';
import 'package:zephyr/page/bookshelf/service/favorite_folder_service.dart';
import 'package:zephyr/util/error_filter.dart';

const _kPageSize = 200;

enum BookshelfLoadStatus { initial, success, failure }

class BookshelfSectionState extends Equatable {
  const BookshelfSectionState({
    this.status = BookshelfLoadStatus.initial,
    this.comics = const <dynamic>[],
    this.result = '',
    this.total = 0,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.searchEnterConst = const SearchEnter(),
  });

  final BookshelfLoadStatus status;
  final List<dynamic> comics;
  final String result;
  final int total;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final bool loadMoreFailed;
  final SearchEnter searchEnterConst;

  BookshelfSectionState copyWith({
    BookshelfLoadStatus? status,
    List<dynamic>? comics,
    String? result,
    int? total,
    bool? hasReachedMax,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    SearchEnter? searchEnterConst,
  }) {
    return BookshelfSectionState(
      status: status ?? this.status,
      comics: comics ?? this.comics,
      result: result ?? this.result,
      total: total ?? this.total,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      searchEnterConst: searchEnterConst ?? this.searchEnterConst,
    );
  }

  @override
  List<Object> get props => [
    status,
    comics,
    result,
    total,
    hasReachedMax,
    isLoadingMore,
    loadMoreFailed,
    searchEnterConst,
  ];
}

sealed class BookshelfSectionEvent extends Equatable {
  const BookshelfSectionEvent();

  @override
  List<Object> get props => [];
}

class BookshelfLoadRequested extends BookshelfSectionEvent {
  const BookshelfLoadRequested({
    required this.searchEnterConst,
    this.append = false,
  });

  final SearchEnter searchEnterConst;
  final bool append;

  @override
  List<Object> get props => [searchEnterConst, append];
}

class BookshelfItemRemoved extends BookshelfSectionEvent {
  const BookshelfItemRemoved({required this.uniqueKey});

  final String uniqueKey;

  @override
  List<Object> get props => [uniqueKey];
}

class BookshelfSectionBloc
    extends Bloc<BookshelfSectionEvent, BookshelfSectionState> {
  BookshelfSectionBloc({required this.mode})
    : super(const BookshelfSectionState()) {
    on<BookshelfLoadRequested>(_onLoadRequested, transformer: sequential());
    on<BookshelfItemRemoved>(_onItemRemoved);
  }

  final ShelfPageMode mode;

  Future<void> _onLoadRequested(
    BookshelfLoadRequested event,
    Emitter<BookshelfSectionState> emit,
  ) async {
    final current = state;
    final searchChanged = current.searchEnterConst != event.searchEnterConst;

    if (!event.append &&
        !searchChanged &&
        current.status != BookshelfLoadStatus.initial) {
      return;
    }

    if (event.append) {
      if (current.isLoadingMore || current.hasReachedMax) {
        return;
      }
      emit(current.copyWith(isLoadingMore: true, loadMoreFailed: false));
    } else {
      emit(
        current.copyWith(
          status: BookshelfLoadStatus.initial,
          comics: const <dynamic>[],
          total: 0,
          hasReachedMax: false,
          isLoadingMore: false,
          loadMoreFailed: false,
          result: '',
          searchEnterConst: event.searchEnterConst,
        ),
      );
    }

    try {
      final offset = event.append ? current.comics.length : 0;
      final raw = _fetchRawItems(
        search: event.searchEnterConst,
        offset: offset,
        limit: _kPageSize,
      );
      final maskedKeywords = objectbox.userSettingBox
          .get(1)!
          .globalSetting
          .maskedKeywords
          .where((keyword) => keyword.trim().isNotEmpty)
          .toList();

      final response = await workerManager.execute<Map<String, dynamic>>(
        () => _runBookshelfFilterTask({
          'search': {
            'keyword': event.searchEnterConst.keyword,
            'sort': event.searchEnterConst.sort,
            'categories': event.searchEnterConst.categories,
            'sources': event.searchEnterConst.sources,
          },
          'items': raw.items,
          'maskedKeywords': maskedKeywords,
        }),
      );

      final error = response['error']?.toString() ?? '';
      if (error.isNotEmpty) {
        throw Exception(error);
      }

      final pageItems = _decodeItems(response['items']);
      final total = raw.total;
      final hasReachedMax = (offset + raw.items.length) >= total;

      emit(
        current.copyWith(
          status: BookshelfLoadStatus.success,
          comics: event.append ? [...current.comics, ...pageItems] : pageItems,
          total: total,
          hasReachedMax: hasReachedMax,
          isLoadingMore: false,
          loadMoreFailed: false,
          result: total.toString(),
          searchEnterConst: event.searchEnterConst,
        ),
      );
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      if (event.append) {
        emit(current.copyWith(isLoadingMore: false, loadMoreFailed: true));
      } else {
        emit(
          current.copyWith(
            status: BookshelfLoadStatus.failure,
            result: normalizeSearchErrorMessage(e),
            isLoadingMore: false,
            loadMoreFailed: false,
            searchEnterConst: event.searchEnterConst,
          ),
        );
      }
    }
  }

  void _onItemRemoved(
    BookshelfItemRemoved event,
    Emitter<BookshelfSectionState> emit,
  ) {
    final current = state;
    if (current.status != BookshelfLoadStatus.success) {
      return;
    }

    final nextComics = current.comics
        .where((item) => _uniqueKeyOfItem(item) != event.uniqueKey)
        .toList();
    if (nextComics.length == current.comics.length) {
      return;
    }

    final removedCount = current.comics.length - nextComics.length;
    final remaining = current.total - removedCount;
    final nextTotal = remaining < 0 ? 0 : remaining;
    final nextHasReachedMax = nextComics.length >= nextTotal;

    emit(
      current.copyWith(
        comics: nextComics,
        total: nextTotal,
        hasReachedMax: nextHasReachedMax,
        result: nextTotal.toString(),
      ),
    );
  }

  _RawQueryResult _fetchRawItems({
    required SearchEnter search,
    required int offset,
    required int limit,
  }) {
    return switch (mode) {
      ShelfPageMode.favorite => _queryFavoriteRaw(search, offset, limit),
      ShelfPageMode.history => _queryHistoryRaw(search, offset, limit),
      ShelfPageMode.download => _queryDownloadRaw(search, offset, limit),
    };
  }

  _RawQueryResult _queryFavoriteRaw(SearchEnter search, int offset, int limit) {
    final folderKey = FavoriteFolderService.parseFolderKeyFromSources(
      search.sources,
    );
    final sourcesWithoutFolder = FavoriteFolderService.stripFolderSourceTokens(
      search.sources,
    );
    final folderFiltering =
        folderKey != null && folderKey != kFavoriteFolderAllKey;
    final query = objectbox.unifiedFavoriteBox
        .query(
          _favoriteBaseCondition(
            search.copyWith(sources: sourcesWithoutFolder),
          ),
        )
        .order(
          UnifiedComicFavorite_.createdAt,
          flags: search.sort == 'da' ? 0 : Order.descending,
        )
        .build();
    try {
      final total = query.count();
      if (folderFiltering) {
        final all = query.find();
        final members = FavoriteFolderService.membersOf(folderKey);
        final filtered = all
            .where((item) => members.contains(item.uniqueKey))
            .toList();
        final start = offset > filtered.length ? filtered.length : offset;
        final end = (start + limit) > filtered.length
            ? filtered.length
            : (start + limit);
        final items = filtered.sublist(start, end);
        return _RawQueryResult(
          items.map((item) => item.toJson()).toList(),
          filtered.length,
        );
      }
      query.offset = offset;
      query.limit = limit;
      final items = query.find();
      return _RawQueryResult(
        items.map((item) => item.toJson()).toList(),
        total,
      );
    } finally {
      query.close();
    }
  }

  _RawQueryResult _queryHistoryRaw(SearchEnter search, int offset, int limit) {
    final query = objectbox.unifiedHistoryBox
        .query(_historyBaseCondition(search))
        .order(
          UnifiedComicHistory_.updatedAt,
          flags: search.sort == 'da' ? 0 : Order.descending,
        )
        .build();
    try {
      final total = query.count();
      query.offset = offset;
      query.limit = limit;
      final items = query.find();
      return _RawQueryResult(
        items.map((item) => item.toJson()).toList(),
        total,
      );
    } finally {
      query.close();
    }
  }

  _RawQueryResult _queryDownloadRaw(SearchEnter search, int offset, int limit) {
    final query = objectbox.unifiedDownloadBox
        .query(_downloadBaseCondition(search))
        .order(
          UnifiedComicDownload_.downloadedAt,
          flags: search.sort == 'da' ? 0 : Order.descending,
        )
        .build();
    try {
      final total = query.count();
      query.offset = offset;
      query.limit = limit;
      final items = query.find();
      return _RawQueryResult(
        items.map((item) => item.toJson()).toList(),
        total,
      );
    } finally {
      query.close();
    }
  }

  Condition<UnifiedComicFavorite> _favoriteBaseCondition(SearchEnter search) {
    return _favoriteSourceCondition(
      search.sources,
    ).and(UnifiedComicFavorite_.deleted.equals(false));
  }

  Condition<UnifiedComicHistory> _historyBaseCondition(SearchEnter search) {
    return _historySourceCondition(
      search.sources,
    ).and(UnifiedComicHistory_.deleted.equals(false));
  }

  Condition<UnifiedComicDownload> _downloadBaseCondition(SearchEnter search) {
    return _downloadSourceCondition(search.sources);
  }

  Condition<UnifiedComicFavorite> _favoriteSourceCondition(
    List<String> sources,
  ) {
    final cleaned = sources
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) {
      return UnifiedComicFavorite_.id.lessThan(0);
    }
    var condition = UnifiedComicFavorite_.source.equals(cleaned.first);
    for (final source in cleaned.skip(1)) {
      condition = condition.or(UnifiedComicFavorite_.source.equals(source));
    }
    return condition;
  }

  Condition<UnifiedComicHistory> _historySourceCondition(List<String> sources) {
    final cleaned = sources
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) {
      return UnifiedComicHistory_.id.lessThan(0);
    }
    var condition = UnifiedComicHistory_.source.equals(cleaned.first);
    for (final source in cleaned.skip(1)) {
      condition = condition.or(UnifiedComicHistory_.source.equals(source));
    }
    return condition;
  }

  Condition<UnifiedComicDownload> _downloadSourceCondition(
    List<String> sources,
  ) {
    final cleaned = sources
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) {
      return UnifiedComicDownload_.id.lessThan(0);
    }
    var condition = UnifiedComicDownload_.source.equals(cleaned.first);
    for (final source in cleaned.skip(1)) {
      condition = condition.or(UnifiedComicDownload_.source.equals(source));
    }
    return condition;
  }

  List<dynamic> _decodeItems(dynamic payload) {
    final list = (payload as List?) ?? const <dynamic>[];
    return switch (mode) {
      ShelfPageMode.favorite =>
        list
            .whereType<Map>()
            .map(
              (entry) => UnifiedComicFavorite.fromJson(
                Map<String, dynamic>.from(entry),
              ),
            )
            .toList(),
      ShelfPageMode.history =>
        list
            .whereType<Map>()
            .map(
              (entry) => UnifiedComicHistory.fromJson(
                Map<String, dynamic>.from(entry),
              ),
            )
            .toList(),
      ShelfPageMode.download =>
        list
            .whereType<Map>()
            .map(
              (entry) => UnifiedComicDownload.fromJson(
                Map<String, dynamic>.from(entry),
              ),
            )
            .toList(),
    };
  }

  String _uniqueKeyOfItem(dynamic item) {
    return switch (item) {
      UnifiedComicFavorite comic => comic.uniqueKey,
      UnifiedComicHistory comic => comic.uniqueKey,
      UnifiedComicDownload comic => comic.uniqueKey,
      _ => '',
    };
  }
}

Future<Map<String, dynamic>> _runBookshelfFilterTask(
  Map<String, dynamic> payload,
) async {
  try {
    final search = Map<String, dynamic>.from(
      (payload['search'] as Map?) ?? const <String, dynamic>{},
    );
    final items = ((payload['items'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
    final maskedKeywords =
        ((payload['maskedKeywords'] as List?) ?? const <dynamic>[])
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList();
    final filtered = _filterAndSort(
      items: items,
      search: search,
      maskedKeywords: maskedKeywords,
    );

    return {'items': filtered};
  } catch (e) {
    return {'error': normalizeSearchErrorMessage(e), 'items': [], 'total': 0};
  }
}

List<Map<String, dynamic>> _filterAndSort({
  required List<Map<String, dynamic>> items,
  required Map<String, dynamic> search,
  required List<String> maskedKeywords,
}) {
  final keyword = (search['keyword']?.toString() ?? '').trim().toLowerCase();
  final categories = ((search['categories'] as List?) ?? const <dynamic>[])
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();

  var data = items;

  if (maskedKeywords.isNotEmpty) {
    data = data.where((item) {
      final metadata = _decodeMetadata(item['metadata']?.toString() ?? '[]');
      final allText = [
        item['title']?.toString() ?? '',
        item['description']?.toString() ?? '',
        _creatorName(item['creator']?.toString() ?? ''),
        metadata.map((entry) => entry['name']?.toString() ?? '').join(),
        metadata
            .expand((entry) => entry['value'] as List<dynamic>? ?? const [])
            .map((entry) => (entry as Map?)?['name']?.toString() ?? '')
            .join(),
      ].join().toLowerCase();
      return !maskedKeywords.any(
        (entry) => allText.contains(entry.toLowerCase()),
      );
    }).toList();
  }

  if (categories.isNotEmpty) {
    for (final category in categories) {
      data = data.where((item) {
        final metadata = _decodeMetadata(item['metadata']?.toString() ?? '[]');
        final values = metadata
            .where((entry) => entry['type']?.toString() == 'categories')
            .expand((entry) => entry['value'] as List<dynamic>? ?? const [])
            .map((entry) => (entry as Map?)?['name']?.toString() ?? '')
            .toList();
        return values.contains(category);
      }).toList();
    }
  }

  if (keyword.isNotEmpty) {
    data = data.where((item) {
      final text = [
        item['comicId']?.toString() ?? '',
        item['title']?.toString() ?? '',
        item['description']?.toString() ?? '',
        _creatorName(item['creator']?.toString() ?? ''),
        item['metadata']?.toString() ?? '',
      ].join().toLowerCase();
      return text.contains(keyword);
    }).toList();
  }

  return data;
}

List<Map<String, dynamic>> _decodeMetadata(String raw) {
  try {
    final decoded = raw.trim().isEmpty ? const <dynamic>[] : jsonDecode(raw);
    if (decoded is! List) return const <Map<String, dynamic>>[];
    return decoded
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  } catch (_) {
    return const <Map<String, dynamic>>[];
  }
}

String _creatorName(String raw) {
  if (raw.trim().isEmpty) return '';
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) return decoded['name']?.toString() ?? '';
  } catch (_) {}
  return '';
}

class _RawQueryResult {
  const _RawQueryResult(this.items, this.total);

  final List<Map<String, dynamic>> items;
  final int total;
}
