import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/donwload_task/bloc/dowload_task_bloc.dart';
import 'package:zephyr/i18n/strings.g.dart';
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
      appBar: AppBar(title: Text(t.download.title)),
      body: BlocBuilder<DowloadTaskBloc, DowloadTaskState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loaded: (tasks, pendingCount) {
              if (tasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.download_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t.download.noTasks,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final downloadingTasks = tasks
                  .where((t) => t.isDownloading)
                  .toList();
              final pendingTasks = tasks
                  .where((t) => !t.isDownloading)
                  .toList();

              return CustomScrollView(
                slivers: [
                  if (downloadingTasks.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          t.download.downloading,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final task = downloadingTasks[index];
                        return _DownloadingTaskTile(
                          key: ValueKey(task.id),
                          task: task,
                        );
                      }, childCount: downloadingTasks.length),
                    ),
                  ],
                  if (pendingTasks.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          t.download.pending(count: pendingTasks.length),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final task = pendingTasks[index];
                        return _PendingTaskTile(
                          key: ValueKey(task.id),
                          task: task,
                          onDelete: () {
                            context.read<DowloadTaskBloc>().add(
                              DowloadTaskEvent.taskDeleted(task.id),
                            );
                            showInfoToast(t.download.taskDeleted);
                          },
                        );
                      }, childCount: pendingTasks.length),
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
        trailing: IconButton(
          icon: const Icon(Icons.cancel_outlined, color: Colors.blue),
          onPressed: () {
            final bloc = context.read<DowloadTaskBloc>();
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(t.download.cancelTask),
                content: Text(
                  t.download.cancelTaskConfirm(comicName: task.comicName),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      t.common.cancel,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      bloc.add(const DowloadTaskEvent.cancelCurrentTask());
                      Navigator.of(dialogContext).pop();
                    },
                    child: Text(
                      t.common.ok,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PendingTaskTile extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback onDelete;

  const _PendingTaskTile({
    required super.key,
    required this.task,
    required this.onDelete,
  });

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
