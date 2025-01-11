part of 'user_favourite_bloc.dart';

sealed class UserFavorite extends Equatable {
  const UserFavorite();
}

class UserFavouriteEvent extends UserFavorite {
  final int pageCount;
  final String refresh;

  const UserFavouriteEvent(
    this.pageCount,
    this.refresh,
  );

  @override
  List<Object> get props => [pageCount, refresh];
}
