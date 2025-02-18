part of 'comments_children_bloc.dart';

final class CommentsChildrenEvent extends Equatable {
  final String commentChildrenId;
  final CommentsChildrenStatus status;
  final int count;

  const CommentsChildrenEvent(this.commentChildrenId, this.status, this.count);

  @override
  List<Object> get props => [commentChildrenId, status, count];
}
