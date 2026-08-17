import 'dart:async';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cs/cs.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/donwload_task/bloc/dowload_task_bloc.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/widgets/toast.dart';

@RoutePage()
class DownloadTaskPage extends StatelessWidget {
  const DownloadTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    final csSettings = context.watch<CsModeCubit>().state;
    if (csSettings.isCsMode &&
        csSettings.downloadMode == CsDownloadMode.server) {
      return const _CsServerDownloadTaskView();
    }
    return BlocProvider(
      create: (_) => DowloadTaskBloc()..add(DowloadTaskEvent.started()),
      child: const _DownloadTaskView(),
    );
  }
}

class _CsServerDownloadTaskView extends StatefulWidget {
  const _CsServerDownloadTaskView();

  @override
  State<_CsServerDownloadTaskView> createState() =>
      _CsServerDownloadTaskViewState();
}

class _CsServerDownloadTaskViewState extends State<_CsServerDownloadTaskView> {
  late Future<List<CsDownloadTask>> _tasks;
  StreamSubscription<CsRealtimeEvent>? _eventSubscription;
  Timer? _eventReloadTimer;

  @override
  void initState() {
    super.initState();
    _tasks = CsRuntimeContext.I.serverDownloads();
    _eventSubscription = CsRuntimeContext.I.events.listen(_handleRealtimeEvent);
  }

  @override
  void dispose() {
    _eventReloadTimer?.cancel();
    unawaited(_eventSubscription?.cancel());
    super.dispose();
  }

  void _handleRealtimeEvent(CsRealtimeEvent event) {
    if (!event.topic.startsWith('downloads.')) {
      return;
    }
    _eventReloadTimer?.cancel();
    _eventReloadTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        unawaited(_reload());
      }
    });
  }

  Future<void> _reload() async {
    setState(() {
      _tasks = CsRuntimeContext.I.serverDownloads();
    });
    await _tasks;
  }

  Future<void> _cancel(CsDownloadTask task) async {
    final client = CsRuntimeContext.I.client;
    if (client == null) return;
    await client.cancelServerDownload(task.taskId);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.download.title),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
      body: FutureBuilder<List<CsDownloadTask>>(
        future: _tasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('服务端下载读取失败：${snapshot.error}'));
          }
          final tasks = snapshot.data ?? const <CsDownloadTask>[];
          if (tasks.isEmpty) {
            return Center(child: Text(t.download.noTasks));
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final isActive = switch (task.status) {
                  'completed' || 'failed' || 'cancelled' => false,
                  _ => true,
                };
                final title =
                    task.payload['comic_id'] as String? ?? task.taskId;
                final plugin = task.payload['plugin_id'] as String? ?? '';
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircularProgressIndicator(
                      value: task.progress / 100,
                    ),
                    title: Text(title),
                    subtitle: Text(
                      '$plugin · ${task.status} · ${task.progress}%',
                    ),
                    trailing: isActive
                        ? IconButton(
                            onPressed: () => _cancel(task),
                            icon: const Icon(Icons.cancel_outlined),
                          )
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
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
