import 'dart:async';
import 'dart:convert';
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
import 'package:zephyr/page/download/adapters/download_chapter_adapter.dart';
import 'package:zephyr/page/download/adapters/download_chapter_matcher.dart';
import 'package:zephyr/page/download/models/download_chapter.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/service/download/download_cancel_signal.dart';
import 'package:zephyr/service/download/download_progress_reporter.dart';
import 'package:zephyr/service/download/download_retry.dart';
import 'package:zephyr/service/download/download_task_progress.dart';
import 'package:zephyr/service/download/download_task_repository.dart';
import 'package:zephyr/service/download/models/download_task_json.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/service/download/image_download.dart';
import 'package:zephyr/network/sync/sync_device_id.dart';
import 'package:zephyr/page/bookshelf/service/comic_link_service.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/util/get_path.dart';

Future<void> unifiedDownloadTask(
  DownloadProgressReporter reporter,
  DownloadTaskJson task,
) async {
  await ensureSyncDeviceId();
  logger.d('unifiedDownloadTask received payload=${task.toJson()}');
  final pluginId = (task.from).trim();
  final from = pluginId;
  final runtimeName = runtimeNameForPluginId(pluginId);
  final taskKey = task.taskKey;
  const taskRepository = DownloadTaskRepository();
  bool shouldRetryUntilSuccess() {
    return objectbox.userSettingBox
            .get(1)
            ?.globalSetting
            .retryDownloadUntilSuccess ??
        false;
  }

  Timer? progressTimer;
  bool running = true;

  DownloadTask? findCurrentTask() {
    final current = taskRepository.findByTaskKey(taskKey);
    if (current == null || !current.isDownloading) return null;
    return current;
  }

  DownloadTaskJson currentPayload() {
    final current = taskRepository.findByTaskKey(taskKey);
    return taskRepository.readPayload(current ?? DownloadTask()) ?? task;
  }

  void updateTaskStatus(String status) {
    final dbTask = findCurrentTask();
    if (dbTask != null) {
      dbTask.status = status;
      objectbox.downloadTaskBox.put(dbTask);
    }
  }

  void updateCheckpoint(
    DownloadTaskJson Function(DownloadTaskJson payload) update, {
    String? status,
  }) {
    final dbTask = taskRepository.findByTaskKey(taskKey);
    if (dbTask == null) return;
    final payload = taskRepository.readPayload(dbTask) ?? task;
    taskRepository.putPayload(dbTask, update(payload), status: status);
  }

  Future<void> ensureTaskRunning() async {
    final currentTask = findCurrentTask();
    final signaled = isDownloadCancelSignaled(taskKey);
    if (signaled || currentTask == null || !currentTask.isDownloading) {
      logger.w(
        'ensureTaskRunning 取消任务: taskKey=$taskKey, signaled=$signaled, currentTask=${currentTask != null}, isDownloading=${currentTask?.isDownloading}',
      );
      await cancelTrackedQjsTasks(pluginId: pluginId, taskGroupKey: taskKey);
      throw const DownloadTaskCancelledException();
    }
  }

  try {
    await ensureQjsRuntimeReady(pluginId: pluginId);
    await ensureTaskRunning();
    updateCheckpoint(
      (payload) =>
          payload.copyWith(stateCode: 'running', phaseCode: 'preparingRuntime'),
    );
    await preparePluginDownloadRuntime(
      from: from,
      pluginId: pluginId,
      runtimeName: runtimeName,
      taskGroupKey: taskKey,
    );

    updateCheckpoint(
      (payload) => payload.copyWith(
        phaseCode: 'fetchingComicInfo',
        lastErrorCode: '',
        lastErrorMessage: '',
      ),
      status: t.download.statusFetchingComicInfo,
    );
    updateTaskStatus(t.download.statusFetchingComicInfo);
    reporter.updateMessage(t.download.statusFetchingComicInfo);
    final detail = await getComicDetailByPlugin(
      task.comicId,
      from,
      pluginId: pluginId,
    );

    final downloadInfo = UnifiedComicDownloadInfo.fromString(detail.source);
    final selectedChapters = _resolveSelectedChapters(
      downloadInfo,
      currentPayload(),
    );
    updateCheckpoint(
      (payload) => payload.copyWith(
        totalChapterCount: selectedChapters.length,
        phaseCode: 'fetchingChapterInfo',
      ),
    );

    updateTaskStatus(t.download.statusDownloadingCover);
    updateCheckpoint(
      (payload) => payload.copyWith(phaseCode: 'downloadingCover'),
      status: t.download.statusDownloadingCover,
    );
    reporter.updateMessage(t.download.statusDownloadingCover);
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
        qjsTaskGroupKey: taskKey,
        shouldRetryUntilSuccess: shouldRetryUntilSuccess,
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

    progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (running) {
        updateTaskStatus(reporter.message);
      }
    });

    final completedChapterKeys = _restoreCompletedChapterKeys(
      from: from,
      comicId: task.comicId,
      selectedChapters: selectedChapters,
      checkpointKeys: currentPayload().completedChapterKeys,
    );
    final checkpointPayload = currentPayload();
    final checkpointKeys = checkpointPayload.completedChapterKeys.toSet();
    final checkpointChanged =
        completedChapterKeys.length != checkpointKeys.length ||
        !completedChapterKeys.containsAll(checkpointKeys);
    if (checkpointChanged) {
      updateCheckpoint(
        (payload) => payload.copyWith(
          completedChapterKeys: completedChapterKeys.toList(),
          completedChapterCount: completedChapterKeys.length,
          currentChapterKey: '',
          currentChapterCompletedImages: 0,
          currentChapterReusedImages: 0,
          currentChapterFailedImages: 0,
          currentChapterTotalImages: 0,
        ),
      );
      logger.i(
        '恢复下载 checkpoint: taskKey=$taskKey, '
        '已完成章节=${completedChapterKeys.length}/${selectedChapters.length}',
      );
    }

    void reportChapterProgress({
      required int completedChapters,
      required int currentChapterCompletedImages,
      required int currentChapterTotalImages,
    }) {
      final message = downloadTaskProgressMessage(
        completedChapters: completedChapters,
        totalChapters: selectedChapters.length,
        currentChapterCompletedImages: currentChapterCompletedImages,
        currentChapterTotalImages: currentChapterTotalImages,
      );
      if (message.isEmpty) return;
      updateTaskStatus(message);
      reporter.updateMessage(message);
    }

    reportChapterProgress(
      completedChapters: completedChapterKeys.length,
      currentChapterCompletedImages: 0,
      currentChapterTotalImages: 0,
    );

    final firstIncompleteIndex = selectedChapters.indexWhere(
      (chapter) =>
          !completedChapterKeys.contains(_chapterCheckpointKey(chapter)),
    );
    if (firstIncompleteIndex >= 0) {
      logger.i(
        '开始恢复未完成章节: taskKey=$taskKey, '
        '章节位置=${firstIncompleteIndex + 1}/${selectedChapters.length}',
      );
    }

    for (
      var index = firstIncompleteIndex;
      index >= 0 && index < selectedChapters.length;
      index++
    ) {
      final chapter = selectedChapters[index];
      final chapterKey = _chapterCheckpointKey(chapter);
      if (completedChapterKeys.contains(chapterKey)) {
        logger.d('跳过已完成章节: taskKey=$taskKey, chapterKey=$chapterKey');
        continue;
      }

      await ensureTaskRunning();
      final fetchMessage = t.download.statusFetchingChapterInfoProgress(
        completed: downloadTaskDisplayPosition(
          completed: completedChapterKeys.length,
          total: selectedChapters.length,
        ),
        total: selectedChapters.length,
        percent: selectedChapters.isEmpty
            ? 0
            : ((completedChapterKeys.length / selectedChapters.length) * 100)
                  .floor(),
      );
      updateTaskStatus(fetchMessage);
      reporter.updateMessage(fetchMessage);
      updateCheckpoint(
        (payload) => payload.copyWith(
          stateCode: 'running',
          phaseCode: 'fetchingChapterInfo',
          currentChapterKey: chapterKey,
          currentChapterCompletedImages: 0,
          currentChapterReusedImages: 0,
          currentChapterFailedImages: 0,
          currentChapterTotalImages: 0,
        ),
      );

      final requestChapterId = _resolveChapterRequestId(chapter);
      final chapterExtern = _resolveChapterExtern(chapter);
      logger.d(
        'download getChapter plugin=$pluginId comicId=${task.comicId} chapter.id=${chapter.id} order=${chapter.order} requestChapterId=$requestChapterId storageChapterId=${chapter.effectiveStorageId} extern=$chapterExtern',
      );
      final response =
          await retryDownloadOperation<UnifiedPluginChapterResponse>(
            operation: '获取章节 ${chapter.displayName}',
            ensureTaskRunning: ensureTaskRunning,
            shouldRetryUntilSuccess: shouldRetryUntilSuccess,
            action: () => _getChapterByPlugin(
              from: from,
              pluginId: pluginId,
              comicId: task.comicId,
              chapterId: requestChapterId,
              runtimeName: runtimeName,
              extern: {...chapterExtern, 'chapterId': requestChapterId},
            ),
          );
      final jobs = <DownloadImageJob>[];
      for (final doc in response.chapter.docs) {
        jobs.add(
          DownloadImageJob(
            url: doc.url,
            path: doc.path,
            cartoonId: task.comicId,
            chapterId: response.chapter.epId,
            storageChapterId: chapter.effectiveStorageId,
            extern: doc.extern,
          ),
        );
      }

      updateCheckpoint(
        (payload) => payload.copyWith(
          phaseCode: 'downloadingChapter',
          currentChapterTotalImages: jobs.length,
        ),
      );
      reportChapterProgress(
        completedChapters: completedChapterKeys.length,
        currentChapterCompletedImages: 0,
        currentChapterTotalImages: jobs.length,
      );

      var lastPersistedImages = 0;
      var lastPersistedAt = DateTime.now();
      var lastReportedChapterPercent = -1;
      await downloadImageJobs(
        from: from,
        jobs: jobs,
        qjsRuntimeName: runtimeName,
        qjsTaskGroupKey: taskKey,
        ensureTaskRunning: ensureTaskRunning,
        shouldRetryUntilSuccess: shouldRetryUntilSuccess,
        reporter: reporter,
        concurrency: 5,
        onProgress: (completed, downloaded, reused) async {
          final now = DateTime.now();
          final currentPercent = jobs.isEmpty
              ? 100
              : (completed / jobs.length * 100).floor();
          if (currentPercent > lastReportedChapterPercent ||
              completed == jobs.length) {
            lastReportedChapterPercent = currentPercent;
            reportChapterProgress(
              completedChapters: completedChapterKeys.length,
              currentChapterCompletedImages: completed,
              currentChapterTotalImages: jobs.length,
            );
          }

          final shouldPersist =
              completed == jobs.length ||
              completed - lastPersistedImages >= 5 ||
              now.difference(lastPersistedAt) >= const Duration(seconds: 1);
          if (!shouldPersist) return;
          lastPersistedImages = completed;
          lastPersistedAt = now;
          updateCheckpoint(
            (payload) => payload.copyWith(
              currentChapterCompletedImages: completed,
              currentChapterReusedImages: reused,
              currentChapterFailedImages: 0,
              currentChapterTotalImages: jobs.length,
            ),
          );
        },
      );

      updateCheckpoint(
        (payload) => payload.copyWith(phaseCode: 'committingChapter'),
      );
      await _saveUnifiedDownloadChapter(
        from: from,
        task: task,
        normalInfo: normalInfo,
        selectedChapter: chapter,
        chapterResponse: response,
      );
      completedChapterKeys.add(chapterKey);
      updateCheckpoint(
        (payload) => payload.copyWith(
          stateCode: 'running',
          phaseCode: 'chapterCommitted',
          completedChapterKeys: completedChapterKeys.toList(),
          currentChapterKey: '',
          completedChapterCount: completedChapterKeys.length,
          currentChapterCompletedImages: 0,
          currentChapterReusedImages: 0,
          currentChapterFailedImages: 0,
          currentChapterTotalImages: 0,
        ),
      );
      reportChapterProgress(
        completedChapters: completedChapterKeys.length,
        currentChapterCompletedImages: 0,
        currentChapterTotalImages: 0,
      );
    }

    updateCheckpoint(
      (payload) => payload.copyWith(
        stateCode: 'completed',
        phaseCode: 'completed',
        completedChapterKeys: completedChapterKeys.toList(),
        completedChapterCount: selectedChapters.length,
        currentChapterKey: '',
      ),
    );
    _markTaskCompleted(taskKey);
  } finally {
    running = false;
    progressTimer?.cancel();
  }
}

String _chapterCheckpointKey(DownloadChapter chapter) {
  final id = chapter.id.trim();
  if (id.isNotEmpty) return id;
  return chapter.effectiveRequestId.trim();
}

Set<String> _restoreCompletedChapterKeys({
  required String from,
  required String comicId,
  required List<DownloadChapter> selectedChapters,
  required List<String> checkpointKeys,
}) {
  final completedKeys = <String>{...checkpointKeys};
  final query = objectbox.unifiedDownloadBox
      .query(
        UnifiedComicDownload_.uniqueKey.equals(
          buildDownloadTaskKey(from, comicId),
        ),
      )
      .build();

  UnifiedComicDownload? existing;
  try {
    existing = query.findFirst();
  } finally {
    query.close();
  }
  if (existing == null) return completedKeys;

  final storedChapters = resolveStoredDownloadChapters(existing);
  for (final selectedChapter in selectedChapters) {
    if (storedChapters.any(
      (storedChapter) => _storedChapterMatches(storedChapter, selectedChapter),
    )) {
      completedKeys.add(_chapterCheckpointKey(selectedChapter));
    }
  }
  return completedKeys;
}

String _resolveChapterRequestId(DownloadChapter chapter) {
  return chapter.effectiveRequestId;
}

List<DownloadChapter> _resolveSelectedChapters(
  UnifiedComicDownloadInfo info,
  DownloadTaskJson task,
) {
  if (task.chapterRefs.isEmpty) {
    throw StateError('DownloadTaskJson.chapterRefs 不能为空');
  }

  const adapter = DownloadChapterAdapter();
  const matcher = DownloadChapterMatcher();

  return task.chapterRefs.map((ref) {
    final refChapter = adapter.fromTaskRef(ref);
    final matched = _findMatchingChapter(info.chapters, refChapter, matcher);
    final matchedExtern = matched != null
        ? Map<String, dynamic>.from(matched.extern)
        : const <String, dynamic>{};

    final displayName = ref.title.trim().isNotEmpty
        ? ref.title.trim()
        : (matched?.displayName ?? '');
    final order = ref.order > 0 ? ref.order : (matched?.order ?? 0);

    return refChapter.copyWith(
      displayName: displayName,
      order: order,
      extern: {...matchedExtern, ...Map<String, dynamic>.from(ref.extern)},
    );
  }).toList();
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

Future<void> _saveUnifiedDownloadChapter({
  required String from,
  required DownloadTaskJson task,
  required normal.NormalComicAllInfo normalInfo,
  required DownloadChapter selectedChapter,
  required UnifiedPluginChapterResponse chapterResponse,
}) async {
  final now = DateTime.now().toUtc();
  final key = buildDownloadTaskKey(from, task.comicId);
  final existing = objectbox.unifiedDownloadBox
      .query(UnifiedComicDownload_.uniqueKey.equals(key))
      .build()
      .findFirst();
  final storedChapters = existing == null
      ? <UnifiedComicDownloadStoredChapter>[]
      : resolveStoredDownloadChapters(existing).toList();
  final storedChapter = _buildStoredChapter(selectedChapter, chapterResponse);
  final existingIndex = storedChapters.indexWhere(
    (item) => _storedChapterMatches(item, selectedChapter),
  );
  if (existingIndex >= 0) {
    storedChapters[existingIndex] = storedChapter;
  } else {
    storedChapters.add(storedChapter);
  }
  storedChapters.sort((a, b) => a.order.compareTo(b.order));

  final eps = storedChapters
      .map(
        (chapter) => normal.Ep(
          // Ep.id 应该是宿主匹配 key，而不是 storage key。
          id: chapter.logicalKey,
          name: chapter.name,
          order: chapter.order,
          requestId: chapter.taskChapterId,
          storageChapterId: chapter.storageChapterId.isNotEmpty
              ? chapter.storageChapterId
              : chapter.id,
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
  var coverMap = _normalizeStoredImageMap(
    _deepCopyMap(detail.comicInfo.cover.toJson()),
  );
  if (_isEmptyStoredImage(coverMap) && existing != null) {
    try {
      coverMap = _normalizeStoredImageMap(
        Map<String, dynamic>.from(jsonDecode(existing.cover) as Map),
      );
    } catch (_) {
      // 旧记录封面 JSON 损坏时继续使用当前详情的空封面。
    }
  }
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
    storageRoot: p.join(
      await getDownloadPath(),
      from,
      'original',
      encodePath(path: task.comicId),
    ),
    createdAt: existing?.createdAt ?? now,
    updatedAt: now,
    downloadedAt: now,
    deleted: false,
    schemaVersion: 2,
  );

  if (existing != null) {
    entity.id = existing.id;
  }
  objectbox.unifiedDownloadBox.put(entity);

  // 同时建立根目录下载链接，用于新的文件夹书架视图
  ComicLinkService.addComic(key, null, ComicFolderType.download);
}

UnifiedComicDownloadStoredChapter _buildStoredChapter(
  DownloadChapter selectedChapter,
  UnifiedPluginChapterResponse response,
) {
  logger.d(
    '_saveUnifiedDownloadChapter: '
    'chapter.id=${selectedChapter.id}, '
    'requestId=${selectedChapter.effectiveRequestId}, '
    'storageId=${selectedChapter.effectiveStorageId}, '
    'responseEpId=${response.chapter.epId}, '
    'imageCount=${response.chapter.docs.length}',
  );
  return UnifiedComicDownloadStoredChapter(
    // `id` 字段保持为本地存储 key，旧版本读取时仍按 storage key 理解。
    id: selectedChapter.effectiveStorageId,
    name: selectedChapter.displayName.trim().isNotEmpty
        ? selectedChapter.displayName
        : response.chapter.epName,
    order: selectedChapter.order,
    // `logicalKey` 写入宿主匹配 key，保证新版本通过适配器能还原出正确的 id。
    logicalKey: selectedChapter.id,
    taskChapterId: _resolveChapterRequestId(selectedChapter),
    // 显式保存 storageChapterId，确保显式指定了 storage key 的插件能正确还原。
    storageChapterId: selectedChapter.effectiveStorageId,
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
  );
}

bool _storedChapterMatches(
  UnifiedComicDownloadStoredChapter stored,
  DownloadChapter selected,
) {
  final storedKeys = <String>{
    stored.id.trim(),
    stored.logicalKey.trim(),
    stored.taskChapterId.trim(),
    stored.storageChapterId.trim(),
  }..remove('');
  final selectedKeys = <String>{
    selected.id.trim(),
    selected.effectiveRequestId.trim(),
    selected.effectiveStorageId.trim(),
  }..remove('');
  if (storedKeys.intersection(selectedKeys).isNotEmpty) return true;
  return stored.order > 0 &&
      selected.order > 0 &&
      stored.order == selected.order;
}

bool _isEmptyStoredImage(Map<String, dynamic> image) {
  final path = image['path']?.toString().trim() ?? '';
  final extern = Map<String, dynamic>.from(image['extern'] as Map? ?? const {});
  final externPath = extern['path']?.toString().trim() ?? '';
  return path.isEmpty && externPath.isEmpty;
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

void _markTaskCompleted(String taskKey) {
  const repository = DownloadTaskRepository();
  final task = repository.findByTaskKey(taskKey);
  if (task == null) return;
  final payload = repository.readPayload(task);
  task
    ..isCompleted = true
    ..isDownloading = false
    ..status = t.download.notificationCompleteTitle;
  if (payload != null) {
    task.taskInfo = payload.copyWith(
      stateCode: 'completed',
      phaseCode: 'completed',
    );
  }
  objectbox.downloadTaskBox.put(task);
}

DownloadChapter? _findMatchingChapter(
  List<UnifiedComicDownloadChapter> chapters,
  DownloadChapter refChapter,
  DownloadChapterMatcher matcher,
) {
  const adapter = DownloadChapterAdapter();
  for (final chapter in chapters) {
    final candidate = adapter.fromOnlineChapter(chapter);
    if (matcher.matches(candidate, refChapter.id)) {
      return candidate;
    }
  }

  if (refChapter.order > 0) {
    for (final chapter in chapters) {
      if (chapter.order == refChapter.order) {
        return adapter.fromOnlineChapter(chapter);
      }
    }
  }

  return null;
}

Map<String, dynamic> _resolveChapterExtern(DownloadChapter chapter) {
  return Map<String, dynamic>.from(chapter.extern);
}
