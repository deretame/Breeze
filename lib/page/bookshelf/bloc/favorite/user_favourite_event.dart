part of 'user_favourite_bloc.dart';

sealed class UserFavorite extends Equatable {
  const UserFavorite();
}

class UserFavouriteEvent extends UserFavorite {
  final UserFavouriteStatus status;
  final int pageCount;
  final String refresh;
  final SearchEnter searchEnterConst;

  const UserFavouriteEvent(
    this.status,
    this.pageCount,
    this.refresh,
    this.searchEnterConst,
  );

  UserFavouriteEvent copyWith({
    UserFavouriteStatus? status,
    int? pageCount,
    String? refresh,
    SearchEnter? searchEnterConst,
  }) {
    return UserFavouriteEvent(
      status ?? this.status,
      pageCount ?? this.pageCount,
      refresh ?? this.refresh,
      searchEnterConst ?? this.searchEnterConst,
    );
  }

  @override
  List<Object> get props => [status, pageCount, refresh, searchEnterConst];
}
