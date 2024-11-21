part of 'favourite_bloc.dart';

enum FavouriteStatus { initial, success, failure, loadingMore, getMoreFailure }

final class FavouriteState extends Equatable {
  final FavouriteStatus status;
  final List<ComicNumber> comics;
  final bool hasReachedMax;
  final String result;
  final int pageCount;
  final int pagesCount;
  final String refresh;

  const FavouriteState({
    this.status = FavouriteStatus.initial,
    this.comics = const [],
    this.hasReachedMax = false,
    this.result = '',
    this.pageCount = 0,
    this.pagesCount = 0,
    this.refresh = '',
  });

  FavouriteState copyWith({
    FavouriteStatus? status,
    List<ComicNumber>? comics,
    bool? hasReachedMax,
    String? result,
    int? pageCount,
    int? pagesCount,
    String? refresh,
  }) {
    return FavouriteState(
      status: status ?? this.status,
      comics: comics ?? this.comics,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      result: result ?? this.result,
      pageCount: pageCount ?? this.pageCount,
      pagesCount: pagesCount ?? this.pagesCount,
      refresh: refresh ?? this.refresh,
    );
  }

  @override
  List<Object?> get props =>
      [status, comics, hasReachedMax, result, pageCount, pagesCount, refresh];
}
