import 'dart:io';

import 'dart:async';
import 'dart:convert';

import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/download/download_cancel_signal.dart';
import 'package:zephyr/util/download/download_progress_reporter.dart';
import 'package:zephyr/util/download/qjs_download_runtime.dart';
import 'package:zephyr/util/foreground_task/data/download_task_json.dart';
import 'package:zephyr/util/foreground_task/task/shared_download.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/jm_url_set.dart';

Future<void> unifiedDownloadTask(
  DownloadProgressReporter reporter,
  DownloadTaskJson task,
) async {
  final from = task.from == 'jm' ? From.jm : From.bika;
  final runtimeName = runtimeNameForSource(from.name);
  Timer? progressTimer;
  bool running = true;

  final query = objectbox.downloadTaskBox
      .query(
        DownloadTask_.comicId
            .equals(task.comicId)
            .and(DownloadTask_.isDownloading.equals(true)),
      )
      .build();

  void updateTaskStatus(String status) {
    final dbTask = query.findFirst();
    if (dbTask != null) {
      dbTask.status = status;
      objectbox.downloadTaskBox.put(dbTask);
    }
  }

  Future<void> ensureTaskRunning() async {
    final currentTask = query.findFirst();
    if (isDownloadCancelSignaled(task.comicId) ||
        currentTask == null ||
        !currentTask.isDownloading) {
      await cancelTrackedQjsTasks(
        source: from.name,
        taskGroupKey: task.comicId,
      );
      throw const DownloadTaskCancelledException();
    }
  }

  try {
    await ensureQjsRuntimeReady(source: from.name);
    await ensureTaskRunning();

    if (from == From.jm) {
      await Future.wait([
        setFastestUrlIndex(
          qjsRuntimeName: runtimeName,
          qjsTaskGroupKey: task.comicId,
        ),
        setFastestImagesUrlIndex(
          qjsRuntimeName: runtimeName,
          qjsTaskGroupKey: task.comicId,
        ),
      ], eagerError: true);
    }

    updateTaskStatus('获取漫画信息中...');
    reporter.updateMessage('获取漫画信息中...');
    final detail = await getComicDetailByPlugin(task.comicId, from);

    final downloadInfo = UnifiedComicDownloadInfo.fromPluginSource(
      detail.source,
    );
    final selectedChapters = _resolveSelectedChapters(
      downloadInfo,
      task.selectedChapters,
    );

    updateTaskStatus('下载封面中...');
    reporter.updateMessage('下载封面中...');
    final cover = detail.normalInfo.comicInfo.cover;
    final coverExtension = Map<String, dynamic>.from(cover.extension);
    final coverFileName =
        coverExtension['path']?.toString() ??
        (cover.name.trim().isNotEmpty
            ? cover.name.trim()
            : '${task.comicId}.jpg');
    final coverPath = await downloadCoverAsset(
      from: from,
      url: cover.url,
      fileName: coverFileName,
      cartoonId: task.comicId,
      qjsName: runtimeName,
      qjsTaskGroupKey: task.comicId,
    );

    var normalInfo = detail.normalInfo.copyWith(recommend: const []);
    if (coverPath.startsWith('404')) {
      normalInfo = normalInfo.copyWith(
        comicInfo: normalInfo.comicInfo.copyWith(
          cover: normalInfo.comicInfo.cover.copyWith(url: ''),
        ),
      );
    }

    updateTaskStatus('获取章节信息中...');
    reporter.updateMessage('获取章节信息中...');
    final chapterResponses = <UnifiedPluginChapterResponse>[];
    for (final chapter in selectedChapters) {
      await ensureTaskRunning();
      chapterResponses.add(
        await _getChapterByPlugin(
          from: from,
          comicId: task.comicId,
          chapterTaskId: chapter.taskChapterId,
          runtimeName: runtimeName,
        ),
      );
    }

    final jobs = <DownloadImageJob>[];
    for (final response in chapterResponses) {
      for (var index = 0; index < response.chapter.docs.length; index++) {
        final doc = response.chapter.docs[index];
        jobs.add(
          DownloadImageJob(
            url: doc.url,
            fileName: _orderedImageFileName(
              index: index,
              originalName: doc.fileName.isNotEmpty ? doc.fileName : doc.name,
              url: doc.url,
            ),
            cartoonId: task.comicId,
            chapterId: response.chapter.epId,
            extern: {if (from == From.jm) 'decodeJmComic': true},
          ),
        );
      }
    }

    progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (running) {
        updateTaskStatus(reporter.message);
      }
    });

    await downloadImageJobs(
      from: from,
      jobs: jobs,
      slowDownload: task.slowDownload,
      qjsRuntimeName: runtimeName,
      qjsTaskGroupKey: task.comicId,
      ensureTaskRunning: ensureTaskRunning,
      reporter: reporter,
      concurrency: from == From.jm ? 5 : 10,
      onError: (error, job) async {
        if (from != From.jm || !error.toString().contains('404')) {
          throw error;
        }
        for (final response in chapterResponses) {
          if (response.chapter.epId != job.chapterId) continue;
          final docs = response.chapter.docs;
          final index = docs.indexWhere(
            (doc) =>
                (doc.fileName.isNotEmpty ? doc.fileName : doc.name) ==
                job.fileName,
          );
          if (index != -1) {
            docs[index] = UnifiedPluginChapterDoc(
              name: docs[index].name,
              fileName: docs[index].fileName,
              url: '404',
              id: docs[index].id,
            );
          }
        }
      },
    );

    await _saveUnifiedDownload(
      from: from,
      task: task,
      normalInfo: normalInfo,
      selectedChapters: selectedChapters,
      chapterResponses: chapterResponses,
    );
    _markTaskCompleted(task.comicId);
  } finally {
    running = false;
    progressTimer?.cancel();
  }
}

List<UnifiedComicDownloadChapter> _resolveSelectedChapters(
  UnifiedComicDownloadInfo info,
  List<String> selectedIds,
) {
  final result = info.chapters
      .where((chapter) => selectedIds.contains(chapter.taskChapterId))
      .toList();
  return result.isEmpty ? info.chapters : result;
}

Future<UnifiedPluginChapterResponse> _getChapterByPlugin({
  required From from,
  required String comicId,
  required String chapterTaskId,
  required String runtimeName,
}) async {
  final core = from == From.bika
      ? {
          'comicId': comicId,
          'chapterId': chapterTaskId,
          'settings': {
            'proxy': objectbox.userSettingBox.get(1)!.bikaSetting.proxy,
            'imageQuality': 'original',
          },
        }
      : {
          'comicId': comicId,
          'chapterId': chapterTaskId,
          'path': '$currentJmBaseUrl/chapter',
          'useJwt': true,
        };

  final map = await callUnifiedComicPlugin(
    from: from,
    fnPath: 'getChapter',
    core: core,
    extern: {
      'source': from.name,
      'comicId': comicId,
      'chapterId': chapterTaskId,
    },
    runtimeName: runtimeName,
  );
  return UnifiedPluginChapterResponse.fromMap(map);
}

Future<void> _saveUnifiedDownload({
  required From from,
  required DownloadTaskJson task,
  required normal.NormalComicAllInfo normalInfo,
  required List<UnifiedComicDownloadChapter> selectedChapters,
  required List<UnifiedPluginChapterResponse> chapterResponses,
}) async {
  final now = DateTime.now().toUtc();
  final eps = chapterResponses
      .map(
        (response) => normal.Ep(
          id: response.chapter.epId,
          name: response.chapter.epName,
          order: selectedChapters
              .firstWhere(
                (e) => e.id == response.chapter.epId,
                orElse: () => selectedChapters.first,
              )
              .order,
        ),
      )
      .toList();

  final detail = normalInfo.copyWith(eps: eps, recommend: const []);
  final key = '${from.name}:${task.comicId}';
  final coverMap =
      jsonDecode(jsonEncode(detail.comicInfo.cover.toJson()))
          as Map<String, dynamic>;
  final creatorMap =
      jsonDecode(jsonEncode(detail.comicInfo.creator.toJson()))
          as Map<String, dynamic>;
  final titleMeta =
      (jsonDecode(
                jsonEncode(
                  detail.comicInfo.titleMeta.map((e) => e.toJson()).toList(),
                ),
              )
              as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
  final metadata =
      (jsonDecode(
                jsonEncode(
                  detail.comicInfo.metadata.map((e) => e.toJson()).toList(),
                ),
              )
              as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
  final chapters =
      (jsonDecode(jsonEncode(eps.map((e) => e.toJson()).toList())) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  final entity = UnifiedComicDownload(
    uniqueKey: key,
    source: from.name,
    comicId: task.comicId,
    title: detail.comicInfo.title,
    description: detail.comicInfo.description,
    cover: coverMap,
    creator: creatorMap,
    titleMeta: titleMeta,
    metadata: metadata,
    totalViews: detail.totalViews,
    totalLikes: detail.totalLikes,
    totalComments: detail.totalComments,
    isFavourite: detail.isFavourite,
    isLiked: detail.isLiked,
    allowComment: detail.allowComment,
    allowLike: detail.allowLike,
    allowFavorite: detail.allowFavorite,
    allowDownload: detail.allowDownload,
    chapters: chapters,
    detailJson: jsonEncode(
      detail
          .copyWith(extension: {...detail.extension, 'version': 'v2'})
          .toJson(),
    ),
    storageRoot:
        '${await getDownloadPath()}${Platform.pathSeparator}${from.name}${Platform.pathSeparator}original${Platform.pathSeparator}${task.comicId}',
    createdAt: now,
    updatedAt: now,
    downloadedAt: now,
    deleted: false,
    schemaVersion: 2,
  );

  final temp = objectbox.unifiedDownloadBox
      .query(UnifiedComicDownload_.uniqueKey.equals(key))
      .build()
      .find();
  objectbox.unifiedDownloadBox.removeMany(temp.map((e) => e.id).toList());
  objectbox.unifiedDownloadBox.put(entity);
}

String _orderedImageFileName({
  required int index,
  required String originalName,
  required String url,
}) {
  final candidate = originalName.split(RegExp(r'[\\/]')).last.trim();
  final fromUrl = Uri.tryParse(url.trim())?.pathSegments.last ?? '';
  final seed = candidate.isNotEmpty ? candidate : fromUrl;
  var extension = '';
  final dotIndex = seed.lastIndexOf('.');
  if (dotIndex != -1 && dotIndex < seed.length - 1) {
    extension = seed.substring(dotIndex);
  }
  if (extension.isEmpty) {
    extension = '.bin';
  }
  return '${(index + 1).toString().padLeft(4, '0')}$extension';
}

void _markTaskCompleted(String comicId) {
  final tasks = objectbox.downloadTaskBox
      .query(DownloadTask_.comicId.equals(comicId))
      .build()
      .find();
  for (final item in tasks) {
    item
      ..isCompleted = true
      ..isDownloading = false
      ..status = '下载完成';
  }
  if (tasks.isNotEmpty) {
    objectbox.downloadTaskBox.putMany(tasks);
  }
}
