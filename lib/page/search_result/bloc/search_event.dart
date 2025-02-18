part of 'search_bloc.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();
}

class FetchSearchResult extends SearchEvent {
  final SearchEnterConst searchEnterConst;
  final SearchStatus searchStatus;

  const FetchSearchResult(this.searchEnterConst, this.searchStatus);

  @override
  List<Object> get props => [searchEnterConst];
}
