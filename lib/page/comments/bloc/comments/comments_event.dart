part of 'comments_bloc.dart';

final class CommentsEvent extends Equatable {
  final String commentsId;
  final CommentsStatus status;
  final int count;

  const CommentsEvent(this.commentsId, this.status, this.count);

  @override
  List<Object> get props => [commentsId, status, count];
}
