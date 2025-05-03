part of 'get_comic_eps_bloc.dart';

class GetComicEpsEvent extends Equatable {
  final Comic comic;

  const GetComicEpsEvent({required this.comic});

  @override
  List<Object> get props => [comic];
}
