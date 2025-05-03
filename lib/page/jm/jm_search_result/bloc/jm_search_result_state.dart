part of 'jm_search_result_bloc.dart';

enum JmSearchResultStatus {
  initial,
  success,
  failure,
  loadingMore,
  loadingMoreFailure,
}

class JmSearchResultState extends Equatable {
  final JmSearchResultStatus status;
  final List<Content>? jmSearchResults;
  final bool hasReachedMax;
  final String result;

  const JmSearchResultState({
    this.status = JmSearchResultStatus.initial,
    this.jmSearchResults,
    this.hasReachedMax = false,
    this.result = '',
  });

  JmSearchResultState copyWith({
    JmSearchResultStatus? status,
    List<Content>? jmSearchResults,
    bool? hasReachedMax,
    String? result,
  }) {
    return JmSearchResultState(
      status: status ?? this.status,
      jmSearchResults: jmSearchResults ?? this.jmSearchResults,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [status, jmSearchResults, hasReachedMax, result];
}
