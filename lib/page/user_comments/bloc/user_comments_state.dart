part of 'user_comments_bloc.dart';

enum UserCommentsStatus {
  initial,
  success,
  failure,
  loadingMore,
  getMoreFailure,
}

final class UserCommentsState extends Equatable {
  const UserCommentsState({
    this.status = UserCommentsStatus.initial,
    this.userCommentsJson,
    this.hasReachedMax = false,
    this.result = '',
    this.count = 0,
  });

  final UserCommentsStatus status;
  final List<UserCommentsJson>? userCommentsJson;
  final bool hasReachedMax;
  final String result;
  final int count;

  UserCommentsState copyWith({
    UserCommentsStatus? status,
    List<UserCommentsJson>? userCommentsJson,
    bool? hasReachedMax,
    String? result,
    int? count,
  }) {
    return UserCommentsState(
      status: status ?? this.status,
      userCommentsJson: userCommentsJson ?? this.userCommentsJson,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      result: result ?? this.result,
      count: count ?? this.count,
    );
  }

  @override
  List<Object?> get props =>
      [status, userCommentsJson, hasReachedMax, result, count];
}
