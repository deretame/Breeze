import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/comic_info/method/export_comic.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/permission.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

/// 批量导出选中的已下载漫画。
///
/// 返回成功导出的数量。导出失败的项目会被跳过，不会中断后续导出。
Future<int> batchExportComics({
  required BuildContext context,
  required List<ComicSimplifyEntryInfo> comics,
}) async {
  if (comics.isEmpty) return 0;

  final exportType = await _pickBatchExportType(context);
  if (exportType == null) return 0;

  final exportRoot = await _resolveBatchExportDirectory();
  if (exportRoot == null || exportRoot.trim().isEmpty) return 0;

  var success = 0;
  for (final comic in comics) {
    final from = comic.from.trim();
    if (from.isEmpty) continue;

    String? exportPath;
    if (exportType == ExportType.folder) {
      exportPath = exportRoot;
    } else {
      final safeTitle = _sanitizeFileName(
        comic.title.trim().isEmpty ? comic.id : comic.title,
      );
      exportPath = p.join(exportRoot, '$safeTitle.zip');
    }

    try {
      await exportComic(comic.id, exportType, from, path: exportPath);
      success++;
    } catch (_) {
      // 继续导出下一本，避免单本失败导致整批中断。
    }
  }

  return success;
}

Future<ExportType?> _pickBatchExportType(BuildContext context) async {
  if (Platform.isIOS) return ExportType.zip;
  return showDialog<ExportType>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.bookshelf.batchExportTitle),
      content: Text(t.bookshelf.batchExportSubtitle),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(ExportType.folder),
          child: Text(t.comicInfo.folder),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(ExportType.zip),
          child: Text(t.comicInfo.zip),
        ),
      ],
    ),
  );
}

Future<String?> _resolveBatchExportDirectory() async {
  if (Platform.isIOS) {
    return getDirectoryPath();
  }
  final customPath = globalSetting.customExportPath.trim();
  if (customPath.isNotEmpty) {
    return customPath;
  }
  if (Platform.isAndroid) {
    final granted = await requestExportPermission();
    if (!granted) {
      throw StateError(t.comicInfo.exportPermissionDenied);
    }
    return createDownloadDir();
  }
  return getDirectoryPath();
}

String _sanitizeFileName(String input) {
  final safe = input
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return safe.isEmpty ? 'comic' : safe;
}
