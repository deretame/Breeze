import 'package:auto_route/annotations.dart';
import 'package:material_ui/material_ui.dart' hide Page;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/donwload_task/bloc/dowload_task_bloc.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/service/download/download_queue_manager.dart';
import 'package:zephyr/service/download/download_task_progress.dart';
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
                          onRetry: task.taskInfo?.stateCode == 'failed'
                              ? () => DownloadQueueManager.instance.retryTask(
                                  task.id,
                                )
                              : null,
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
    final payload = task.taskInfo;
    final progress = payload == null
        ? null
        : downloadTaskPayloadProgressFraction(payload);
    final progressMessage = payload == null
        ? ''
        : downloadTaskPayloadProgressMessage(payload);
    // 任务状态和 checkpoint 进度是分开写入的。下载中只显示结构化进度，
    // 避免两次 ObjectBox 更新之间蓝色状态文字短暂出现造成闪烁。
    final statusMessage = progressMessage.isEmpty ? task.status : '';

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
              value: progress,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        title: Text(task.comicName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (statusMessage.isNotEmpty)
              Text(
                statusMessage,
                style: const TextStyle(color: Colors.blue),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (progressMessage.isNotEmpty)
              Text(
                progressMessage,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (progress != null) ...[
              const SizedBox(height: 4),
              LinearProgressIndicator(value: progress),
            ],
          ],
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
  final VoidCallback? onRetry;
  final VoidCallback onDelete;

  const _PendingTaskTile({
    required super.key,
    required this.task,
    this.onRetry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final payload = task.taskInfo;
    final progressMessage = payload == null
        ? ''
        : downloadTaskPayloadProgressMessage(payload);
    final statusMessage = task.status == progressMessage ? '' : task.status;
    final failureMessage = payload?.stateCode == 'failed'
        ? payload?.lastErrorMessage.trim() ?? ''
        : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.hourglass_empty, color: Colors.white),
        ),
        title: Text(task.comicName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (statusMessage.isNotEmpty)
              Text(
                statusMessage,
                style: const TextStyle(color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (progressMessage.isNotEmpty)
              Text(
                progressMessage,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (failureMessage.isNotEmpty)
              InkWell(
                onTap: () => _showDownloadFailureDetails(
                  context,
                  failureMessage,
                ),
                child: Text(
                  failureMessage,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onRetry != null)
              IconButton(
                tooltip: t.common.retry,
                icon: const Icon(Icons.refresh),
                onPressed: onRetry,
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

void _showDownloadFailureDetails(BuildContext context, String message) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t.download.notificationFailedTitle),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(child: SelectableText(message)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(t.common.ok),
        ),
      ],
    ),
  );
}
