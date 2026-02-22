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

              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return _DownloadTaskTile(
                    task: task,
                    onDelete: () {
                      context.read<DowloadTaskBloc>().add(
                        DowloadTaskEvent.taskDeleted(task.id),
                      );
                      showInfoToast("已删除任务");
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _DownloadTaskTile extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback onDelete;

  const _DownloadTaskTile({required this.task, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _buildStatusIcon(),
        title: Text(task.comicName),
        subtitle: _buildSubtitle(),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (task.isDownloading) {
      return const CircleAvatar(
        backgroundColor: Colors.blue,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    } else {
      return const CircleAvatar(
        backgroundColor: Colors.orange,
        child: Icon(Icons.hourglass_empty, color: Colors.white),
      );
    }
  }

  Widget _buildSubtitle() {
    return Text(task.status, style: const TextStyle(color: Colors.blue));
  }
}
