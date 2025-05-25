part of 'get_comic_info_bloc.dart';

class GetComicInfoEvent extends Equatable {
  final String comicId;

  const GetComicInfoEvent({required this.comicId});

  @override
  List<Object> get props => [comicId];
}
