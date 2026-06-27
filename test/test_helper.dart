import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/sync/sync_device_id.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/object_box.dart';

/// 测试辅助类：在独立的临时目录创建 ObjectBox，并设置全局 [objectbox]。
///
/// 每个调用方在 `setUpAll` 中调用 [setUpTestObjectBox]，
/// 在 `tearDownAll` 中调用 [tearDownTestObjectBox]，
/// 在 `tearDown` 中调用 [cleanComicFolderBoxes] 清理数据。
class TestObjectBoxHelper {
  static Directory? _tempDir;
  static ObjectBox? _objectBox;

  static Future<void> setUpTestObjectBox() async {
    _tempDir = await Directory.systemTemp.createTemp('breeze_test_');
    ObjectBox.resetForTests();
    _objectBox = await ObjectBox.create(dbRootPath: _tempDir!.path);
    objectbox = _objectBox!;
    syncDeviceId = 'test_device';
  }

  static Future<void> tearDownTestObjectBox() async {
    _objectBox?.close();
    _objectBox = null;
    if (_tempDir != null && await _tempDir!.exists()) {
      await _tempDir!.delete(recursive: true);
    }
    _tempDir = null;
  }

  static void cleanComicFolderBoxes() {
    objectbox.comicFolderBox.removeAll();
    objectbox.comicLinkBox.removeAll();
    objectbox.unifiedFavoriteBox.removeAll();
    objectbox.unifiedHistoryBox.removeAll();
    objectbox.unifiedDownloadBox.removeAll();
  }
}

/// 构造一个测试用的 UnifiedComicFavorite。
UnifiedComicFavorite createTestFavorite(
  String uniqueKey, {
  bool deleted = false,
  DateTime? updatedAt,
}) {
  final now = updatedAt ?? DateTime.now().toUtc();
  return UnifiedComicFavorite(
    uniqueKey: uniqueKey,
    source: 'test',
    comicId: uniqueKey,
    title: 'Test Comic $uniqueKey',
    description: '',
    cover: '',
    creator: '',
    titleMeta: '',
    metadata: '',
    createdAt: now,
    updatedAt: now,
    deleted: deleted,
    schemaVersion: 1,
  );
}

/// 构造一个测试用的 UnifiedComicHistory。
UnifiedComicHistory createTestHistory(
  String uniqueKey, {
  bool deleted = false,
  DateTime? updatedAt,
}) {
  final now = updatedAt ?? DateTime.now().toUtc();
  return UnifiedComicHistory(
    uniqueKey: uniqueKey,
    source: 'test',
    comicId: uniqueKey,
    title: 'Test Comic $uniqueKey',
    description: '',
    cover: '',
    creator: '',
    titleMeta: '',
    metadata: '',
    chapterId: '',
    chapterTitle: '',
    chapterOrder: 0,
    pageIndex: 0,
    createdAt: now,
    lastReadAt: now,
    updatedAt: now,
    deleted: deleted,
    schemaVersion: 1,
  );
}

/// 构造一个测试用的 UnifiedComicDownload。
UnifiedComicDownload createTestDownload(
  String uniqueKey, {
  String storageRoot = '',
  bool deleted = false,
  DateTime? updatedAt,
}) {
  final now = updatedAt ?? DateTime.now().toUtc();
  return UnifiedComicDownload(
    uniqueKey: uniqueKey,
    source: 'test',
    comicId: uniqueKey,
    title: 'Test Comic $uniqueKey',
    description: '',
    cover: '',
    creator: '',
    titleMeta: '',
    metadata: '',
    totalViews: 0,
    totalLikes: 0,
    totalComments: 0,
    isFavourite: false,
    isLiked: false,
    allowComment: false,
    allowLike: false,
    allowFavorite: false,
    allowDownload: false,
    chapters: '',
    detailJson: '',
    storageRoot: storageRoot,
    createdAt: now,
    updatedAt: now,
    downloadedAt: now,
    deleted: deleted,
    schemaVersion: 1,
  );
}
