part of 'jm_ranking_bloc.dart';

enum JmRankingStatus {
  initial,
  success,
  failure,
  loadingMore,
  loadingMoreFailure,
}

@freezed
abstract class JmRankingState with _$JmRankingState {
  const factory JmRankingState({
    @Default(JmRankingStatus.initial) JmRankingStatus status,
    @Default([]) List<Content> list,
    @Default(false) bool hasReachedMax,
    @Default('') String result,
  }) = _JmRankingState;
}
