part of 'favourite_bloc.dart';

sealed class Favourite extends Equatable {
  const Favourite();
}

class FavouriteEvent extends Favourite {
  final int pageCount;
  final String refresh;

  const FavouriteEvent(
    this.pageCount,
    this.refresh,
  );

  @override
  List<Object> get props => [pageCount, refresh];
}
