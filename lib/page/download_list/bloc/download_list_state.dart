part of 'download_list_bloc.dart';

enum DownloadListStatus { initial, success, failure }

class DownloadListState extends Equatable {
  const DownloadListState({
    this.status = DownloadListStatus.initial,
    this.comics = const [],
    this.result = '',
    this.searchEnterConst = const SearchEnterConst(),
  });

  final DownloadListStatus status;
  final List<BikaComicDownload> comics;
  final String result;
  final SearchEnterConst searchEnterConst;

  DownloadListState copyWith({
    DownloadListStatus? status,
    List<BikaComicDownload>? comics,
    String? result,
    SearchEnterConst? searchEnterConst,
  }) {
    return DownloadListState(
      status: status ?? this.status,
      comics: comics ?? this.comics,
      result: result ?? this.result,
      searchEnterConst: searchEnterConst ?? this.searchEnterConst,
    );
  }

  @override
  String toString() {
    return '''DownloadListState { status: $status, comics: ${comics.length} , result: $result, searchEnter: $searchEnterConst}''';
  }

  @override
  List<Object> get props => [status, comics, result, searchEnterConst];
}
