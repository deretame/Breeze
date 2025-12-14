part of 'jm_cloud_favourite_bloc.dart';

@freezed
abstract class JmCloudFavouriteEvent with _$JmCloudFavouriteEvent {
  const factory JmCloudFavouriteEvent({
    @Default(1) int page,
    @Default('') String id,
    @Default('mr') String order,
    @Default(JmCloudFavouriteStatus.initial) JmCloudFavouriteStatus status,
  }) = _JmCloudFavouriteEvent;
}
