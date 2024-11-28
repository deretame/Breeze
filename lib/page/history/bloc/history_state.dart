part of 'history_bloc.dart';

enum HistoryStatus { initial, success, failure }

final class HistoryState extends Equatable {
  const HistoryState({
    this.status = HistoryStatus.initial,
    this.comics = const [],
    this.result = '',
    this.searchEnterConst = const SearchEnterConst(),
  });

  final HistoryStatus status;
  final List<BikaComicHistory> comics;
  final String result;
  final SearchEnterConst searchEnterConst;

  HistoryState copyWith({
    HistoryStatus? status,
    List<BikaComicHistory>? comics,
    String? result,
    SearchEnterConst? searchEnterConst,
  }) {
    return HistoryState(
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
