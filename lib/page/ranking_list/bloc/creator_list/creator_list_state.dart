part of 'creator_list_bloc.dart';

enum CreatorListStatus { initial, success, failure }

final class CreatorListState extends Equatable {
  const CreatorListState({
    this.status = CreatorListStatus.initial,
    this.userList = const <User>[],
    this.result = '',
  });

  final CreatorListStatus status;
  final List<User>? userList;
  final String? result;

  CreatorListState copyWith({
    CreatorListStatus? status,
    List<User>? userList,
    String? result,
  }) {
    return CreatorListState(
      status: status ?? this.status,
      userList: userList ?? this.userList,
      result: result ?? this.result,
    );
  }

  @override
  String toString() {
    return '''PostState { status: $status, userList: $userList , result: $result }''';
  }

  @override
  List<Object?> get props => [status, userList, result];
}
