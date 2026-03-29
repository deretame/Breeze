part of 'local_favorite_bloc.dart';

@freezed
abstract class LocalFavoriteEvent with _$LocalFavoriteEvent {
  const factory LocalFavoriteEvent({
    @Default(SearchEnter()) SearchEnter searchEnterConst,
  }) = _LocalFavoriteEvent;
}
