part of 'jm_search_result_bloc.dart';

class JmSearchResultEvent extends Equatable {
  final JmSearchResultStatus status;
  final String keyword;
  final String sort;

  const JmSearchResultEvent({
    this.status = JmSearchResultStatus.initial,
    this.keyword = '',
    this.sort = '',
  });

  JmSearchResultEvent copyWith({
    JmSearchResultStatus? status,
    String? keyword,
    String? sort,
  }) {
    return JmSearchResultEvent(
      status: status ?? this.status,
      keyword: keyword ?? this.keyword,
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object> get props => [status, keyword, sort];
}
