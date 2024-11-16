part of 'page_bloc.dart';

sealed class PageEvent extends Equatable {
  const PageEvent();
}

class GetPage extends PageEvent {
  final String comicId;
  final int epsId;

  const GetPage(this.comicId, this.epsId);

  @override
  List<Object> get props => [comicId, epsId];
}
