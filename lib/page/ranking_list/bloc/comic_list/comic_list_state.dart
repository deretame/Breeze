part of 'comic_list_bloc.dart';

enum ComicListStatus { initial, success, failure }

final class ComicListState extends Equatable {
  const ComicListState({
    this.status = ComicListStatus.initial,
    this.comicList = const <Comic>[],
    this.result = '',
  });

  final ComicListStatus status;
  final List<Comic>? comicList;
  final String? result;

  ComicListState copyWith({
    ComicListStatus? status,
    List<Comic>? comicList,
    String? result,
  }) {
    return ComicListState(
      status: status ?? this.status,
      comicList: comicList ?? this.comicList,
      result: result ?? this.result,
    );
  }

  @override
  String toString() {
    return '''ComicListState { status: $status, comicList: $comicList , result: $result }''';
  }

  @override
  List<Object?> get props => [status, comicList, result];
}
