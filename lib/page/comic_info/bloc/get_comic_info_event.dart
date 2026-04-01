part of 'get_comic_info_bloc.dart';

class GetComicInfoEvent extends Equatable {
  final String comicId;
  final String from;
  final String pluginId;
  final ComicEntryType type;

  const GetComicInfoEvent({
    required this.comicId,
    required this.from,
    required this.pluginId,
    required this.type,
  });

  @override
  List<Object> get props => [comicId, from, pluginId, type];
}
