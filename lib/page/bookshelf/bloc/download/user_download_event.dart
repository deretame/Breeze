part of 'user_download_bloc.dart';

final class UserDownloadEvent extends Equatable {
  final SearchEnterConst searchEnterConst;

  const UserDownloadEvent(this.searchEnterConst);

  @override
  List<Object> get props => [searchEnterConst];
}
