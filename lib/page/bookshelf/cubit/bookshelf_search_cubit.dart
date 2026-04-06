import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/bookshelf/cubit/search_status.dart';
import 'package:zephyr/page/bookshelf/models/shelf_page_mode.dart';

class BookshelfSearchState {
  const BookshelfSearchState({
    this.favorite = const SearchStatusState(),
    this.history = const SearchStatusState(),
    this.download = const SearchStatusState(),
  });

  final SearchStatusState favorite;
  final SearchStatusState history;
  final SearchStatusState download;

  SearchStatusState stateOf(ShelfPageMode mode) {
    return switch (mode) {
      ShelfPageMode.favorite => favorite,
      ShelfPageMode.history => history,
      ShelfPageMode.download => download,
    };
  }

  BookshelfSearchState copyMode(ShelfPageMode mode, SearchStatusState next) {
    return switch (mode) {
      ShelfPageMode.favorite => BookshelfSearchState(
        favorite: next,
        history: history,
        download: download,
      ),
      ShelfPageMode.history => BookshelfSearchState(
        favorite: favorite,
        history: next,
        download: download,
      ),
      ShelfPageMode.download => BookshelfSearchState(
        favorite: favorite,
        history: history,
        download: next,
      ),
    };
  }
}

class BookshelfSearchCubit extends Cubit<BookshelfSearchState> {
  BookshelfSearchCubit() : super(const BookshelfSearchState());

  void setKeyword(ShelfPageMode mode, String keyword) {
    final next = state.stateOf(mode).copyWith(keyword: keyword);
    emit(state.copyMode(mode, next));
  }

  void setSort(ShelfPageMode mode, String sort) {
    final next = state.stateOf(mode).copyWith(sort: sort);
    emit(state.copyMode(mode, next));
  }

  void setSources(ShelfPageMode mode, List<String> sources) {
    final next = state.stateOf(mode).copyWith(sources: sources);
    emit(state.copyMode(mode, next));
  }

  void syncSources(List<String> available) {
    if (available.isEmpty) {
      return;
    }
    var nextState = state;
    for (final mode in ShelfPageMode.values) {
      final current = nextState
          .stateOf(mode)
          .sources
          .where((item) => item.trim().isNotEmpty);
      final filtered = current.where(available.contains).toList();
      final nextSources = filtered.isEmpty ? available : filtered;
      if (!_listEquals(nextState.stateOf(mode).sources, nextSources)) {
        nextState = nextState.copyMode(
          mode,
          nextState.stateOf(mode).copyWith(sources: nextSources),
        );
      }
    }
    if (!identical(nextState, state)) {
      emit(nextState);
    }
  }

  bool _listEquals(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) {
        return false;
      }
    }
    return true;
  }
}
