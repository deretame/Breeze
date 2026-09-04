import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/page/comic_info/models/comic_preview.dart';
import 'package:zephyr/page/comic_info/models/unified_plugin_preview.dart';
import 'package:zephyr/util/error_filter.dart';

enum ComicPreviewStatus {
  initial,
  success,
  failure,
  loadingMore,
  getMoreFailure,
}

final class ComicPreviewState extends Equatable {
  const ComicPreviewState({
    this.status = ComicPreviewStatus.initial,
    this.items = const <UnifiedPluginPreviewItem>[],
    this.page = 0,
    this.hasReachedMax = false,
    this.pluginExtern = const <String, dynamic>{},
    this.result = '',
  });

  final ComicPreviewStatus status;
  final List<UnifiedPluginPreviewItem> items;
  final int page;
  final bool hasReachedMax;
  final Map<String, dynamic> pluginExtern;
  final String result;

  ComicPreviewState copyWith({
    ComicPreviewStatus? status,
    List<UnifiedPluginPreviewItem>? items,
    int? page,
    bool? hasReachedMax,
    Map<String, dynamic>? pluginExtern,
    String? result,
  }) {
    return ComicPreviewState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      pluginExtern: pluginExtern ?? this.pluginExtern,
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    page,
    hasReachedMax,
    pluginExtern,
    result,
  ];
}

final class LoadComicPreview extends Equatable {
  const LoadComicPreview({this.loadMore = false});

  final bool loadMore;

  @override
  List<Object> get props => [loadMore];
}

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class ComicPreviewBloc extends Bloc<LoadComicPreview, ComicPreviewState> {
  ComicPreviewBloc({
    required this.comicId,
    required this.from,
    required this.capability,
    this._extern = const <String, dynamic>{},
  }) : super(const ComicPreviewState()) {
    on<LoadComicPreview>(
      _fetchPreview,
      transformer: _throttleDroppable(const Duration(milliseconds: 100)),
    );
  }

  final String comicId;
  final String from;
  final ComicPreviewCapability capability;
  final Map<String, dynamic> _extern;

  Future<void> _fetchPreview(
    LoadComicPreview event,
    Emitter<ComicPreviewState> emit,
  ) async {
    if (event.loadMore &&
        (state.hasReachedMax ||
            state.status == ComicPreviewStatus.loadingMore)) {
      return;
    }

    final page = event.loadMore ? state.page + 1 : 1;
    if (event.loadMore) {
      emit(state.copyWith(status: ComicPreviewStatus.loadingMore));
    } else {
      emit(state.copyWith(status: ComicPreviewStatus.initial));
    }

    final requestExtern = event.loadMore
        ? state.pluginExtern
        : {..._extern, ...capability.extern};

    try {
      final response = await getComicPreviewByPlugin(
        comicId,
        page,
        from,
        extern: requestExtern,
      );
      final items = event.loadMore
          ? _appendUnique(state.items, response.items)
          : response.items;
      final hasNoProgress =
          response.items.isEmpty ||
          (event.loadMore &&
              (items.length == state.items.length ||
                  response.paging.page <= state.page));
      final hasReachedMax =
          response.paging.hasReachedMax ||
          (response.paging.pages > 0 &&
              response.paging.page >= response.paging.pages) ||
          hasNoProgress;

      emit(
        state.copyWith(
          status: ComicPreviewStatus.success,
          items: items,
          page: response.paging.page,
          hasReachedMax: hasReachedMax,
          pluginExtern: response.extern,
          result: '',
        ),
      );
    } catch (error, stackTrace) {
      logger.e(error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          status: event.loadMore
              ? ComicPreviewStatus.getMoreFailure
              : ComicPreviewStatus.failure,
          result: normalizeSearchErrorMessage(error),
        ),
      );
    }
  }

  List<UnifiedPluginPreviewItem> _appendUnique(
    List<UnifiedPluginPreviewItem> current,
    List<UnifiedPluginPreviewItem> incoming,
  ) {
    final result = List<UnifiedPluginPreviewItem>.from(current);
    final keys = result.map(_itemKey).toSet();
    for (final item in incoming) {
      if (keys.add(_itemKey(item))) {
        result.add(item);
      }
    }
    return result;
  }

  String _itemKey(UnifiedPluginPreviewItem item) {
    if (item.id.trim().isNotEmpty) return 'id:${item.id}';
    return 'path:${item.path}|url:${item.url}';
  }
}
