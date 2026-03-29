import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
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
                      objectbox.unifiedDownloadBox.removeAll();
                      deleteDirectory(
                        '/data/data/com.zephyr.breeze/files/downloads',
                      );
                    } else {
                      var allHistory = objectbox.unifiedHistoryBox.getAll();

                      for (var history in allHistory) {
                        history.deleted = true;
                        history.updatedAt = DateTime.now().toUtc();
                        history.lastReadAt = history.updatedAt;
                      }

                      objectbox.unifiedHistoryBox.putMany(allHistory);
                    }

                    // 刷新页面
                    refresh();
                    showSuccessToast(deletedText);

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
