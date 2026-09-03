part of 'get_comic_info_bloc.dart';

class GetComicInfoEvent extends Equatable {
  final String comicId;
  final String from;
  final ComicEntryType type;
  final Map<String, dynamic>? extern;

  const GetComicInfoEvent({
    required this.comicId,
    required this.from,
    required this.type,
    this.extern,
  });

  @override
  List<Object?> get props => [comicId, from, type, extern];
}
