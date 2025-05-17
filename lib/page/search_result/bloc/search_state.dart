part of 'search_bloc.dart';

enum SearchStatus { initial, success, failure, loadingMore, getMoreFailure }

final class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.initial,
    this.comics = const [],
    this.hasReachedMax = false,
    this.result = '',
    this.searchEnter,
    this.pagesCount = 0,
  });

  final SearchStatus status;
  final List<ComicNumber> comics;
  final bool hasReachedMax;
  final String result;
  final SearchEnter? searchEnter;
  final int pagesCount;

  SearchState copyWith({
    SearchStatus? status,
    List<ComicNumber>? comics,
    bool? hasReachedMax,
    String? result,
    SearchEnter? searchEnter,
    int? pagesCount,
  }) {
    return SearchState(
      status: status ?? this.status,
      comics: comics ?? this.comics,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      result: result ?? this.result,
      searchEnter: searchEnter ?? this.searchEnter,
      pagesCount: pagesCount ?? this.pagesCount,
    );
  }

  @override
  String toString() {
    return '''SearchState { status: $status, hasReachedMax: $hasReachedMax, posts: ${comics.length} , result: $result, searchEnter: $searchEnter, pagesCount: $pagesCount }''';
  }

  @override
  List<Object?> get props => [
    status,
    comics,
    hasReachedMax,
    result,
    searchEnter,
    pagesCount,
  ];
}
