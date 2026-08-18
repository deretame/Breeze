import 'dart:convert';

import 'package:worker_manager/worker_manager.dart';
import 'package:zephyr/database/database.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/worker_isolate.dart';

Future<void> migrateV4ToV5() async {
  final dbRootPath = await getDbPath();
  final rootIsolateToken = captureWorkerIsolateToken();
  await workerManager.execute(() async {
    ensureWorkerIsolateInitialized(rootIsolateToken);
    final databaseTemp = await createDatabase(dbRootPath: dbRootPath);
    _migrateFavorites(databaseTemp);
    _migrateHistories(databaseTemp);
    _migrateDownloads(databaseTemp);
  });
  logger.d('[migration_v4_to_v5] done');
}

void _migrateFavorites(AppDatabase database) {
  final all = database.unifiedFavorites.getAll();
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
    database.unifiedFavorites.put(item);
    changed++;
  }
  logger.d('[migration_v4_to_v5] updated UnifiedComicFavorite: $changed');
}

void _migrateHistories(AppDatabase database) {
  final all = database.unifiedHistories.getAll();
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
    database.unifiedHistories.put(item);
    changed++;
  }
  logger.d('[migration_v4_to_v5] updated UnifiedComicHistory: $changed');
}

void _migrateDownloads(AppDatabase database) {
  final all = database.unifiedDownloads.getAll();
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
    database.unifiedDownloads.put(item);
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
