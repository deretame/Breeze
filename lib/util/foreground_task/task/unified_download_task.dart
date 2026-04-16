import 'dart:io';

import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/util/download/download_cancel_signal.dart';
import 'package:zephyr/util/download/download_progress_reporter.dart';
import 'package:zephyr/network/http/plugin/qjs_download_runtime.dart';
import 'package:zephyr/util/foreground_task/data/download_task_json.dart';
import 'package:zephyr/util/foreground_task/task/shared_download.dart';
import 'package:zephyr/util/get_path.dart';

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
    final selectedChapters = _resolveSelectedChapters(
      downloadInfo,
      task.selectedChapters,
    );

    updateTaskStatus('下载封面中...');
    reporter.updateMessage('下载封面中...');
    final cover = detail.normalInfo.comicInfo.cover;
    final coverExtension = Map<String, dynamic>.from(cover.extension);
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
        ...normalInfo.comicInfo.cover.extension,
        'path': '',
      };
      normalInfo = normalInfo.copyWith(
        comicInfo: normalInfo.comicInfo.copyWith(
          cover: normalInfo.comicInfo.cover.copyWith(
            url: '',
            path: '',
            extension: clearedCoverExtension,
          ),
        ),
      );
    }

    updateTaskStatus('获取章节信息中...');
    reporter.updateMessage('获取章节信息中...');
    final chapterResponses = <UnifiedPluginChapterResponse>[];
    for (final chapter in selectedChapters) {
      await ensureTaskRunning();
      final requestChapterId = _resolveChapterRequestId(chapter);
      logger.d(
        'download getChapter plugin=$pluginId comicId=${task.comicId} chapter.id=${chapter.id} order=${chapter.order} requestChapterId=$requestChapterId',
      );
      chapterResponses.add(
        await _getChapterByPlugin(
          from: from,
          pluginId: pluginId,
          comicId: task.comicId,
          chapterId: requestChapterId,
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
            path: doc.path,
            cartoonId: task.comicId,
            chapterId: response.chapter.epId,
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
      onError: (error, job) async {
        throw error;
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

String _resolveChapterRequestId(UnifiedComicDownloadChapter chapter) {
  final rawId = chapter.id.trim();
  if (rawId.isNotEmpty && int.tryParse(rawId) != null) {
    return rawId;
  }
  final order = chapter.order <= 0 ? 1 : chapter.order;
  return order.toString();
}

List<UnifiedComicDownloadChapter> _resolveSelectedChapters(
  UnifiedComicDownloadInfo info,
  List<String> selectedIds,
) {
  final matched = info.chapters
      .where((chapter) => selectedIds.contains(chapter.id))
      .toList();
  return matched.isEmpty ? info.chapters : matched;
}

Future<UnifiedPluginChapterResponse> _getChapterByPlugin({
  required String from,
  required String pluginId,
  required String comicId,
  required String chapterId,
  required String runtimeName,
}) async {
  return getComicChapterByPlugin(
    comicId,
    chapterId,
    from,
    pluginId: pluginId,
    runtimeName: runtimeName,
  );
}

Future<void> _saveUnifiedDownload({
  required String from,
  required DownloadTaskJson task,
  required normal.NormalComicAllInfo normalInfo,
  required List<UnifiedComicDownloadChapter> selectedChapters,
  required List<UnifiedPluginChapterResponse> chapterResponses,
}) async {
  final now = DateTime.now().toUtc();
  final storedChapters = chapterResponses
      .map(
        (response) => UnifiedComicDownloadStoredChapter(
          id: response.chapter.epId,
          name: response.chapter.epName,
          order: selectedChapters
              .firstWhere(
                (e) => e.id == response.chapter.epId,
                orElse: () => selectedChapters.first,
              )
              .order,
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
            );
          }).toList(),
        ),
      )
      .toList();
  final eps = storedChapters
      .map(
        (chapter) =>
            normal.Ep(id: chapter.id, name: chapter.name, order: chapter.order),
      )
      .toList();

  final detail = normalInfo.copyWith(
    eps: eps,
    recommend: const [],
    extension: {
      ...normalInfo.extension,
      'downloadChapters': storedChapters
          .map(
            (e) => {
              'id': e.id,
              'name': e.name,
              'order': e.order,
              'images': e.images.map((image) => image.toMap()).toList(),
            },
          )
          .toList(),
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
  final chapters = storedChapters
      .map(
        (chapter) => UnifiedComicDownloadChapter(
          id: chapter.id,
          title: chapter.name,
          order: chapter.order,
        ).toMap(),
      )
      .toList();

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
          .copyWith(extension: {...detail.extension, 'version': mainVersion})
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
  final ext = Map<String, dynamic>.from(map['extension'] as Map? ?? const {});
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
  map['extension'] = ext;
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
