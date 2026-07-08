import 'dart:convert';

import 'package:zephyr/main.dart';

/// v6 -> v7: 把 JSON 字段中残留的 `extension` 统一重命名为 `extern`。
///
/// 旧版本把扩展字段命名为 `extension`，新版本统一为 `extern`。v4->v5 的迁移
/// 虽然做过一次替换，但它只递归处理了 Map/List，没有解析嵌套在 JSON 字符串
/// 里的 `extension`。这导致 `detailJson` 中像 `comicInfo.cover`、`creator.avatar`、
/// `titleMeta`、`metadata` 等以字符串形式存储的 JSON 内部仍然使用旧字段名。
///
/// 本次迁移会深度遍历 JSON 结构，包括嵌套的 JSON 字符串，确保所有 `extension`
/// 都被正确替换为 `extern`。
Future<void> migrateV6ToV7() async {
  var favoriteChanged = 0;
  var historyChanged = 0;
  var downloadChanged = 0;

  final favorites = objectbox.unifiedFavoriteBox.getAll();
  for (final item in favorites) {
    final newCover = _renameExtensionToExternDeep(item.cover);
    final newCreator = _renameExtensionToExternDeep(item.creator);
    final newTitleMeta = _renameExtensionToExternDeep(item.titleMeta);
    final newMetadata = _renameExtensionToExternDeep(item.metadata);
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
    favoriteChanged++;
  }

  final histories = objectbox.unifiedHistoryBox.getAll();
  for (final item in histories) {
    final newCover = _renameExtensionToExternDeep(item.cover);
    final newCreator = _renameExtensionToExternDeep(item.creator);
    final newTitleMeta = _renameExtensionToExternDeep(item.titleMeta);
    final newMetadata = _renameExtensionToExternDeep(item.metadata);
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
    historyChanged++;
  }

  final downloads = objectbox.unifiedDownloadBox.getAll();
  for (final item in downloads) {
    final newCover = _renameExtensionToExternDeep(item.cover);
    final newCreator = _renameExtensionToExternDeep(item.creator);
    final newTitleMeta = _renameExtensionToExternDeep(item.titleMeta);
    final newMetadata = _renameExtensionToExternDeep(item.metadata);
    final newChapters = _renameExtensionToExternDeep(item.chapters);
    final newDetailJson = _renameExtensionToExternDeep(item.detailJson);
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
    downloadChanged++;
  }

  logger.d(
    '[migration_v6_to_v7] '
    'favorite=$favoriteChanged, history=$historyChanged, download=$downloadChanged',
  );
}

/// 深度替换 JSON 字符串中的 `extension` 为 `extern`。
///
/// 会递归解析嵌套的 JSON 字符串（例如 `detailJson` 中 `cover`、`creator` 等
/// 字段本身又是 JSON 字符串）。如果字符串不是 JSON 或没有需要替换的内容，
/// 返回 null。
String? _renameExtensionToExternDeep(String jsonStr) {
  if (!jsonStr.contains('"extension"')) return null;
  try {
    final decoded = jsonDecode(jsonStr);
    final result = _renameExtensionToExtern(decoded);
    if (!result.changed) return null;
    return jsonEncode(result.value);
  } catch (_) {
    return null;
  }
}

class _RenameResult {
  _RenameResult(this.value, this.changed);

  final dynamic value;
  final bool changed;
}

_RenameResult _renameExtensionToExtern(dynamic value) {
  if (value is Map<String, dynamic>) {
    var changed = false;
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      final newKey = entry.key == 'extension' ? 'extern' : entry.key;
      if (entry.key == 'extension') changed = true;
      final renamedValue = _renameExtensionToExtern(entry.value);
      if (renamedValue.changed) changed = true;
      result[newKey] = renamedValue.value;
    }
    return _RenameResult(result, changed);
  }
  if (value is List) {
    var changed = false;
    final result = <dynamic>[];
    for (final item in value) {
      final renamedItem = _renameExtensionToExtern(item);
      if (renamedItem.changed) changed = true;
      result.add(renamedItem.value);
    }
    return _RenameResult(result, changed);
  }
  if (value is String) {
    // 尝试解析嵌套 JSON 字符串。
    if (value.contains('"extension"')) {
      try {
        final decoded = jsonDecode(value);
        final renamed = _renameExtensionToExtern(decoded);
        if (renamed.changed) {
          return _RenameResult(jsonEncode(renamed.value), true);
        }
      } catch (_) {}
    }
    return _RenameResult(value, false);
  }
  return _RenameResult(value, false);
}
