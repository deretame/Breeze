part of 'search_bloc.dart';

enum SearchStatus { initial, success, failure, loadingMore, getMoreFailure }

@freezed
abstract class SearchState with _$SearchState {
  const factory SearchState({
    @Default(SearchStatus.initial) SearchStatus status,
    @Default([]) List<ComicNumber> comics,
    @Default(false) bool hasReachedMax,
    @Default('') String result,
    @Default(SearchEvent()) SearchEvent searchEvent,
  }) = _SearchState;

  factory SearchState.fromJson(Map<String, dynamic> json) =>
      _$SearchStateFromJson(json);
}
