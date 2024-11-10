part of 'search_bloc.dart';

enum SearchStatus { initial, success, failure, loadingMore, getMoreFailure }

final class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.initial,
    this.comics = const [],
    this.hasReachedMax = false,
    this.result = '',
    this.searchEnterConst = const SearchEnterConst(),
    this.pagesCount = 0,
  });

  final SearchStatus status;
  final List<ComicNumber> comics;
  final bool hasReachedMax;
  final String result;
  final SearchEnterConst searchEnterConst;
  final int pagesCount;

  SearchState copyWith({
    SearchStatus? status,
    List<ComicNumber>? comics,
    bool? hasReachedMax,
    String? result,
    SearchEnterConst? searchEnterConst,
    int? pagesCount,
  }) {
    return SearchState(
      status: status ?? this.status,
      comics: comics ?? this.comics,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      result: result ?? this.result,
      searchEnterConst: searchEnterConst ?? this.searchEnterConst,
      pagesCount: pagesCount ?? this.pagesCount,
    );
  }

  @override
  String toString() {
    return '''SearchState { status: $status, hasReachedMax: $hasReachedMax, posts: ${comics.length} , result: $result, searchEnter: $searchEnterConst, pagesCount: $pagesCount }''';
  }

  @override
  List<Object> get props =>
      [status, comics, hasReachedMax, result, searchEnterConst, pagesCount];
}
