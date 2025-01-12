part of 'user_comments_bloc.dart';

final class UserCommentsEvent extends Equatable {
  final UserCommentsStatus status;
  final int count;

  const UserCommentsEvent({
    this.status = UserCommentsStatus.initial,
    this.count = 0,
  });

  @override
  List<Object> get props => [status, count];
}
