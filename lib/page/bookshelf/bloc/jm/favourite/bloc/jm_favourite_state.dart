part of 'jm_favourite_bloc.dart';

enum JmFavouriteStatus { initial, success, failure }

@freezed
abstract class JmFavouriteState with _$JmFavouriteState {
  const factory JmFavouriteState({
    @Default(JmFavouriteStatus.initial) JmFavouriteStatus status,
    @Default([]) List<JmFavorite> comics,
    @Default('') String result,
    @Default(SearchEnter()) SearchEnter searchEnterConst,
  }) = _JmFavouriteState;
}
