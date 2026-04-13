import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/bookshelf/models/search_enter.dart';
import 'package:zephyr/page/bookshelf/models/shelf_page_mode.dart';

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

class BookshelfSectionBloc
    extends Bloc<BookshelfSectionEvent, BookshelfSectionState> {
  BookshelfSectionBloc({required this.mode})
    : super(const BookshelfSectionState()) {
    _workerReady = _bookshelfWorkerService.ensureReady();
    on<BookshelfLoadRequested>(_onLoadRequested, transformer: sequential());
  }

  final ShelfPageMode mode;
  late final Future<void> _workerReady;

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
      await _workerReady;
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

      final response = await _bookshelfWorkerService.query(
        mode: mode,
        search: event.searchEnterConst,
        sourceItems: raw.items,
        maskedKeywords: maskedKeywords,
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
            result: e.toString(),
            isLoadingMore: false,
            loadMoreFailed: false,
            searchEnterConst: event.searchEnterConst,
          ),
        );
      }
    }
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
    final query = objectbox.unifiedFavoriteBox
        .query(_favoriteBaseCondition(search))
        .order(
          UnifiedComicFavorite_.createdAt,
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
}

final _bookshelfWorkerService = _BookshelfWorkerService();

class _BookshelfWorkerService {
  Isolate? _worker;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  StreamSubscription? _subscription;
  int _requestId = 0;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  Future<void>? _readyFuture;

  Future<void> ensureReady() {
    _readyFuture ??= _start();
    return _readyFuture!;
  }

  Future<void> _start() async {
    _receivePort = ReceivePort();
    _worker = await Isolate.spawn(_bookshelfWorkerMain, _receivePort!.sendPort);

    final ready = Completer<void>();
    _subscription = _receivePort!.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        if (!ready.isCompleted) {
          ready.complete();
        }
        return;
      }

      if (message is Map) {
        final id = message['id'];
        if (id is int && _pending.containsKey(id)) {
          _pending.remove(id)!.complete(Map<String, dynamic>.from(message));
        }
      }
    });

    await ready.future;
  }

  Future<Map<String, dynamic>> query({
    required ShelfPageMode mode,
    required SearchEnter search,
    required List<Map<String, dynamic>> sourceItems,
    required List<String> maskedKeywords,
    bool isRetry = false,
  }) async {
    await ensureReady();
    if (_sendPort == null) {
      throw StateError('Bookshelf worker send port missing');
    }

    final id = ++_requestId;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;

    _sendPort!.send({
      'id': id,
      'mode': mode.name,
      'search': {
        'keyword': search.keyword,
        'sort': search.sort,
        'categories': search.categories,
        'sources': search.sources,
      },
      'items': sourceItems,
      'maskedKeywords': maskedKeywords,
    });

    final response = await completer.future;
    final error = response['error']?.toString() ?? '';
    if (!isRetry && error.contains('_filterAndSort')) {
      await _restart();
      return query(
        mode: mode,
        search: search,
        sourceItems: sourceItems,
        maskedKeywords: maskedKeywords,
        isRetry: true,
      );
    }
    return response;
  }

  Future<void> _restart() async {
    for (final pending in _pending.values) {
      if (!pending.isCompleted) {
        pending.completeError(StateError('Bookshelf worker restarting'));
      }
    }
    _pending.clear();
    await _subscription?.cancel();
    _subscription = null;
    _receivePort?.close();
    _receivePort = null;
    _sendPort = null;
    _worker?.kill(priority: Isolate.immediate);
    _worker = null;
    _readyFuture = null;
    await ensureReady();
  }
}

@pragma('vm:entry-point')
void _bookshelfWorkerMain(SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    if (message is! Map) {
      return;
    }
    final id = message['id'];
    if (id is! int) {
      return;
    }

    try {
      final search = Map<String, dynamic>.from(
        (message['search'] as Map?) ?? const <String, dynamic>{},
      );
      final items = ((message['items'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
      final maskedKeywords =
          ((message['maskedKeywords'] as List?) ?? const <dynamic>[])
              .map((entry) => entry.toString().trim())
              .where((entry) => entry.isNotEmpty)
              .toList();
      final filtered = _filterAndSort(
        items: items,
        search: search,
        maskedKeywords: maskedKeywords,
      );

      sendPort.send({'id': id, 'items': filtered});
    } catch (e) {
      sendPort.send({'id': id, 'error': e.toString(), 'items': [], 'total': 0});
    }
  });
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
