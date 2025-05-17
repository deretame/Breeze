part of 'comments_bloc.dart';

enum CommentsStatus {
  initial,
  success,
  failure,
  loadingMore,
  loadingMoreFailure,
}

@freezed
abstract class CommentsState with _$CommentsState {
  const factory CommentsState({
    @Default(CommentsStatus.initial) CommentsStatus status,
    @Default([]) List<ListElement> comments,
    @Default(false) bool hasReachedMax,
    @Default('') String result,
  }) = _CommentsState;
}
