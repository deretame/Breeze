import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/network/http/plugin/qjs_download_runtime.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/util/download/download_cancel_signal.dart';
import 'package:zephyr/util/download/download_progress_reporter.dart';
import 'package:zephyr/util/foreground_task/data/download_task_json.dart';
import 'package:zephyr/util/foreground_task/task/shared_download.dart';
import 'package:zephyr/util/get_path.dart';

class _ResolvedDownloadChapter {
  const _ResolvedDownloadChapter({
    required this.chapterId,
    required this.requestId,
    required this.storageChapterId,
    required this.logicalKey,
    required this.title,
    required this.order,
    required this.extern,
  });

  final String chapterId;
  final String requestId;
  final String storageChapterId;
  final String logicalKey;
  final String title;
  final int order;
  final Map<String, dynamic> extern;
}

Future<void> unifiedDownloadTask(
  DownloadProgressReporter reporter,
  DownloadTaskJson task,
) async {
  logger.d('unifiedDownloadTask received payload=${task.toJson()}');
  final pluginId = (task.from).trim();
  final from = pluginId;
  final runtimeName = runtimeNameForPluginId(pluginId);
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
        pluginId: pluginId,
        taskGroupKey: task.comicId,
      );
      throw const DownloadTaskCancelledException();
    }
  }

  try {
    await ensureQjsRuntimeReady(pluginId: pluginId);
    await ensureTaskRunning();
    await preparePluginDownloadRuntime(
      from: from,
      pluginId: pluginId,
      runtimeName: runtimeName,
      taskGroupKey: task.comicId,
    );

    updateTaskStatus('获取漫画信息中...');
    reporter.updateMessage('获取漫画信息中...');
    final detail = await getComicDetailByPlugin(
      task.comicId,
      from,
      pluginId: pluginId,
    );

    final downloadInfo = UnifiedComicDownloadInfo.fromString(detail.source);
    final selectedChapters = _resolveSelectedChapters(downloadInfo, task);

    updateTaskStatus('下载封面中...');
    reporter.updateMessage('下载封面中...');
    final cover = detail.normalInfo.comicInfo.cover;
    final coverExtension = Map<String, dynamic>.from(cover.extern);
    final rawCoverFileName = cover.path.trim().isNotEmpty
        ? cover.path
        : coverExtension['path']?.toString() ?? '';
    String coverPath = '404';
    if (rawCoverFileName.trim().isNotEmpty && cover.url.trim().isNotEmpty) {
      final coverFileName = normalizeStoredAssetPath(rawCoverFileName);
      coverPath = await downloadCoverAsset(
        from: from,
        url: cover.url,
        path: coverFileName,
        cartoonId: task.comicId,
        qjsName: runtimeName,
        qjsTaskGroupKey: task.comicId,
      );
    }

    var normalInfo = detail.normalInfo.copyWith(recommend: const []);
    if (coverPath.startsWith('404')) {
      final clearedCoverExtension = {
        ...normalInfo.comicInfo.cover.extern,
        'path': '',
      };
      normalInfo = normalInfo.copyWith(
        comicInfo: normalInfo.comicInfo.copyWith(
          cover: normalInfo.comicInfo.cover.copyWith(
            url: '',
            path: '',
            extern: clearedCoverExtension,
          ),
        ),
      );
    }

    void reportChapterFetchProgress(int completed, int total) {
      if (total <= 0) {
        const message = '获取章节信息中...';
        updateTaskStatus(message);
        reporter.updateMessage(message);
        return;
      }
      final percent = ((completed / total) * 100).floor();
      final message = '获取章节信息中... ($completed/$total, $percent%)';
      updateTaskStatus(message);
      reporter.updateMessage(message);
    }

    reportChapterFetchProgress(0, selectedChapters.length);
    final chapterResponses = <UnifiedPluginChapterResponse>[];
    for (var index = 0; index < selectedChapters.length; index++) {
      final chapter = selectedChapters[index];
      await ensureTaskRunning();
      final requestChapterId = _resolveChapterRequestId(chapter);
      final chapterExtern = _resolveChapterExtern(chapter);
      logger.d(
        'download getChapter plugin=$pluginId comicId=${task.comicId} chapter.id=${chapter.chapterId} order=${chapter.order} requestChapterId=$requestChapterId storageChapterId=${chapter.storageChapterId} logicalKey=${chapter.logicalKey} extern=$chapterExtern',
      );
      chapterResponses.add(
        await _getChapterByPlugin(
          from: from,
          pluginId: pluginId,
          comicId: task.comicId,
          chapterId: requestChapterId,
          runtimeName: runtimeName,
          extern: {...chapterExtern, 'chapterId': requestChapterId},
        ),
      );
      reportChapterFetchProgress(index + 1, selectedChapters.length);
    }

    final jobs = <DownloadImageJob>[];
    for (
      var chapterIndex = 0;
      chapterIndex < chapterResponses.length;
      chapterIndex++
    ) {
      final response = chapterResponses[chapterIndex];
      final selectedChapter = selectedChapters[chapterIndex];
      for (var index = 0; index < response.chapter.docs.length; index++) {
        final doc = response.chapter.docs[index];
        jobs.add(
          DownloadImageJob(
            url: doc.url,
            path: doc.path,
            cartoonId: task.comicId,
            chapterId: response.chapter.epId,
            storageChapterId: selectedChapter.storageChapterId,
            extern: doc.extern,
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
      qjsRuntimeName: runtimeName,
      qjsTaskGroupKey: task.comicId,
      ensureTaskRunning: ensureTaskRunning,
      reporter: reporter,
      concurrency: 5,
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

String _resolveChapterRequestId(_ResolvedDownloadChapter chapter) {
  final requestId = chapter.requestId.trim();
  if (requestId.isNotEmpty) {
    return requestId;
  }

  final order = chapter.order <= 0 ? 1 : chapter.order;
  return order.toString();
}

List<_ResolvedDownloadChapter> _resolveSelectedChapters(
  UnifiedComicDownloadInfo info,
  DownloadTaskJson task,
) {
  if (task.chapterRefs.isEmpty) {
    throw StateError('DownloadTaskJson.chapterRefs 不能为空');
  }

  return task.chapterRefs.map((ref) {
    final matched = _findMatchingChapter(info.chapters, ref);
    final matchedExtern = matched != null
        ? Map<String, dynamic>.from(matched.extern)
        : const <String, dynamic>{};

    return _ResolvedDownloadChapter(
      chapterId: ref.chapterId.trim().isNotEmpty
          ? ref.chapterId.trim()
          : (matched?.id.trim() ?? ''),
      requestId: ref.requestId.trim().isNotEmpty
          ? ref.requestId.trim()
          : (matched?.requestId.trim() ?? ''),
      storageChapterId: _resolveStorageChapterId(ref, matched),
      logicalKey: ref.logicalKey.trim(),
      title: ref.title.trim().isNotEmpty
          ? ref.title.trim()
          : (matched?.title ?? ''),
      order: ref.order > 0 ? ref.order : (matched?.order ?? 0),
      extern: {...matchedExtern, ...Map<String, dynamic>.from(ref.extern)},
    );
  }).toList();
}

String _resolveStorageChapterId(
  DownloadChapterTaskRef ref,
  UnifiedComicDownloadChapter? matched,
) {
  final explicitStorageChapterId = ref.storageChapterId.trim();
  if (explicitStorageChapterId.isNotEmpty) {
    return explicitStorageChapterId;
  }

  final matchedStorageChapterId = matched?.storageChapterId.trim() ?? '';
  if (matchedStorageChapterId.isNotEmpty) {
    return matchedStorageChapterId;
  }

  final refChapterId = ref.chapterId.trim();
  if (refChapterId.isNotEmpty) {
    return refChapterId;
  }

  return matched?.id.trim() ?? '';
}

Future<UnifiedPluginChapterResponse> _getChapterByPlugin({
  required String from,
  required String pluginId,
  required String comicId,
  required String chapterId,
  required String runtimeName,
  required Map<String, dynamic> extern,
}) async {
  return getComicChapterByPlugin(
    comicId,
    chapterId,
    from,
    pluginId: pluginId,
    runtimeName: runtimeName,
    extern: extern,
  );
}

Future<void> _saveUnifiedDownload({
  required String from,
  required DownloadTaskJson task,
  required normal.NormalComicAllInfo normalInfo,
  required List<_ResolvedDownloadChapter> selectedChapters,
  required List<UnifiedPluginChapterResponse> chapterResponses,
}) async {
  final now = DateTime.now().toUtc();
  final storedChapters = <UnifiedComicDownloadStoredChapter>[];
  for (var index = 0; index < chapterResponses.length; index++) {
    final response = chapterResponses[index];
    final selectedChapter = selectedChapters[index];

    storedChapters.add(
      UnifiedComicDownloadStoredChapter(
        id: selectedChapter.storageChapterId.trim().isNotEmpty
            ? selectedChapter.storageChapterId
            : response.chapter.epId,
        name: selectedChapter.title.trim().isNotEmpty
            ? selectedChapter.title
            : response.chapter.epName,
        order: selectedChapter.order,
        logicalKey: selectedChapter.logicalKey,
        taskChapterId: _resolveChapterRequestId(selectedChapter),
        images: response.chapter.docs.map((doc) {
          final imageName = _resolveImageDisplayName(doc);
          final imagePath = normalizeStoredAssetPath(doc.path);
          return UnifiedComicDownloadImage(
            id: doc.id.isNotEmpty
                ? doc.id
                : _fallbackImageId(doc, response.chapter.epId),
            name: imageName,
            path: imagePath,
            url: doc.url,
            extern: doc.extern,
          );
        }).toList(),
      ),
    );
  }

  final eps = storedChapters
      .map(
        (chapter) => normal.Ep(
          id: chapter.id,
          name: chapter.name,
          order: chapter.order,
          requestId: chapter.taskChapterId,
          storageChapterId: chapter.id,
          logicalKey: chapter.logicalKey,
        ),
      )
      .toList();

  final detail = normalInfo.copyWith(
    eps: eps,
    recommend: const [],
    extern: {
      ...normalInfo.extern,
      'downloadChapters': storedChapters.map((e) => e.toMap()).toList(),
    },
  );
  final key = '$from:${task.comicId}';
  final coverMap = _normalizeStoredImageMap(
    _deepCopyMap(detail.comicInfo.cover.toJson()),
  );
  final creatorMap = _normalizeStoredCreatorMap(
    _deepCopyMap(detail.comicInfo.creator.toJson()),
  );
  final titleMeta = _deepCopyMapList(
    detail.comicInfo.titleMeta.map((e) => e.toJson()).toList(),
  );
  final metadata = _normalizeMetadataForStorage(detail.comicInfo.metadata);
  final chapters = storedChapters.map((chapter) => chapter.toMap()).toList();

  final entity = UnifiedComicDownload(
    uniqueKey: key,
    source: from,
    comicId: task.comicId,
    title: detail.comicInfo.title,
    description: detail.comicInfo.description,
    cover: jsonEncode(coverMap),
    creator: jsonEncode(creatorMap),
    titleMeta: jsonEncode(titleMeta),
    metadata: metadata,
    totalViews: detail.totalViews,
    totalLikes: detail.totalLikes,
    totalComments: detail.totalComments,
    isFavourite: detail.isFavourite,
    isLiked: detail.isLiked,
    allowComment: detail.allowComments,
    allowLike: detail.allowLike,
    allowFavorite: detail.allowCollected,
    allowDownload: detail.allowDownload,
    chapters: jsonEncode(chapters),
    detailJson: jsonEncode(
      detail
          .copyWith(extern: {...detail.extern, 'version': mainVersion})
          .toJson(),
    ),
    storageRoot:
        '${await getDownloadPath()}${Platform.pathSeparator}$from${Platform.pathSeparator}original${Platform.pathSeparator}${task.comicId}',
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

Map<String, dynamic> _deepCopyMap(Object value) {
  final encoded = jsonEncode(value);
  final decoded = jsonDecode(encoded);
  return Map<String, dynamic>.from(decoded as Map);
}

List<Map<String, dynamic>> _deepCopyMapList(Object value) {
  final encoded = jsonEncode(value);
  final decoded = jsonDecode(encoded) as List;
  return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
}

String _normalizeMetadataForStorage(List<normal.ComicInfoMetadata> metadata) {
  final normalized = <Map<String, dynamic>>[];
  for (final item in metadata) {
    final values = item.value
        .map((entry) => entry.name.trim())
        .where((entry) => entry.isNotEmpty)
        .map((entry) => {'name': entry})
        .toList();
    if (values.isEmpty) {
      continue;
    }
    normalized.add({'type': item.type, 'name': item.name, 'value': values});
  }
  return jsonEncode(normalized);
}

String _fallbackImageId(UnifiedPluginChapterDoc doc, String chapterId) {
  final candidate = doc.path.isNotEmpty ? doc.path : doc.name;
  final base = candidate.split(RegExp(r'[\\/]')).last.trim();
  final withoutExt = base.contains('.')
      ? base.substring(0, base.lastIndexOf('.'))
      : base;
  if (withoutExt.isNotEmpty) {
    return withoutExt.replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '_');
  }
  return '${chapterId}_${doc.id.hashCode.abs()}';
}

String _resolveImageDisplayName(UnifiedPluginChapterDoc doc) {
  if (doc.name.trim().isNotEmpty) {
    return doc.name.trim();
  }
  final pathName = p.basename(doc.path.trim());
  if (pathName.isNotEmpty) {
    return pathName;
  }
  return 'asset.bin';
}

Map<String, dynamic> _normalizeStoredImageMap(Map<String, dynamic> image) {
  final map = Map<String, dynamic>.from(image);
  final ext = Map<String, dynamic>.from(map['extern'] as Map? ?? const {});
  final topLevelRawPath = map['path']?.toString() ?? '';
  final extRawPath = ext['path']?.toString() ?? '';

  final normalizedTopLevelPath = normalizeStoredAssetPath(
    topLevelRawPath,
    allowEmpty: true,
  );
  final normalizedExtPath = normalizeStoredAssetPath(
    extRawPath,
    allowEmpty: true,
  );
  final mergedPath = normalizedTopLevelPath.isNotEmpty
      ? normalizedTopLevelPath
      : normalizedExtPath;

  map['path'] = mergedPath;
  ext['path'] = mergedPath;
  map['extern'] = ext;
  return map;
}

Map<String, dynamic> _normalizeStoredCreatorMap(Map<String, dynamic> creator) {
  final map = Map<String, dynamic>.from(creator);
  final avatar = Map<String, dynamic>.from(map['avatar'] as Map? ?? const {});
  if (avatar.isNotEmpty) {
    map['avatar'] = _normalizeStoredImageMap(avatar);
  }
  return map;
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

UnifiedComicDownloadChapter? _findMatchingChapter(
  List<UnifiedComicDownloadChapter> chapters,
  DownloadChapterTaskRef ref,
) {
  final logicalKey = ref.logicalKey.trim();
  if (logicalKey.isNotEmpty) {
    for (final chapter in chapters) {
      if (_resolveSelectionKey(chapter) == logicalKey) {
        return chapter;
      }
    }
  }

  final requestId = ref.requestId.trim();
  if (requestId.isNotEmpty) {
    for (final chapter in chapters) {
      if (chapter.requestId.trim() == requestId) {
        return chapter;
      }
    }
  }

  final chapterId = ref.chapterId.trim();
  if (chapterId.isNotEmpty) {
    for (final chapter in chapters) {
      if (chapter.id.trim() == chapterId) {
        return chapter;
      }
    }
  }

  if (ref.order > 0) {
    for (final chapter in chapters) {
      if (chapter.order == ref.order) {
        return chapter;
      }
    }
  }

  return null;
}

Map<String, dynamic> _resolveChapterExtern(_ResolvedDownloadChapter chapter) {
  return Map<String, dynamic>.from(chapter.extern);
}

String _resolveSelectionKey(UnifiedComicDownloadChapter chapter) {
  final logicalKey = chapter.logicalKey.trim();
  if (logicalKey.isNotEmpty) {
    return logicalKey;
  }

  final requestId = chapter.requestId.trim();
  if (requestId.isNotEmpty) {
    return requestId;
  }

  final chapterId = chapter.id.trim();
  if (chapterId.isNotEmpty) {
    return chapterId;
  }

  return chapter.order.toString();
}
