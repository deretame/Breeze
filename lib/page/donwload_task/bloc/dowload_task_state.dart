part of 'dowload_task_bloc.dart';

@freezed
class DowloadTaskState with _$DowloadTaskState {
  const factory DowloadTaskState.initial() = _Initial;
  const factory DowloadTaskState.loaded({
    required List<DownloadTask> tasks,
    required int pendingCount,
  }) = _Loaded;
}
