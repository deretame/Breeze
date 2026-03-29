part of 'local_favorite_bloc.dart';

enum LocalFavoriteStatus { initial, success, failure }

@freezed
abstract class LocalFavoriteState with _$LocalFavoriteState {
  const factory LocalFavoriteState({
    @Default(LocalFavoriteStatus.initial) LocalFavoriteStatus status,
    @Default([]) List<UnifiedComicFavorite> comics,
    @Default('') String result,
    @Default(SearchEnter()) SearchEnter searchEnterConst,
  }) = _LocalFavoriteState;
}
