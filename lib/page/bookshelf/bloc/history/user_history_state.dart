part of 'user_history_bloc.dart';

enum UserHistoryStatus { initial, success, failure }

final class UserHistoryState extends Equatable {
  const UserHistoryState({
    this.status = UserHistoryStatus.initial,
    this.comics = const [],
    this.result = '',
    this.searchEnterConst = const SearchEnter(),
  });

  final UserHistoryStatus status;
  final List<dynamic> comics;
  final String result;
  final SearchEnter searchEnterConst;

  UserHistoryState copyWith({
    UserHistoryStatus? status,
    List<dynamic>? comics,
    String? result,
    SearchEnter? searchEnterConst,
  }) {
    return UserHistoryState(
      status: status ?? this.status,
      comics: comics ?? this.comics,
      result: result ?? this.result,
      searchEnterConst: searchEnterConst ?? this.searchEnterConst,
    );
  }

  @override
  String toString() {
    return '''SearchState { status: $status, posts: ${comics.length} , result: $result, searchEnter: $searchEnterConst}''';
  }

  @override
  List<Object> get props => [status, comics, result, searchEnterConst];
}
