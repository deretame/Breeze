import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import 'package:zephyr/widgets/toast.dart';

import 'package:zephyr/main.dart';

enum DeleteType { download, history }

Widget deletingDialog(BuildContext context, Function refresh, DeleteType type) {
  final bodyText = type == DeleteType.download
      ? t.bookshelf.confirmDeleteAllDownloadsContent
      : t.bookshelf.confirmClearHistoryContent;
  final deletedText = type == DeleteType.download
      ? t.bookshelf.allDownloadRecordsAndFilesDeleted
      : t.bookshelf.historyRecordsCleared;
  final buttonText = type == DeleteType.download
      ? t.bookshelf.deleteAllDownloadRecordsAndFiles
      : t.bookshelf.clearHistoryRecords;

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
              title: Text(t.common.confirm),
              content: Text(bodyText),
              actions: [
                TextButton(
                  onPressed: () => dialogContext.pop(), // 使用 dialogContext
                  child: Text(t.common.cancel),
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
                  child: Text(t.common.ok),
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
