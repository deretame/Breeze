part of 'get_comic_eps_bloc.dart';

sealed class GetComicEpsEvent extends Equatable {
  const GetComicEpsEvent();
}

class GetComicEps extends GetComicEpsEvent {
  final Comic comic;

  const GetComicEps(this.comic);

  @override
  List<Object> get props => [comic];
}
