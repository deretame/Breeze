import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/service/download/download_queue_manager.dart';
import 'package:zephyr/service/download/download_task_repository.dart';

part 'dowload_task_bloc.freezed.dart';
part 'dowload_task_event.dart';
part 'dowload_task_state.dart';

class DowloadTaskBloc extends Bloc<DowloadTaskEvent, DowloadTaskState> {
  StreamSubscription? _watchSubscription;

  DowloadTaskBloc() : super(_Initial()) {
    on<DowloadTaskEvent>(_onEvent);
  }

  void _onEvent(DowloadTaskEvent event, Emitter<DowloadTaskState> emit) {
    event.when(
      started: () => _watchTasks(emit),
      tasksUpdated: (tasks) => _handleTasksUpdated(tasks, emit),
      taskDeleted: (taskId) => _deleteTask(taskId, emit),
      cancelCurrentTask: () => _cancelCurrentTask(emit),
      clearCompleted: () => _clearCompletedTasks(emit),
    );
  }

  void _watchTasks(Emitter<DowloadTaskState> emit) {
    final watchedQuery = objectbox.downloadTaskBox
        .query(DownloadTask_.isCompleted.equals(false))
        .order(DownloadTask_.id)
        .watch();

    _watchSubscription = watchedQuery.listen((query) {
      final tasks = query.find();
      add(DowloadTaskEvent.tasksUpdated(tasks));
    });

    _refreshTasks(emit);
  }

  void _refreshTasks(Emitter<DowloadTaskState> emit) {
    final tasks = objectbox.downloadTaskBox
        .query(DownloadTask_.isCompleted.equals(false))
        .order(DownloadTask_.id)
        .build()
        .find();

    emit(DowloadTaskState.loaded(tasks: tasks, pendingCount: tasks.length));
  }

  void _handleTasksUpdated(
    List<DownloadTask> tasks,
    Emitter<DowloadTaskState> emit,
  ) {
    _refreshTasks(emit);
  }

  void _deleteTask(int taskId, Emitter<DowloadTaskState> emit) {
    final task = objectbox.downloadTaskBox.get(taskId);
    if (task == null) return;
    String? taskKey;
    try {
      taskKey = task.taskInfo?.taskKey;
    } catch (_) {
      taskKey = null;
    }
    // 先排空在途后台写再删，防止旧写复活已删除的任务。
    final removal = taskKey == null
        ? Future.value()
        : const DownloadTaskRepository().flushTaskWrites(taskKey);
    unawaited(removal.then((_) => objectbox.downloadTaskBox.remove(taskId)));
  }

  void _cancelCurrentTask(Emitter<DowloadTaskState> emit) {
    DownloadQueueManager.instance.cancelCurrentTask();
  }

  void _clearCompletedTasks(Emitter<DowloadTaskState> emit) {
    final completedTasks = objectbox.downloadTaskBox
        .query(DownloadTask_.isCompleted.equals(true))
        .build()
        .find();

    for (final task in completedTasks) {
      objectbox.downloadTaskBox.remove(task.id);
    }
  }

  @override
  Future<void> close() {
    _watchSubscription?.cancel();
    return super.close();
  }
}
