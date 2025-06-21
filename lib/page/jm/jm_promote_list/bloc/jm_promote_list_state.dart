part of 'jm_promote_list_bloc.dart';

enum JmPromoteListStatus {
  initial,
  success,
  failure,
  loadingMore,
  loadingMoreFailure,
}

@freezed
abstract class JmPromoteListState with _$JmPromoteListState {
  const factory JmPromoteListState({
    @Default(JmPromoteListStatus.initial) JmPromoteListStatus status,
    @Default([]) List<ListElement> list,
    @Default(false) bool hasReachedMax,
    @Default('') String result,
  }) = _JmPromoteListState;
}
