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
    @Default(<Map<String, dynamic>>[]) List<Map<String, dynamic>> sections,
    @Default(<Map<String, dynamic>>[]) List<Map<String, dynamic>> suggestionItems,
    @Default(false) bool hasReachedMax,
    @Default('') String result,
  }) = _PromoteState;
}
