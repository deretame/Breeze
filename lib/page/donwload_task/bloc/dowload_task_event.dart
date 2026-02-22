part of 'dowload_task_bloc.dart';

@freezed
class DowloadTaskEvent with _$DowloadTaskEvent {
  const factory DowloadTaskEvent.started() = _Started;
  const factory DowloadTaskEvent.tasksUpdated(List<DownloadTask> tasks) =
      _TasksUpdated;
  const factory DowloadTaskEvent.taskDeleted(int taskId) = _TaskDeleted;
  const factory DowloadTaskEvent.clearCompleted() = _ClearCompleted;
}
