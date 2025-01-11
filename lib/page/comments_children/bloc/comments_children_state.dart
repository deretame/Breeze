part of 'comments_children_bloc.dart';

enum CommentsChildrenStatus {
  initial,
  success,
  failure,
  loadingMore,
  getMoreFailure,
  comment
}

final class CommentsChildrenState extends Equatable {
  const CommentsChildrenState({
    this.status = CommentsChildrenStatus.initial,
    this.commentsChildrenJson,
    this.hasReachedMax = false,
    this.result = '',
    this.count = 0,
  });

  final CommentsChildrenStatus status;
  final List<CommentsChildrenJson>? commentsChildrenJson;
  final bool hasReachedMax;
  final String result;
  final int count;

  CommentsChildrenState copyWith({
    CommentsChildrenStatus? status,
    List<CommentsChildrenJson>? commentsChildrenJson,
    bool? hasReachedMax,
    String? result,
    int? count,
  }) {
    return CommentsChildrenState(
      status: status ?? this.status,
      commentsChildrenJson: commentsChildrenJson ?? this.commentsChildrenJson,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      result: result ?? this.result,
      count: count ?? this.count,
    );
  }

  @override
  List<Object?> get props =>
      [status, commentsChildrenJson, hasReachedMax, result, count];
}
