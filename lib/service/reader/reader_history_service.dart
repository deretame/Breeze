import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:worker_manager/worker_manager.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/util/worker_isolate.dart';

/// 供 [ReaderHistoryService] 周期性保存时使用的快照。
class HistorySnapshot {
  const HistorySnapshot({
    required this.pageIndex,
    required this.chapterOrder,
    required this.epInfo,
  });

  final int pageIndex;
  final int chapterOrder;
  final NormalComicEpInfo epInfo;
}

/// 阅读器历史记录服务。
///
/// 封装 ObjectBox 历史记录查询、worker isolate 写入与序列化逻辑，
/// 通过 [statusStream] 把左下角状态文本暴露给 controller，自身不依赖任何 cubit。
class ReaderHistoryService {
  static final ReaderHistoryService instance = ReaderHistoryService._();
  ReaderHistoryService._();

  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  String? _source;
  String? _comicId;
  normal.ComicInfo? _comicInfo;
  UnifiedComicHistory? _history;
  Timer? _timer;
  DateTime? _lastUpdateTime;
  bool _isInserting = false;
  bool _isLoading = true;
  HistorySnapshot Function()? _snapshotProvider;

  /// 加载指定漫画的历史记录，并解析 comicInfo 供后续写入使用。
  Future<void> loadHistory({
    required String source,
    required String comicId,
    required dynamic comicInfo,
  }) async {
    _source = source;
    _comicId = comicId;
    _comicInfo = _resolveNormalComicInfo(comicInfo);
    _isLoading = true;

    final query = objectbox.unifiedHistoryBox
        .query(UnifiedComicHistory_.uniqueKey.equals('$source:$comicId'))
        .build();
    try {
      _history = query.findFirst();
    } finally {
      query.close();
    }
  }

  /// 上次加载到的历史页码，未加载或为 null 时返回 0。
  int get lastPageIndex => _history?.pageIndex ?? 0;

  /// 标记数据加载完成，可以开始写入。
  void markLoaded() => _isLoading = false;

  /// 启动周期性保存。
  ///
  /// [provider] 由 controller 提供，用于在每次触发时获取当前阅读快照。
  void startPeriodicSave(HistorySnapshot Function() provider) {
    _snapshotProvider = provider;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _writeHistory();
    });
  }

  /// 立即停止周期性保存。
  void stop() => _timer?.cancel();

  Future<void> _writeHistory() async {
    if (_isLoading || _comicInfo == null) return;
    if (_isInserting) return;
    if (_lastUpdateTime != null &&
        DateTime.now().difference(_lastUpdateTime!).inMilliseconds < 100) {
      return;
    }

    final snapshot = _snapshotProvider?.call();
    if (snapshot == null) return;

    final currentTime = DateTime.now().toLocal().toString().substring(0, 19);
    _statusController.add(
      '${snapshot.chapterOrder > 0 ? '${snapshot.chapterOrder}-' : ''}'
      '${snapshot.epInfo.epName} / ${snapshot.pageIndex - 1} / $currentTime',
    );

    _isInserting = true;
    try {
      final timestamp = DateTime.now().toUtc();
      final payload = <String, dynamic>{
        'dbRootPath': p.dirname(objectbox.store.directoryPath),
        'source': _source,
        'comicId': _comicId,
        'normalInfo': _serializeComicInfoForWorker(_comicInfo!),
        'chapterId': snapshot.epInfo.epId,
        'chapterTitle': snapshot.epInfo.epName,
        'chapterOrder': snapshot.chapterOrder,
        'pageIndex': snapshot.pageIndex,
        'timestamp': timestamp.toIso8601String(),
      };
      final rootIsolateToken = captureWorkerIsolateToken();
      final historyJson = await workerManager.execute<Map<String, dynamic>>(
        () => _upsertUnifiedHistoryOnWorker(payload, rootIsolateToken),
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

  normal.ComicInfo _resolveNormalComicInfo(dynamic comicInfo) {
    if (comicInfo is PluginComicDetailSource) {
      return comicInfo.normalInfo.comicInfo;
    }
    if (comicInfo is UnifiedComicDownload) {
      final detail = jsonDecode(comicInfo.detailJson) as Map<String, dynamic>;
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
  RootIsolateToken? rootIsolateToken,
) async {
  ensureWorkerIsolateInitialized(rootIsolateToken);

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
