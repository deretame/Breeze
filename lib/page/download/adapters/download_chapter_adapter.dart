import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/page/download/models/download_chapter.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/util/foreground_task/data/download_task_json.dart';

/// 把各种 legacy 章节数据格式转换为干净的 [DownloadChapter]。
///
/// 本项目从“单一漫画源 App”演变为“插件平台”的过程中，章节标识字段
/// 不断叠加：先有 `id` + `order`，后来又出现 `requestId`、`storageChapterId`、
/// `logicalKey`、`taskChapterId` 等。不同历史阶段的数据格式混在 ObjectBox
/// 里，导致读取时必须做兼容。
///
/// 本适配器把所有 legacy 字段统一映射为语义清晰的三个 key：
///
/// | DownloadChapter 字段 | 语义 | 来源 |
/// |---------------------|------|------|
/// | `id` | 宿主内部匹配 key（历史、下载选中、跳章） | `logicalKey` > `id` > `taskChapterId` > `requestId` > `order` |
/// | `requestId` | 调用插件 `getChapter` / `getReadSnapshot` 的 key | `requestId` > `taskChapterId`；老数据 fallback 到 `id` |
/// | `storageId` | 本地文件系统目录 key | `storageChapterId`；旧版本未写该字段时 fallback 到 `id` |
///
/// 处理的数据格式：
///
/// 1. **纯老数据**（无插件化字段）：
///    ```json
///    {"id": "ep123", "name": "第1话", "order": 1, "images": []}
///    ```
///    此时 `id` 同时是匹配 key、请求 key、存储 key。
///
/// 2. **旧插件数据**（有 `logicalKey` / `taskChapterId`，但无 `storageChapterId`）：
///    ```json
///    {"id": "Gallery", "logicalKey": "chunk-1", "taskChapterId": "req-456",
///     "name": "第1话", "order": 1, "images": []}
///    ```
///    旧版本把 storage key 放在 `id` 字段，`logicalKey` 放匹配 key，
///    `taskChapterId` 放请求 key。通过判断 `storageChapterId` 字段是否存
///    在来识别这种数据。
///
/// 3. **新插件数据**（字段齐全）：
///    ```json
///    {"id": "Gallery", "logicalKey": "chunk-1", "taskChapterId": "req-456",
///     "storageChapterId": "Gallery", "name": "第1话", "order": 1, "images": []}
///    ```
///    `storageChapterId` 字段存在且非空，直接作为 `storageId`。
///
/// 4. **下载任务引用** [DownloadChapterTaskRef]：
///    直接读取 `logicalKey` / `chapterId` / `requestId` / `storageChapterId`。
///
/// 5. **在线详情章节** [UnifiedComicDownloadChapter]：
///    从插件详情页转换而来，字段含义与任务引用类似。
class DownloadChapterAdapter {
  const DownloadChapterAdapter();

  /// 从本地存储的 `UnifiedComicDownloadStoredChapter` JSON 转换。
  DownloadChapter fromStoredMap(Map<String, dynamic> map) {
    final rawLogicalKey = _string(map['logicalKey']);
    final rawId = _string(map['id']);
    final rawTaskChapterId = _string(map['taskChapterId']);
    final rawRequestId = _string(map['requestId']);
    final rawStorageId = _string(map['storageChapterId']);
    // 旧版本 `UnifiedComicDownloadStoredChapter.toMap()` 没有输出 `storageChapterId`，
    // 因此可以用字段是否存在来判断数据是否由新版本写入。
    final hasStorageChapterIdField = map.containsKey('storageChapterId');
    final order = _toInt(map['order'], 1);

    final isLegacy = _isLegacyData(
      logicalKey: rawLogicalKey,
      requestId: rawRequestId,
      taskChapterId: rawTaskChapterId,
      storageChapterId: rawStorageId,
    );

    final id =
        _firstNonEmpty([
          rawLogicalKey,
          rawId,
          rawTaskChapterId,
          rawRequestId,
        ]) ??
        order.toString();

    final String? requestId;
    if (rawRequestId.isNotEmpty) {
      requestId = rawRequestId;
    } else if (rawTaskChapterId.isNotEmpty) {
      requestId = rawTaskChapterId;
    } else if (isLegacy && rawId.isNotEmpty) {
      // 老数据：id 同时是匹配 key 和请求 key。
      requestId = rawId;
    } else {
      requestId = null;
    }

    final String? storageId;
    if (rawStorageId.isNotEmpty) {
      storageId = rawStorageId;
    } else if (!hasStorageChapterIdField && rawId.isNotEmpty) {
      // 旧版本未写入 storageChapterId，此时 `id` 字段就是本地存储目录 key。
      storageId = rawId;
    } else if (isLegacy && rawId.isNotEmpty) {
      // 老数据：id 同时是匹配/请求/存储 key。
      storageId = rawId;
    } else {
      storageId = null;
    }

    return DownloadChapter(
      id: id,
      displayName: _string(map['name']),
      order: order,
      requestId: requestId,
      storageId: storageId,
      extern: const {},
      images: _imagesFromList(map['images'] as List?),
    );
  }

  /// 从下载任务引用 [DownloadChapterTaskRef] 转换。
  DownloadChapter fromTaskRef(DownloadChapterTaskRef ref) {
    final rawLogicalKey = ref.logicalKey.trim();
    final rawChapterId = ref.chapterId.trim();
    final rawRequestId = ref.requestId.trim();

    final id =
        _firstNonEmpty([rawLogicalKey, rawChapterId, rawRequestId]) ??
        ref.order.toString();

    return DownloadChapter(
      id: id,
      displayName: ref.title.trim(),
      order: ref.order,
      requestId: rawRequestId.isNotEmpty ? rawRequestId : null,
      storageId: ref.storageChapterId.trim().isNotEmpty
          ? ref.storageChapterId.trim()
          : null,
      extern: Map<String, dynamic>.from(ref.extern),
      images: const [],
    );
  }

  /// 从插件返回的 [Ep] 转换（详情页章节列表）。
  DownloadChapter fromEp(Ep episode) {
    final rawLogicalKey = episode.logicalKey.trim();
    final rawId = episode.id.trim();
    final rawRequestId = episode.requestId.trim();

    final id =
        _firstNonEmpty([rawLogicalKey, rawId, rawRequestId]) ??
        episode.order.toString();

    return DownloadChapter(
      id: id,
      displayName: episode.name.trim(),
      order: episode.order,
      requestId: rawRequestId.isNotEmpty ? rawRequestId : null,
      storageId: episode.storageChapterId.trim().isNotEmpty
          ? episode.storageChapterId.trim()
          : null,
      extern: Map<String, dynamic>.from(episode.extern),
      images: const [],
    );
  }

  /// 从宿主内部章节引用 [UnifiedComicChapterRef] 转换（阅读页上下章匹配）。
  DownloadChapter fromChapterRef(UnifiedComicChapterRef ref) {
    final rawLogicalKey = ref.logicalKey.trim();
    final rawId = ref.id.trim();
    final rawRequestId = ref.requestId.trim();

    final id =
        _firstNonEmpty([rawLogicalKey, rawId, rawRequestId]) ??
        ref.order.toString();

    return DownloadChapter(
      id: id,
      displayName: ref.name.trim(),
      order: ref.order,
      requestId: rawRequestId.isNotEmpty ? rawRequestId : null,
      storageId: ref.storageChapterId.trim().isNotEmpty
          ? ref.storageChapterId.trim()
          : null,
      extern: Map<String, dynamic>.from(ref.extern),
      images: const [],
    );
  }

  /// 从在线详情 [UnifiedComicDownloadChapter] 转换。
  DownloadChapter fromOnlineChapter(UnifiedComicDownloadChapter chapter) {
    final rawLogicalKey = chapter.logicalKey.trim();
    final rawId = chapter.id.trim();
    final rawRequestId = chapter.requestId.trim();

    final id =
        _firstNonEmpty([rawLogicalKey, rawId, rawRequestId]) ??
        chapter.order.toString();

    return DownloadChapter(
      id: id,
      displayName: chapter.title.trim(),
      order: chapter.order,
      requestId: rawRequestId.isNotEmpty ? rawRequestId : null,
      storageId: chapter.storageChapterId.trim().isNotEmpty
          ? chapter.storageChapterId.trim()
          : null,
      extern: Map<String, dynamic>.from(chapter.extern),
      images: chapter.images
          .map(
            (image) => DownloadImage(
              id: image.id,
              name: image.name,
              path: image.path,
              url: image.url,
              extern: Map<String, dynamic>.from(image.extern),
            ),
          )
          .toList(),
    );
  }

  /// 判断是否为纯老数据：没有任何插件化后的字段。
  bool _isLegacyData({
    required String logicalKey,
    required String requestId,
    required String taskChapterId,
    required String storageChapterId,
  }) {
    return logicalKey.isEmpty &&
        requestId.isEmpty &&
        taskChapterId.isEmpty &&
        storageChapterId.isEmpty;
  }

  String _string(dynamic value) => value?.toString().trim() ?? '';

  int _toInt(dynamic value, int fallback) {
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String? _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  List<DownloadImage> _imagesFromList(List? raw) {
    if (raw == null) return const [];
    return raw
        .whereType<Map>()
        .map((e) => _imageFromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  DownloadImage _imageFromMap(Map<String, dynamic> map) {
    return DownloadImage(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      path: map['path']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      extern: Map<String, dynamic>.from(
        map['extern'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
