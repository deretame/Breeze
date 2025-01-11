part of 'user_history_bloc.dart';

enum UserHistoryStatus { initial, success, failure }

final class UserHistoryState extends Equatable {
  const UserHistoryState({
    this.status = UserHistoryStatus.initial,
    this.comics = const [],
    this.result = '',
    this.searchEnterConst = const SearchEnterConst(),
  });

  final UserHistoryStatus status;
  final List<BikaComicHistory> comics;
  final String result;
  final SearchEnterConst searchEnterConst;

  UserHistoryState copyWith({
    UserHistoryStatus? status,
    List<BikaComicHistory>? comics,
    String? result,
    SearchEnterConst? searchEnterConst,
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
