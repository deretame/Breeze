part of 'comments_bloc.dart';

enum CommentsStatus {
  initial,
  success,
  failure,
  loadingMore,
  getMoreFailure,
  comment
}

final class CommentsState extends Equatable {
  const CommentsState({
    this.status = CommentsStatus.initial,
    this.commentsJson,
    this.hasReachedMax = false,
    this.result = '',
    this.count = 0,
  });

  final CommentsStatus status;
  final List<CommentsJson>? commentsJson;
  final bool hasReachedMax;
  final String result;
  final int count;

  CommentsState copyWith({
    CommentsStatus? status,
    List<CommentsJson>? commentsJson,
    bool? hasReachedMax,
    String? result,
    int? count,
  }) {
    return CommentsState(
      status: status ?? this.status,
      commentsJson: commentsJson ?? this.commentsJson,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      result: result ?? this.result,
      count: count ?? this.count,
    );
  }

  @override
  List<Object?> get props =>
      [status, commentsJson, hasReachedMax, result, count];
}
