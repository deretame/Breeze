import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:worker_manager/worker_manager.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/page/comic_read/method/history_writer.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';

import '../../../main.dart'; // 引用 objectbox
import '../../../object_box/model.dart';
import '../../../object_box/objectbox.g.dart';
import '../../../page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;

class ReaderHistoryManager {
  final String comicId;
  final int order;
  final String from;
  final dynamic comicInfo;
  final HistoryWriter historyWriter;

  // 状态回调
  final int Function() getPageIndex;
  final int Function() getCurrentChapterOrder;
  final NormalComicEpInfo Function() getEpInfo;
  final StringSelectCubit stringSelectCubit;

  // 内部状态
  UnifiedComicHistory? _history;
  Timer? _timer;
  DateTime? _lastUpdateTime;
  bool _isInserting = false;
  bool _isLoading = true; // 对应原本的 _loading，但这其实是数据是否准备好的标志

  ReaderHistoryManager({
    required this.comicId,
    required this.order,
    required this.from,
    required this.comicInfo,
    required this.historyWriter,
    required this.getPageIndex,
    required this.getCurrentChapterOrder,
    required this.getEpInfo,
    required this.stringSelectCubit,
  });

  /// 初始化：查询或创建历史记录对象
  Future<void> init() async {
    final query = objectbox.unifiedHistoryBox
        .query(UnifiedComicHistory_.uniqueKey.equals('$from:$comicId'))
        .build();
    try {
      _history = query.findFirst();
    } finally {
      query.close();
    }

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _writeToDatabase();
    });
  }

  /// 标记数据加载完成，可以开始写入
  void markLoaded() {
    _isLoading = false;
  }

  void stop() {
    _timer?.cancel();
  }

  /// 获取历史记录中的页码，用于初始定位
  int getHistoryPageIndex() {
    return _history?.pageIndex ?? 0;
  }

  Future<void> _writeToDatabase() async {
    // 基础检查
    if (_isLoading || comicInfo == null) return;
    if (_isInserting) return;
    if (_lastUpdateTime != null &&
        DateTime.now().difference(_lastUpdateTime!).inMilliseconds < 100) {
      return;
    }

    final pageIndex = getPageIndex();
    final epInfo = getEpInfo();
    final currentTime = DateTime.now().toLocal().toString().substring(0, 19);

    // 更新左下角文字 (StringSelectCubit)
    if (!stringSelectCubit.isClosed) {
      final historyPrefix = '历史：${epInfo.epName}';

      stringSelectCubit.setDate(
        '$historyPrefix / ${pageIndex - 1} / $currentTime',
      );
    }

    // 写入数据库
    _isInserting = true;
    try {
      final normalInfo = _resolveNormalComicInfo();
      final timestamp = DateTime.now().toUtc();
      final payload = <String, dynamic>{
        'dbRootPath': p.dirname(objectbox.store.directoryPath),
        'source': from,
        'comicId': comicId,
        'normalInfo': _serializeComicInfoForWorker(normalInfo),
        'chapterId': epInfo.epId,
        'chapterTitle': epInfo.epName,
        'chapterOrder': getCurrentChapterOrder(),
        'pageIndex': pageIndex,
        'timestamp': timestamp.toIso8601String(),
      };
      final historyJson = await workerManager.execute<Map<String, dynamic>>(
        () => _upsertUnifiedHistoryOnWorker(payload),
      );
      _history = UnifiedComicHistory.fromJson(historyJson);
    } catch (e, s) {
      logger.w('history write offloaded to worker failed', error: e);
      logger.d(s);
    } finally {
      _isInserting = false;
      _lastUpdateTime = DateTime.now();
    }
  }

  normal.ComicInfo _resolveNormalComicInfo() {
    if (comicInfo is PluginComicDetailSource) {
      return (comicInfo as PluginComicDetailSource).normalInfo.comicInfo;
    }
    if (comicInfo is UnifiedComicDownload) {
      final detail =
          jsonDecode((comicInfo as UnifiedComicDownload).detailJson)
              as Map<String, dynamic>;
      return normal.NormalComicAllInfo.fromJson(detail).comicInfo;
    }

    final map = _toDynamicMap(comicInfo);
    final comicInfoMap = _toDynamicMap(map['comicInfo']);
    if (comicInfoMap.isNotEmpty) {
      return normal.ComicInfo.fromJson(comicInfoMap);
    }
    if (_looksLikeComicInfoMap(map)) {
      return normal.ComicInfo.fromJson(map);
    }

    throw StateError('Unsupported comicInfo type: ${comicInfo.runtimeType}');
  }

  Map<String, dynamic> _toDynamicMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    try {
      final normalized = jsonDecode(jsonEncode(value));
      if (normalized is Map) {
        return Map<String, dynamic>.from(normalized);
      }
    } catch (_) {}
    return const <String, dynamic>{};
  }

  bool _looksLikeComicInfoMap(Map<String, dynamic> map) {
    return map['id'] != null &&
        map['title'] != null &&
        map['cover'] is Map &&
        map['creator'] is Map;
  }

  Map<String, dynamic> _serializeComicInfoForWorker(normal.ComicInfo info) {
    final normalized = jsonDecode(jsonEncode(info.toJson()));
    if (normalized is Map) {
      return Map<String, dynamic>.from(normalized);
    }
    throw StateError('Failed to serialize ComicInfo for worker isolate');
  }
}

Future<Map<String, dynamic>> _upsertUnifiedHistoryOnWorker(
  Map<String, dynamic> payload,
) async {
  final dbRootPath = payload['dbRootPath']?.toString() ?? '';
  if (dbRootPath.trim().isEmpty) {
    throw StateError('missing dbRootPath for history worker write');
  }

  final source = payload['source']?.toString() ?? '';
  final comicId = payload['comicId']?.toString() ?? '';
  final normalInfo = normal.ComicInfo.fromJson(
    _toWorkerMap(payload['normalInfo']),
  );
  final chapterId = payload['chapterId']?.toString() ?? '';
  final chapterTitle = payload['chapterTitle']?.toString() ?? '';
  final chapterOrder = (payload['chapterOrder'] as num?)?.toInt() ?? 0;
  final pageIndex = (payload['pageIndex'] as num?)?.toInt() ?? 0;
  final timestamp = DateTime.parse(
    payload['timestamp']?.toString() ??
        DateTime.now().toUtc().toIso8601String(),
  ).toUtc();

  final box = await ObjectBox.create(dbRootPath: dbRootPath);
  final key = '$source:$comicId';
  final query = box.unifiedHistoryBox
      .query(UnifiedComicHistory_.uniqueKey.equals(key))
      .build();

  try {
    final existing = query.findFirst();
    final entity =
        existing ??
        UnifiedComicHistory(
          uniqueKey: key,
          source: source,
          comicId: comicId,
          title: normalInfo.title,
          description: normalInfo.description,
          cover: _normalizeWorkerFlexMapString(normalInfo.cover),
          creator: _normalizeWorkerFlexMapString(normalInfo.creator),
          titleMeta: _normalizeWorkerFlexListString(normalInfo.titleMeta),
          metadata: _normalizeWorkerMetadataString(normalInfo.metadata),
          chapterId: chapterId,
          chapterTitle: chapterTitle,
          chapterOrder: chapterOrder,
          pageIndex: pageIndex,
          createdAt: timestamp,
          lastReadAt: timestamp,
          updatedAt: timestamp,
          deleted: false,
          schemaVersion: 2,
        );

    entity
      ..title = normalInfo.title
      ..description = normalInfo.description
      ..cover = _normalizeWorkerFlexMapString(normalInfo.cover)
      ..creator = _normalizeWorkerFlexMapString(normalInfo.creator)
      ..titleMeta = _normalizeWorkerFlexListString(normalInfo.titleMeta)
      ..metadata = _normalizeWorkerMetadataString(normalInfo.metadata)
      ..chapterId = chapterId
      ..chapterTitle = chapterTitle
      ..chapterOrder = chapterOrder
      ..pageIndex = pageIndex
      ..lastReadAt = timestamp
      ..updatedAt = timestamp
      ..deleted = false;

    entity.id = box.unifiedHistoryBox.put(entity);
    return entity.toJson();
  } finally {
    query.close();
  }
}

Map<String, dynamic> _toWorkerMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

Map<String, dynamic> _normalizeWorkerFlexMap(dynamic value) {
  final encoded = jsonEncode(value);
  final decoded = jsonDecode(encoded);
  if (decoded is Map) {
    return Map<String, dynamic>.from(decoded);
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _normalizeWorkerFlexList(List<dynamic> value) {
  final encoded = jsonEncode(value);
  final decoded = jsonDecode(encoded);
  if (decoded is List) {
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  return <Map<String, dynamic>>[];
}

String _normalizeWorkerFlexMapString(dynamic value) {
  return jsonEncode(_normalizeWorkerFlexMap(value));
}

String _normalizeWorkerFlexListString(List<dynamic> value) {
  return jsonEncode(_normalizeWorkerFlexList(value));
}

String _normalizeWorkerMetadataString(List<dynamic> value) {
  final normalized = _normalizeWorkerFlexList(value);
  return jsonEncode(normalized);
}
