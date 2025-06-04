part of 'search_keyword_bloc.dart';

enum SearchKeywordStatus { initial, success, failure }

final class SearchKeywordState extends Equatable {
  const SearchKeywordState({
    this.status = SearchKeywordStatus.initial,
    this.keywords = const [],
    this.result = '',
  });

  final SearchKeywordStatus status;
  final List<String> keywords;
  final String result;

  SearchKeywordState copyWith({
    SearchKeywordStatus? status,
    List<String>? keywords,
    String? result,
  }) {
    return SearchKeywordState(
      status: status ?? this.status,
      keywords: keywords ?? this.keywords,
      result: result ?? this.result,
    );
  }

  @override
  String toString() =>
      'SearchKeywordState { status: $status, keywords: $keywords, result: $result }';

  @override
  List<Object> get props => [status, keywords, result];
}
