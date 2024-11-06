part of 'comic_list_bloc.dart';

sealed class ComicListEvent extends Equatable {
  const ComicListEvent();

  @override
  List<Object> get props => [];
}

class FetchComicList extends ComicListEvent {
  final GetInfo getInfo;

  const FetchComicList(this.getInfo);

  @override
  List<Object> get props => [getInfo];
}
