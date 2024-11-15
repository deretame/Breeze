part of 'get_comic_info_bloc.dart';

sealed class GetComicInfoEvent extends Equatable {
  const GetComicInfoEvent();
}

class GetComicInfo extends GetComicInfoEvent {
  final String comicId;

  const GetComicInfo(this.comicId);

  @override
  List<Object> get props => [comicId];
}
