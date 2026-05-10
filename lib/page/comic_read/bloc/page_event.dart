part of 'page_bloc.dart';

class PageEvent extends Equatable {
  final String comicId;
  final int epsId;
  final String chapterId;
  final Map<String, dynamic> chapterExtern;
  final String from;
  final ComicEntryType type;
  final dynamic comicInfo;

  const PageEvent(
    this.comicId,
    this.epsId,
    this.chapterId,
    this.chapterExtern,
    this.from,
    this.type, {
    this.comicInfo,
  });

  @override
  List<Object> get props => [
    comicId,
    epsId,
    chapterId,
    chapterExtern,
    from,
    type,
  ];
}
