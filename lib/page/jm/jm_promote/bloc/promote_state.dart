part of 'promote_bloc.dart';

enum PromoteStatus {
  initial,
  success,
  failure,
  loadingMore,
  loadingMoreFailure,
}

@freezed
abstract class PromoteState with _$PromoteState {
  const factory PromoteState({
    @Default(PromoteStatus.initial) PromoteStatus status,
    @Default([]) List<JmPromoteJson> list,
    @Default([]) List<JmSuggestionJson> suggestionList,
    @Default('') String result,
  }) = _PromoteState;
}
