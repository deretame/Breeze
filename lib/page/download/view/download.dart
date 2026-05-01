import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/page/download/widgets/eps.dart';
import 'package:zephyr/util/foreground_task/data/download_task_json.dart';
import 'package:zephyr/util/foreground_task/init.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../comments/widgets/title.dart';
import 'package:zephyr/util/error_filter.dart';

@RoutePage()
class DownloadPage extends StatefulWidget {
  final UnifiedComicDownloadInfo downloadInfo;

  const DownloadPage({super.key, required this.downloadInfo});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  UnifiedComicDownloadInfo get downloadInfo => widget.downloadInfo;
  String get source =>
      (downloadInfo.source.trim().isEmpty ? '' : downloadInfo.source).trim();

  late Map<int, bool> _downloadInfo;
  late Map<String, Map<String, dynamic>> _chapterExternById;
  late UnifiedComicDownload? comicDownloadInfo;

  void onUpdateDownloadInfo(int order) {
    setState(() {
      _downloadInfo[order] = !_downloadInfo[order]!;
    });
  }

  @override
  void initState() {
    super.initState();
    if (source.isEmpty) {
      throw StateError('download source pluginId is required');
    }
    _downloadInfo = {};
    _chapterExternById = <String, Map<String, dynamic>>{};
    for (var ep in downloadInfo.chapters) {
      _downloadInfo[ep.order] = false;
      final chapterId = ep.id.trim();
      if (chapterId.isNotEmpty) {
        _chapterExternById[chapterId] = Map<String, dynamic>.from(ep.extern);
      }
    }
    final query = objectbox.unifiedDownloadBox.query(
      UnifiedComicDownload_.uniqueKey.equals('$source:${downloadInfo.comicId}'),
    );
    comicDownloadInfo = query.build().findFirst();
    if (comicDownloadInfo != null) {
      final storedChapters = resolveStoredDownloadChapters(comicDownloadInfo!);
      final downloadedChapterIds = storedChapters
          .map((chapter) => chapter.id.trim())
          .where((id) => id.isNotEmpty)
          .toSet();
      final downloadedOrders = storedChapters
          .map((chapter) => chapter.order)
          .where((order) => order > 0)
          .toSet();
      for (var ep in downloadInfo.chapters) {
        final chapterId = ep.id.trim();
        final selectedById =
            chapterId.isNotEmpty && downloadedChapterIds.contains(chapterId);
        final selectedByOrder = downloadedOrders.contains(ep.order);
        _downloadInfo[ep.order] = selectedById || selectedByOrder;
      }
    }
  }

  // 判断是否所有章节都被选中
  bool get isAllSelected {
    return downloadInfo.chapters.every((ep) => _downloadInfo[ep.order] == true);
  }

  // 切换全选或取消全选
  void toggleSelectAll() {
    setState(() {
      bool newState = !isAllSelected; // 如果当前是全选，则取消全选；反之亦然
      for (var ep in downloadInfo.chapters) {
        _downloadInfo[ep.order] = newState;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ScrollableTitle(text: downloadInfo.title),
        actions: [
          // 动态切换全选/取消全选按钮
          IconButton(
            icon: Icon(isAllSelected ? Icons.deselect : Icons.select_all),
            onPressed: toggleSelectAll,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              88,
            ), // reserved bottom padding for FAB
            itemCount: downloadInfo.chapters.length,
            itemBuilder: (context, index) {
              final chapter = downloadInfo.chapters[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: EpsWidget(
                  chapter: chapter,
                  downloaded: _downloadInfo[chapter.order]!,
                  onUpdateDownloadInfo: onUpdateDownloadInfo,
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.download),
        label: const Text("开始下载"),
        onPressed: () {
          logger.d("开始下载");
          download();
        },
      ),
    );
  }

  Future<void> download() async {
    final selectedChapters = downloadInfo.chapters
        .where((chapter) => _downloadInfo[chapter.order] == true)
        .map((chapter) => chapter.id.trim())
        .where((chapterId) => chapterId.isNotEmpty)
        .toList();
    if (selectedChapters.isEmpty) {
      showErrorToast("请选择要下载的章节");
      return;
    }
    final task = DownloadTaskJson(
      from: source,
      comicId: downloadInfo.comicId,
      comicName: downloadInfo.title,
      selectedChapters: selectedChapters,
      chapterExternById: selectedChapters.fold<Map<String, dynamic>>(
        <String, dynamic>{},
        (acc, chapterId) {
          final extern = _chapterExternById[chapterId];
          if (extern != null && extern.isNotEmpty) {
            acc[chapterId] = extern;
          }
          return acc;
        },
      ),
    );
    logger.d('download task payload=${task.toJson()}');
    logger.d(
      'download chapter map=${downloadInfo.chapters.map((chapter) => {'order': chapter.order, 'id': chapter.id, 'selected': _downloadInfo[chapter.order] == true}).toList()}',
    );
    try {
      await startDownloadTask(task);
      showInfoToast("下载任务已启动");
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      showErrorToast("下载任务启动失败，${normalizeSearchErrorMessage(e)}");
    }
  }
}
