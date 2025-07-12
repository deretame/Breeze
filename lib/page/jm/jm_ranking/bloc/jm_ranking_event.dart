part of 'jm_ranking_bloc.dart';

@freezed
abstract class JmRankingEvent with _$JmRankingEvent {
  const factory JmRankingEvent({
    @Default(JmRankingStatus.initial) JmRankingStatus status,
    @Default(1) int page,
    @Default("0") String type,
    @Default("") String order,
  }) = _JmRankingEvent;
}
