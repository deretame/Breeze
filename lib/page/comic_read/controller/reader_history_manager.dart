import 'dart:async';

import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/page/comic_read/method/history_writer.dart';
import 'package:zephyr/page/comic_read/method/type_change.dart'
    show bikaNormalComicInfoFromAny;
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'dart:convert';

import '../../../main.dart'; // 引用 objectbox
import '../../../object_box/model.dart';
import '../../../object_box/objectbox.g.dart';
import '../../../page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;
import '../../../page/comic_info/models/to_normal_info.dart';

class ReaderHistoryManager {
  final String comicId;
  final int order;
  final String from;
  final dynamic comicInfo;
  final HistoryWriter historyWriter;

  // 状态回调
  final int Function() getPageIndex;
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
    required this.getEpInfo,
    required this.stringSelectCubit,
  });

  /// 初始化：查询或创建历史记录对象
  Future<void> init() async {
    _history = objectbox.unifiedHistoryBox
        .query(UnifiedComicHistory_.uniqueKey.equals('$from:$comicId'))
        .build()
        .findFirst();

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
      final temp = _resolveNormalComicInfo();
      final timestamp = DateTime.now().toUtc();
      _upsertUnifiedHistory(
        normalInfo: temp,
        chapterId: epInfo.epId,
        chapterTitle: epInfo.epName,
        chapterOrder: order,
        pageIndex: pageIndex,
        timestamp: timestamp,
      );
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
    try {
      return bikaNormalComicInfoFromAny(comicInfo);
    } catch (_) {
      return jm2NormalComicAllInfo(comicInfo as dynamic).comicInfo;
    }
  }

  void _upsertUnifiedHistory({
    required normal.ComicInfo normalInfo,
    required String chapterId,
    required String chapterTitle,
    required int chapterOrder,
    required int pageIndex,
    required DateTime timestamp,
  }) {
    final key = '$from:$comicId';
    final existing = objectbox.unifiedHistoryBox
        .query(UnifiedComicHistory_.uniqueKey.equals(key))
        .build()
        .findFirst();

    final entity =
        existing ??
        UnifiedComicHistory(
          uniqueKey: key,
          source: from,
          comicId: comicId,
          title: normalInfo.title,
          description: normalInfo.description,
          cover: _normalizeFlexMap(normalInfo.cover),
          creator: _normalizeFlexMap(normalInfo.creator),
          titleMeta: _normalizeFlexList(normalInfo.titleMeta),
          metadata: _normalizeFlexList(normalInfo.metadata),
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
      ..cover = _normalizeFlexMap(normalInfo.cover)
      ..creator = _normalizeFlexMap(normalInfo.creator)
      ..titleMeta = _normalizeFlexList(normalInfo.titleMeta)
      ..metadata = _normalizeFlexList(normalInfo.metadata)
      ..chapterId = chapterId
      ..chapterTitle = chapterTitle
      ..chapterOrder = chapterOrder
      ..pageIndex = pageIndex
      ..lastReadAt = timestamp
      ..updatedAt = timestamp
      ..deleted = false;

    entity.id = objectbox.unifiedHistoryBox.put(entity);
    _history = entity;
  }

  Map<String, dynamic> _normalizeFlexMap(dynamic value) {
    final encoded = jsonEncode(value);
    final decoded = jsonDecode(encoded);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _normalizeFlexList(List<dynamic> value) {
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
}
