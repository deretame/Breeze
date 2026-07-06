import 'dart:convert';

import 'package:worker_manager/worker_manager.dart';
import 'package:zephyr/main.dart' hide objectbox;
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/worker_isolate.dart';

Future<void> migrateV4ToV5() async {
  final dbRootPath = await getDbPath();
  final rootIsolateToken = captureWorkerIsolateToken();
  await workerManager.execute(() async {
    ensureWorkerIsolateInitialized(rootIsolateToken);
    final objectboxTemp = await ObjectBox.create(dbRootPath: dbRootPath);
    _migrateFavorites(objectboxTemp);
    _migrateHistories(objectboxTemp);
    _migrateDownloads(objectboxTemp);
  });
  logger.d('[migration_v4_to_v5] done');
}

void _migrateFavorites(ObjectBox objectbox) {
  final all = objectbox.unifiedFavoriteBox.getAll();
  var changed = 0;
  for (final item in all) {
    final newCover = _renameExtensionToExternInJsonString(item.cover);
    final newCreator = _renameExtensionToExternInJsonString(item.creator);
    final newTitleMeta = _renameExtensionToExternInJsonString(item.titleMeta);
    final newMetadata = _renameExtensionToExternInJsonString(item.metadata);
    if (newCover == null &&
        newCreator == null &&
        newTitleMeta == null &&
        newMetadata == null) {
      continue;
    }
    if (newCover != null) item.cover = newCover;
    if (newCreator != null) item.creator = newCreator;
    if (newTitleMeta != null) item.titleMeta = newTitleMeta;
    if (newMetadata != null) item.metadata = newMetadata;
    objectbox.unifiedFavoriteBox.put(item);
    changed++;
  }
  logger.d('[migration_v4_to_v5] updated UnifiedComicFavorite: $changed');
}

void _migrateHistories(ObjectBox objectbox) {
  final all = objectbox.unifiedHistoryBox.getAll();
  var changed = 0;
  for (final item in all) {
    final newCover = _renameExtensionToExternInJsonString(item.cover);
    final newCreator = _renameExtensionToExternInJsonString(item.creator);
    final newTitleMeta = _renameExtensionToExternInJsonString(item.titleMeta);
    final newMetadata = _renameExtensionToExternInJsonString(item.metadata);
    if (newCover == null &&
        newCreator == null &&
        newTitleMeta == null &&
        newMetadata == null) {
      continue;
    }
    if (newCover != null) item.cover = newCover;
    if (newCreator != null) item.creator = newCreator;
    if (newTitleMeta != null) item.titleMeta = newTitleMeta;
    if (newMetadata != null) item.metadata = newMetadata;
    objectbox.unifiedHistoryBox.put(item);
    changed++;
  }
  logger.d('[migration_v4_to_v5] updated UnifiedComicHistory: $changed');
}

void _migrateDownloads(ObjectBox objectbox) {
  final all = objectbox.unifiedDownloadBox.getAll();
  var changed = 0;
  for (final item in all) {
    final newCover = _renameExtensionToExternInJsonString(item.cover);
    final newCreator = _renameExtensionToExternInJsonString(item.creator);
    final newTitleMeta = _renameExtensionToExternInJsonString(item.titleMeta);
    final newMetadata = _renameExtensionToExternInJsonString(item.metadata);
    final newChapters = _renameExtensionToExternInJsonString(item.chapters);
    final newDetailJson = _renameExtensionToExternInJsonString(item.detailJson);
    if (newCover == null &&
        newCreator == null &&
        newTitleMeta == null &&
        newMetadata == null &&
        newChapters == null &&
        newDetailJson == null) {
      continue;
    }
    if (newCover != null) item.cover = newCover;
    if (newCreator != null) item.creator = newCreator;
    if (newTitleMeta != null) item.titleMeta = newTitleMeta;
    if (newMetadata != null) item.metadata = newMetadata;
    if (newChapters != null) item.chapters = newChapters;
    if (newDetailJson != null) item.detailJson = newDetailJson;
    objectbox.unifiedDownloadBox.put(item);
    changed++;
  }
  logger.d('[migration_v4_to_v5] updated UnifiedComicDownload: $changed');
}

String? _renameExtensionToExternInJsonString(String jsonStr) {
  if (!jsonStr.contains('extension')) return null;
  final decoded = jsonDecode(jsonStr);
  final renamed = _renameExtensionToExtern(decoded);
  return jsonEncode(renamed);
}

dynamic _renameExtensionToExtern(dynamic value) {
  if (value is Map<String, dynamic>) {
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      result[entry.key == 'extension' ? 'extern' : entry.key] =
          _renameExtensionToExtern(entry.value);
    }
    return result;
  }
  if (value is List) {
    return value.map(_renameExtensionToExtern).toList();
  }
  return value;
}
