part of 'user_download_bloc.dart';

enum UserDownloadStatus { initial, success, failure }

class UserDownloadState extends Equatable {
  const UserDownloadState({
    this.status = UserDownloadStatus.initial,
    this.comics = const [],
    this.result = '',
    this.searchEnterConst = const SearchEnterConst(),
  });

  final UserDownloadStatus status;
  final List<dynamic> comics;
  final String result;
  final SearchEnterConst searchEnterConst;

  UserDownloadState copyWith({
    UserDownloadStatus? status,
    List<dynamic>? comics,
    String? result,
    SearchEnterConst? searchEnterConst,
  }) {
    return UserDownloadState(
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
