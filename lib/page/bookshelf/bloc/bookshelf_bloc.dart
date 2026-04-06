import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
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
      final sourceItems = _fetchRawItems();
      final maskedKeywords = objectbox.userSettingBox
          .get(1)!
          .globalSetting
          .maskedKeywords
          .where((keyword) => keyword.trim().isNotEmpty)
          .toList();
      final offset = event.append ? current.comics.length : 0;

      final response = await _bookshelfWorkerService.query(
        mode: mode,
        search: event.searchEnterConst,
        sourceItems: sourceItems,
        maskedKeywords: maskedKeywords,
        offset: offset,
        limit: _kPageSize,
      );

      final error = response['error']?.toString() ?? '';
      if (error.isNotEmpty) {
        throw Exception(error);
      }

      final pageItems = _decodeItems(response['items']);
      final total = response['total'] as int? ?? 0;
      final hasReachedMax = response['hasReachedMax'] as bool? ?? true;

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

  List<Map<String, dynamic>> _fetchRawItems() {
    return switch (mode) {
      ShelfPageMode.favorite =>
        objectbox.unifiedFavoriteBox
            .getAll()
            .map((item) => item.toJson())
            .toList(),
      ShelfPageMode.history =>
        objectbox.unifiedHistoryBox
            .getAll()
            .map((item) => item.toJson())
            .toList(),
      ShelfPageMode.download =>
        objectbox.unifiedDownloadBox
            .getAll()
            .map((item) => item.toJson())
            .toList(),
    };
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
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  int _requestId = 0;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  Future<void>? _readyFuture;

  Future<void> ensureReady() {
    _readyFuture ??= _start();
    return _readyFuture!;
  }

  Future<void> _start() async {
    _receivePort = ReceivePort();
    await Isolate.spawn(_bookshelfWorkerMain, _receivePort!.sendPort);

    final ready = Completer<void>();
    _receivePort!.listen((message) {
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
    required int offset,
    required int limit,
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
      'offset': offset,
      'limit': limit,
    });

    return completer.future;
  }
}

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
      final mode = message['mode']?.toString() ?? '';
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
      final offset = (message['offset'] as int?) ?? 0;
      final limit = (message['limit'] as int?) ?? _kPageSize;

      final filtered = _filterAndSort(
        mode: mode,
        items: items,
        search: search,
        maskedKeywords: maskedKeywords,
      );

      final total = filtered.length;
      final start = offset < 0 ? 0 : offset;
      final end = (start + limit) > total ? total : (start + limit);
      final page = start >= total
          ? const <Map<String, dynamic>>[]
          : filtered.sublist(start, end);

      sendPort.send({
        'id': id,
        'items': page,
        'total': total,
        'hasReachedMax': end >= total,
      });
    } catch (e) {
      sendPort.send({'id': id, 'error': e.toString(), 'items': [], 'total': 0});
    }
  });
}

List<Map<String, dynamic>> _filterAndSort({
  required String mode,
  required List<Map<String, dynamic>> items,
  required Map<String, dynamic> search,
  required List<String> maskedKeywords,
}) {
  final keyword = (search['keyword']?.toString() ?? '').trim().toLowerCase();
  final sort = (search['sort']?.toString() ?? 'dd').trim();
  final sources = ((search['sources'] as List?) ?? const <dynamic>[])
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toSet();
  final categories = ((search['categories'] as List?) ?? const <dynamic>[])
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();

  var data = items.where((item) {
    if (sources.isNotEmpty && !sources.contains(item['source']?.toString())) {
      return false;
    }
    if (item['deleted'] == true) {
      return false;
    }
    return true;
  }).toList();

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

  data.sort((a, b) => _sortCompare(mode, sort, a, b));
  return data;
}

int _sortCompare(
  String mode,
  String sort,
  Map<String, dynamic> left,
  Map<String, dynamic> right,
) {
  if (sort == 'da') {
    final l = _num(left['updatedAt'] ?? left['downloadedAt']);
    final r = _num(right['updatedAt'] ?? right['downloadedAt']);
    return l.compareTo(r);
  }
  if (sort == 'ld') {
    if (mode == ShelfPageMode.download.name) {
      return _num(right['totalLikes']).compareTo(_num(left['totalLikes']));
    }
    return (right['title']?.toString() ?? '').compareTo(
      left['title']?.toString() ?? '',
    );
  }
  if (sort == 'vd') {
    if (mode == ShelfPageMode.download.name) {
      return _num(right['totalViews']).compareTo(_num(left['totalViews']));
    }
    if (mode == ShelfPageMode.history.name) {
      return _viewsFromTitleMeta(
        right['titleMeta'],
      ).compareTo(_viewsFromTitleMeta(left['titleMeta']));
    }
    return (right['title']?.toString() ?? '').compareTo(
      left['title']?.toString() ?? '',
    );
  }

  final l = _num(left['updatedAt'] ?? left['downloadedAt']);
  final r = _num(right['updatedAt'] ?? right['downloadedAt']);
  return r.compareTo(l);
}

int _num(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
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

int _viewsFromTitleMeta(dynamic raw) {
  final input = raw?.toString() ?? '';
  if (input.trim().isEmpty) return 0;
  try {
    final decoded = jsonDecode(input);
    if (decoded is! List) return 0;
    for (final entry in decoded.whereType<Map>()) {
      final name = entry['name']?.toString() ?? '';
      if (name.startsWith('浏览：')) {
        return int.tryParse(name.substring(3)) ?? 0;
      }
    }
  } catch (_) {}
  return 0;
}
