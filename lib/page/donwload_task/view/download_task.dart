import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/donwload_task/bloc/dowload_task_bloc.dart';
import 'package:zephyr/widgets/toast.dart';

@RoutePage()
class DownloadTaskPage extends StatelessWidget {
  const DownloadTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DowloadTaskBloc()..add(DowloadTaskEvent.started()),
      child: const _DownloadTaskView(),
    );
  }
}

class _DownloadTaskView extends StatelessWidget {
  const _DownloadTaskView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("下载任务")),
      body: BlocBuilder<DowloadTaskBloc, DowloadTaskState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loaded: (tasks, pendingCount) {
              if (tasks.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "暂无下载任务",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              final downloadingTasks = tasks.where((t) => t.isDownloading).toList();
              final pendingTasks = tasks.where((t) => !t.isDownloading).toList();

              return CustomScrollView(
                slivers: [
                  if (downloadingTasks.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          "正在下载",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = downloadingTasks[index];
                          return _DownloadingTaskTile(
                            key: ValueKey(task.id),
                            task: task,
                          );
                        },
                        childCount: downloadingTasks.length,
                      ),
                    ),
                  ],
                  if (pendingTasks.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          "等待中 (${pendingTasks.length})",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = pendingTasks[index];
                          return _PendingTaskTile(
                            key: ValueKey(task.id),
                            task: task,
                            onDelete: () {
                              context.read<DowloadTaskBloc>().add(
                                DowloadTaskEvent.taskDeleted(task.id),
                              );
                              showInfoToast("已删除任务");
                            },
                          );
                        },
                        childCount: pendingTasks.length,
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _DownloadingTaskTile extends StatelessWidget {
  final DownloadTask task;

  const _DownloadingTaskTile({required super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        title: Text(task.comicName),
        subtitle: Text(
          task.status,
          style: const TextStyle(color: Colors.blue),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
      ),
    );
  }
}

class _PendingTaskTile extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback onDelete;

  const _PendingTaskTile({required super.key, required this.task, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.hourglass_empty, color: Colors.white),
        ),
        title: Text(task.comicName),
        subtitle: Text(
          task.status,
          style: const TextStyle(color: Colors.grey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
