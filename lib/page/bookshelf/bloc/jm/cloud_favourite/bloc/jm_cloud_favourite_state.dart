part of 'jm_cloud_favourite_bloc.dart';

enum JmCloudFavouriteStatus {
  initial,
  success,
  failure,
  loadingMore,
  loadMoreFail,
}

@freezed
abstract class JmCloudFavouriteState with _$JmCloudFavouriteState {
  const factory JmCloudFavouriteState({
    @Default(JmCloudFavouriteStatus.initial) JmCloudFavouriteStatus status,
    @Default([]) List<ListElement> list,
    @Default([]) List<FolderList> folderList,
    @Default(JmCloudFavouriteEvent()) JmCloudFavouriteEvent event,
    @Default(true) bool hasMore,
    @Default('') String result,
  }) = _JmCloudFavouriteState;
}
