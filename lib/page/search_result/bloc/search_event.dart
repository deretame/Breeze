part of 'search_bloc.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();
}

class FetchSearchResult extends SearchEvent {
  final SearchEnterConst searchEnterConst;

  const FetchSearchResult(
    this.searchEnterConst,
  );

  @override
  List<Object> get props => [searchEnterConst];
}
