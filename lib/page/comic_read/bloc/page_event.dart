part of 'page_bloc.dart';

class PageEvent extends Equatable {
  final String comicId;
  final int epsId;
  final From from;

  const PageEvent(this.comicId, this.epsId, this.from);

  @override
  List<Object> get props => [comicId, epsId];
}
