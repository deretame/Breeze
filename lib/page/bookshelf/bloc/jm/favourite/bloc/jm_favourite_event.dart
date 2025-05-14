part of 'jm_favourite_bloc.dart';

@freezed
abstract class JmFavouriteEvent with _$JmFavouriteEvent {
  const factory JmFavouriteEvent({
    @Default(SearchEnter()) SearchEnter searchEnterConst,
  }) = _JmFavouriteEvent;
}
