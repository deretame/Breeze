part of 'download_list_bloc.dart';

final class DownloadListEvent extends Equatable {
  final SearchEnterConst searchEnterConst;

  const DownloadListEvent(this.searchEnterConst);

  @override
  List<Object> get props => [searchEnterConst];
}
