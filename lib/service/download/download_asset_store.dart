import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as file_path;
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/get_path.dart';

/// 资产在本地磁盘上的候选位置。
///
/// 新文件只写入 [canonicalDownload]；其余位置仅用于兼容已经存在的文件。
enum DownloadAssetLocation { canonicalDownload, legacyDownload, canonicalCache }

class DownloadAssetCandidate {
  const DownloadAssetCandidate({required this.path, required this.location});

  final String path;
  final DownloadAssetLocation location;
}

/// 下载/缓存图片的统一路径解析器和文件落盘工具。
class DownloadAssetStore {
  DownloadAssetStore({
    required String from,
    required String path,
    required String cartoonId,
    required String chapterId,
    String storageChapterId = '',
    required this.pictureType,
  }) : from = from.trim(),
       path = path.trim(),
       cartoonId = cartoonId.trim(),
       chapterId = chapterId.trim(),
       storageChapterId = storageChapterId.trim();

  final String from;
  final String path;
  final String cartoonId;
  final String chapterId;
  final String storageChapterId;
  final PictureType pictureType;

  bool get isCover => pictureType == PictureType.cover;

  String get effectiveChapterId {
    return storageChapterId.isNotEmpty ? storageChapterId : chapterId;
  }

  /// 新布局只由 hash 片段组成，任何外部传入值都不会直接进入路径。
  Future<DownloadAssetCandidate> canonicalDownloadCandidate() async {
    return _canonicalCandidate(
      await getDownloadPath(),
      DownloadAssetLocation.canonicalDownload,
    );
  }

  Future<DownloadAssetCandidate> canonicalCacheCandidate() async {
    return _canonicalCandidate(
      await getCachePath(),
      DownloadAssetLocation.canonicalCache,
    );
  }

  /// 仅返回下载目录中的候选项。第一个是新布局，后面是已确认存在过的旧布局。
  Future<List<DownloadAssetCandidate>> downloadCandidates() async {
    if (path.isEmpty) return const [];

    final root = await getDownloadPath();
    final normalizedPath = normalizeStoredAssetPath(path);
    final pathHash = encodePath(path: path);
    final normalizedPathHash = encodePath(path: normalizedPath);
    final cartoonHash = encodePath(path: cartoonId);
    final chapterKeys = <String>{effectiveChapterId};
    if (chapterId.isNotEmpty) chapterKeys.add(chapterId);

    final result = <DownloadAssetCandidate>[await canonicalDownloadCandidate()];

    void addLegacy(String candidatePath) {
      if (isWithinRoot(root, candidatePath) &&
          !result.any((item) => item.path == candidatePath)) {
        result.add(
          DownloadAssetCandidate(
            path: candidatePath,
            location: DownloadAssetLocation.legacyDownload,
          ),
        );
      }
    }

    // c703e334 以前的编码布局：from 未 hash，且包含 original。
    for (final legacyChapterId in chapterKeys) {
      final encodedChapter = encodePath(path: legacyChapterId);
      addLegacy(
        _buildLegacyFilePath(
          root,
          encodedCartoon: cartoonHash,
          encodedChapter: encodedChapter,
          fileName: normalizedPathHash,
        ),
      );

      // 更早版本曾把原始文件扩展名拼接到文件名 hash 后面。
      final extension = file_path.extension(normalizedPath);
      if (extension.isNotEmpty) {
        addLegacy(
          _buildLegacyFilePath(
            root,
            encodedCartoon: cartoonHash,
            encodedChapter: encodedChapter,
            fileName: '$pathHash$extension',
          ),
        );
      }

      // 未编码的历史布局只使用安全的 basename，不让旧输入重新成为路径结构。
      addLegacy(
        _buildLegacyFilePath(
          root,
          cartoonSegment: cartoonId,
          chapterSegment: legacyChapterId,
          fileName: normalizedPath,
        ),
      );
    }

    return result;
  }

  Future<DownloadAssetCandidate?> findExistingDownload() async {
    return await findCanonicalDownload() ?? await findLegacyDownload();
  }

  Future<DownloadAssetCandidate?> findCanonicalDownload() async {
    return _findExisting([await canonicalDownloadCandidate()]);
  }

  Future<DownloadAssetCandidate?> findLegacyDownload() async {
    return _findExisting(
      (await downloadCandidates())
          .where(
            (candidate) =>
                candidate.location == DownloadAssetLocation.legacyDownload,
          )
          .toList(),
    );
  }

  Future<DownloadAssetCandidate?> _findExisting(
    List<DownloadAssetCandidate> candidates,
  ) async {
    for (final candidate in candidates) {
      final file = File(candidate.path);
      try {
        if (await file.exists() && await file.length() > 0) {
          return candidate;
        }
      } catch (_) {
        // 读取失败时继续尝试下一个兼容路径。
      }
    }
    return null;
  }

  /// 读取缓存时只检查新缓存布局，不兼容旧缓存布局。
  Future<DownloadAssetCandidate?> findCanonicalCache() async {
    final candidate = await canonicalCacheCandidate();
    final file = File(candidate.path);
    try {
      if (await file.exists() && await file.length() > 0) return candidate;
    } catch (_) {}
    return null;
  }

  /// 读取本地图片时，先查下载目录，再查新缓存目录。
  Future<DownloadAssetCandidate?> findExisting() async {
    return await findExistingDownload() ?? await findCanonicalCache();
  }

  /// 将旧下载文件迁移到新布局；删除源文件必须发生在目标文件确认完成之后。
  Future<String> migrateDownload(DownloadAssetCandidate candidate) async {
    if (candidate.location == DownloadAssetLocation.canonicalDownload) {
      return candidate.path;
    }

    final target = await canonicalDownloadPath();
    await copyFileAtomically(sourcePath: candidate.path, finalPath: target);
    final targetFile = File(target);
    if (!await targetFile.exists() || await targetFile.length() <= 0) {
      throw StateError('旧下载迁移后目标文件不存在或为空: $target');
    }
    if (candidate.path != target) {
      await File(candidate.path).delete();
    }
    return target;
  }

  Future<String> canonicalDownloadPath() async {
    return (await canonicalDownloadCandidate()).path;
  }

  Future<String> canonicalCachePath() async {
    return (await canonicalCacheCandidate()).path;
  }

  DownloadAssetCandidate _canonicalCandidate(
    String root,
    DownloadAssetLocation location,
  ) {
    final segments = <String>[
      root,
      encodePath(path: from),
      encodePath(path: cartoonId),
      encodePath(path: effectiveChapterId),
      encodePath(path: normalizeStoredAssetPath(path)),
    ];
    final candidate = file_path.joinAll(segments);
    if (!isWithinRoot(root, candidate)) {
      throw StateError('生成的资产路径越出根目录: $candidate');
    }
    return DownloadAssetCandidate(path: candidate, location: location);
  }

  String _buildLegacyFilePath(
    String root, {
    String? encodedCartoon,
    String? encodedChapter,
    String? cartoonSegment,
    String? chapterSegment,
    required String fileName,
  }) {
    return _buildStoredFilePath(
      root,
      from,
      fileName,
      encodedCartoon ?? cartoonSegment ?? '',
      isCover ? '' : (encodedChapter ?? chapterSegment ?? ''),
      rootFolder: 'original',
    );
  }

  /// 将字节先写入临时文件，再提交到最终路径。
  static Future<void> writeBytesAtomically(
    Uint8List data, {
    required String finalPath,
    String taskId = '',
  }) async {
    if (data.isEmpty) {
      throw StateError('不能写入空图片数据');
    }

    final temporaryPath = temporaryPathFor(finalPath, taskId: taskId);
    final temporaryFile = File(temporaryPath);
    try {
      await ensureParentDirectory(finalPath);
      await temporaryFile.writeAsBytes(data, flush: true);
      if (await temporaryFile.length() <= 0) {
        throw StateError('临时图片文件为空');
      }
      await commitTemporaryFile(temporaryPath, finalPath);
    } catch (_) {
      await _deleteIfExists(temporaryFile);
      rethrow;
    }
  }

  /// 将已有缓存文件原子复制到编码下载路径。
  Future<void> copyFileAtomically({
    required String sourcePath,
    required String finalPath,
    String taskId = '',
  }) async {
    final source = File(sourcePath);
    final temporaryPath = temporaryPathFor(finalPath, taskId: taskId);
    final temporaryFile = File(temporaryPath);
    try {
      await ensureParentDirectory(finalPath);
      await source.copy(temporaryPath);
      if (await temporaryFile.length() <= 0) {
        throw StateError('临时复制文件为空');
      }
      await commitTemporaryFile(temporaryPath, finalPath);
    } catch (_) {
      await _deleteIfExists(temporaryFile);
      rethrow;
    }
  }

  static String temporaryPathFor(String finalPath, {String taskId = ''}) {
    final rawSuffix = taskId.trim().isNotEmpty
        ? taskId.trim()
        : DateTime.now().microsecondsSinceEpoch.toString();
    final suffix = rawSuffix.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    return '$finalPath.part.$suffix';
  }

  static Future<void> commitTemporaryFile(
    String temporaryPath,
    String finalPath,
  ) async {
    final temporaryFile = File(temporaryPath);
    final finalFile = File(finalPath);
    if (!await temporaryFile.exists() || await temporaryFile.length() <= 0) {
      throw StateError('临时图片文件不存在或为空: $temporaryPath');
    }

    // 并发下载同一资源时，已经提交的完整文件优先保留。
    if (await finalFile.exists() && await finalFile.length() > 0) {
      await _deleteIfExists(temporaryFile);
      return;
    }

    await ensureParentDirectory(finalPath);
    try {
      await temporaryFile.rename(finalPath);
    } on FileSystemException {
      // Windows 等平台在 rename 竞态下可能报告目标已存在；重新确认后
      // 将其视为另一个执行器已经完成写入。
      if (await finalFile.exists() && await finalFile.length() > 0) {
        await _deleteIfExists(temporaryFile);
        return;
      }
      rethrow;
    }
  }

  static Future<void> ensureParentDirectory(String filePath) async {
    final directory = Directory(file_path.dirname(filePath));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  static Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  static String _buildStoredFilePath(
    String basePath,
    String from,
    String path,
    String cartoonId,
    String chapterId, {
    String? rootFolder,
  }) {
    final fileName = normalizeStoredAssetPath(path);
    final segments = <String>[basePath, from.trim()];
    if (rootFolder != null && rootFolder.isNotEmpty) {
      segments.add(rootFolder);
    }
    if (cartoonId.trim().isNotEmpty) segments.add(cartoonId.trim());
    if (chapterId.trim().isNotEmpty) segments.add(chapterId.trim());
    segments.add(fileName);
    return file_path.joinAll(segments);
  }

  static bool isWithinRoot(String rootPath, String candidatePath) {
    final root = file_path.normalize(file_path.absolute(rootPath));
    final candidate = file_path.normalize(file_path.absolute(candidatePath));
    final normalizedRoot = Platform.isWindows ? root.toLowerCase() : root;
    final normalizedCandidate = Platform.isWindows
        ? candidate.toLowerCase()
        : candidate;
    return normalizedCandidate == normalizedRoot ||
        normalizedCandidate.startsWith('$normalizedRoot${file_path.separator}');
  }
}

/// 取消任务时只清理该任务写入的临时文件，不触碰已经提交的历史图片。
Future<void> cleanupDownloadTaskTemporaryFiles(String taskKey) async {
  final suffix = taskKey.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
  if (suffix.isEmpty) return;

  final roots = <String>[await getDownloadPath(), await getCachePath()];
  for (final rootPath in roots) {
    final root = Directory(rootPath);
    if (!await root.exists()) continue;

    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File ||
          !DownloadAssetStore.isWithinRoot(rootPath, entity.path)) {
        continue;
      }
      final name = file_path.basename(entity.path);
      if (!name.endsWith('.part.$suffix')) continue;
      try {
        await entity.delete();
      } catch (_) {
        // 临时文件清理失败不应影响任务状态迁移。
      }
    }
  }
}

String normalizeStoredAssetPath(String rawPath, {bool allowEmpty = false}) {
  final raw = rawPath.trim();
  if (raw.isEmpty) {
    if (allowEmpty) return '';
    throw StateError('normalizeStoredAssetPath requires non-empty path');
  }
  final candidate = file_path.isAbsolute(raw) ? file_path.basename(raw) : raw;
  final sanitized = candidate.replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '_');
  if (sanitized.isNotEmpty) return sanitized;
  throw StateError('normalizeStoredAssetPath received invalid path: $rawPath');
}
