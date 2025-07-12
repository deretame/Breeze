part of 'week_ranking_bloc.dart';

@freezed
abstract class WeekRankingEvent with _$WeekRankingEvent {
  const factory WeekRankingEvent({
    @Default(JmRankingStatus.initial) JmRankingStatus status,
    @Default(0) int date,
    @Default("all") String type,
    @Default(1) int page,
  }) = _WeekRankingEvent;
}
