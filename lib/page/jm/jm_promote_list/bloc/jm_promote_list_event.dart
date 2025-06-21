part of 'jm_promote_list_bloc.dart';

@freezed
abstract class JmPromoteListEvent with _$JmPromoteListEvent {
  const factory JmPromoteListEvent({
    @Default(JmPromoteListStatus.initial) JmPromoteListStatus status,
    @Default(0) int page,
    @Default(0) int id,
  }) = _JmPromoteListEvent;
}
