part of 'search_bloc.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();
}

class FetchSearchResult extends SearchEvent {
  final SearchEnter searchEnter;
  final SearchStatus searchStatus;

  const FetchSearchResult(this.searchEnter, this.searchStatus);

  @override
  List<Object> get props => [searchEnter];
}
