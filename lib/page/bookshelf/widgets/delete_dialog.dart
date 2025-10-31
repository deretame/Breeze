import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // 1. 导入 Bloc
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../main.dart';

enum DeleteType { download, history }

Widget deletingDialog(BuildContext context, Function refresh, DeleteType type) {
  final bodyText = type == DeleteType.download
      ? '确定要删除所有下载记录及其文件吗？此操作不可恢复！'
      : '确定要清空历史记录吗？此操作不可恢复！';
  final deletedText = type == DeleteType.download ? '所有下载记录及其文件已删除' : '历史记录已清空';
  final buttonText = type == DeleteType.download ? '删除所有下载记录及其文件' : '清空历史记录';

  return Center(
    child: TextButton(
      onPressed: () {
        // 这里的 `context` 是 `deletingDialog` 被调用时传入的 context,
        // 它可以访问到 BlocProvider
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            // dialogContext 是对话框自己的 context，
            // 它是 `context` 的子级，所以它也可以访问到 BlocProvider
            return AlertDialog(
              title: Text('确认删除'),
              content: Text(bodyText),
              actions: [
                TextButton(
                  onPressed: () => dialogContext.pop(), // 使用 dialogContext
                  child: Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    if (type == DeleteType.download) {
                      objectbox.bikaDownloadBox.removeAll();
                      deleteDirectory(
                        '/data/data/com.zephyr.breeze/files/downloads',
                      );
                    } else {
                      final comicChoice = context
                          .read<GlobalSettingCubit>()
                          .state
                          .comicChoice;

                      if (comicChoice == 1) {
                        var allHistory = objectbox.bikaHistoryBox.getAll();

                        for (var history in allHistory) {
                          history.deleted = true;
                          history.history = DateTime.now().toUtc();
                        }

                        objectbox.bikaHistoryBox.putMany(allHistory);
                      } else if (comicChoice == 2) {
                        var allHistory = objectbox.jmHistoryBox.getAll();

                        for (var history in allHistory) {
                          history.deleted = true;
                          history.history = DateTime.now().toUtc();
                        }

                        objectbox.jmHistoryBox.putMany(allHistory);
                      }
                    }

                    // 刷新页面
                    refresh();
                    showSuccessToast(deletedText);

                    if (type == DeleteType.download) {
                      eventBus.fire(DownloadEvent(EventType.showInfo, false));
                    } else {
                      eventBus.fire(HistoryEvent(EventType.showInfo, false));
                    }

                    // 关闭对话框
                    dialogContext.pop(); // 使用 dialogContext
                  },
                  child: Text('确认'),
                ),
              ],
            );
          },
        );
      },
      child: Text(buttonText),
    ),
  );
}
