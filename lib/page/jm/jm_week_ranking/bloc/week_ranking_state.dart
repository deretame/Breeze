part of 'week_ranking_bloc.dart';

enum JmRankingStatus {
  initial,
  success,
  failure,
  loadingMore,
  loadingMoreFailure,
}

@freezed
abstract class WeekRankingState with _$WeekRankingState {
  const factory WeekRankingState({
    @Default(JmRankingStatus.initial) JmRankingStatus status,
    @Default([]) List<ListElement> list,
    @Default(false) bool hasReachedMax,
    @Default('') String result,
  }) = _WeekRankingBlocState;
}
