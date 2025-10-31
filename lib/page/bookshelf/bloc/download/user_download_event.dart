part of 'user_download_bloc.dart';

final class UserDownloadEvent extends Equatable {
  final SearchEnter searchEnterConst;
  final int comicChoice;

  const UserDownloadEvent(this.searchEnterConst, this.comicChoice);

  @override
  List<Object> get props => [searchEnterConst, comicChoice];
}
