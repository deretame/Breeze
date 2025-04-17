import 'package:flutter/material.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../main.dart';

enum DeleteType { download, history }

Widget deletingDialog(BuildContext context, Function refresh, DeleteType type) {
  final bodyText =
      type == DeleteType.download
          ? '确定要删除所有下载记录及其文件吗？此操作不可恢复！'
          : '确定要清空历史记录吗？此操作不可恢复！';
  final deletedText = type == DeleteType.download ? '所有下载记录及其文件已删除' : '历史记录已清空';
  final buttonText = type == DeleteType.download ? '删除所有下载记录及其文件' : '清空历史记录';

  return Center(
    child: TextButton(
      onPressed: () {
        // 弹出确认对话框
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('确认删除'),
              content: Text(bodyText),
              actions: [
                TextButton(
                  onPressed: () {
                    // 关闭对话框
                    Navigator.of(context).pop();
                  },
                  child: Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    if (type == DeleteType.download) {
                      // 执行删除操作
                      objectbox.bikaDownloadBox.removeAll();
                      deleteDirectory(
                        '/data/data/com.zephyr.breeze/files/downloads',
                      );
                    } else {
                      // 执行清空操作
                      var allHistory = objectbox.bikaHistoryBox.getAll();

                      for (var history in allHistory) {
                        history.deleted = true;
                        history.updatedAt = DateTime.now().toUtc();
                      }

                      objectbox.bikaHistoryBox.putMany(allHistory);
                    }

                    // 刷新页面
                    refresh();
                    showSuccessToast(deletedText);

                    if (type == DeleteType.download) {
                      eventBus.fire(DownloadEvent(EventType.showInfo));
                    } else {
                      eventBus.fire(HistoryEvent(EventType.showInfo));
                    }

                    // 关闭对话框
                    Navigator.of(context).pop();
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
