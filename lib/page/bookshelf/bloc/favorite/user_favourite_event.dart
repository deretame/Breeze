part of 'user_favourite_bloc.dart';

sealed class UserFavorite extends Equatable {
  const UserFavorite();
}

class UserFavouriteEvent extends UserFavorite {
  final UserFavouriteStatus status;
  final int pageCount;
  final String refresh;

  const UserFavouriteEvent(this.status, this.pageCount, this.refresh);

  @override
  List<Object> get props => [status, pageCount, refresh];
}
