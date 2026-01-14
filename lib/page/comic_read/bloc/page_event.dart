part of 'page_bloc.dart';

class PageEvent extends Equatable {
  final String comicId;
  final int epsId;
  final From from;
  final ComicEntryType type;

  const PageEvent(this.comicId, this.epsId, this.from, this.type);

  @override
  List<Object> get props => [comicId, epsId, from, type];
}
