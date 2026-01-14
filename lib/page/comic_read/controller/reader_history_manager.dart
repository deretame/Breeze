import 'dart:async';

import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/page/comic_info/json/jm/jm_comic_info_json.dart';
import 'package:zephyr/page/comic_info/models/all_info.dart';
import 'package:zephyr/page/comic_read/comic_read.dart'
    show comicToBikaComicHistory;
import 'package:zephyr/page/comic_read/method/history_writer.dart';
import 'package:zephyr/page/comic_read/method/type_change.dart'
    show jmToJmHistory;
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';

import '../../../main.dart'; // 引用 objectbox
import '../../../object_box/model.dart';
import '../../../object_box/objectbox.g.dart';
import '../../../type/enum.dart';

class ReaderHistoryManager {
  final String comicId;
  final int order;
  final From from;
  final dynamic comicInfo;
  final HistoryWriter historyWriter;

  // 状态回调
  final int Function() getPageIndex;
  final NormalComicEpInfo Function() getEpInfo;
  final StringSelectCubit stringSelectCubit;

  // 内部状态
  BikaComicHistory? _bikaHistory;
  JmHistory? _jmHistory;
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
    if (from == From.bika) {
      final allInfo = comicInfo as AllInfo;
      _bikaHistory = objectbox.bikaHistoryBox
          .query(BikaComicHistory_.comicId.equals(comicId))
          .build()
          .findFirst();

      if (_bikaHistory == null) {
        _bikaHistory = comicToBikaComicHistory(allInfo.comicInfo);
        objectbox.bikaHistoryBox.put(_bikaHistory!);
      }
    } else if (from == From.jm) {
      final jmComic = comicInfo as JmComicInfoJson;
      _jmHistory = objectbox.jmHistoryBox
          .query(JmHistory_.comicId.equals(comicId))
          .build()
          .findFirst();

      if (_jmHistory == null) {
        _jmHistory = jmToJmHistory(jmComic);
        objectbox.jmHistoryBox.put(_jmHistory!);
      }
    }

    await historyWriter.start();
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
    historyWriter.stop();
  }

  /// 获取历史记录中的页码，用于初始定位
  int getHistoryPageIndex() {
    if (from == From.bika) {
      return _bikaHistory?.epPageCount ?? 0;
    } else {
      return _jmHistory?.epPageCount ?? 0;
    }
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
      final isJmAndSeriesEmpty =
          from == From.jm && (comicInfo as JmComicInfoJson).series.isEmpty;
      final historyPrefix = isJmAndSeriesEmpty
          ? '历史：第1话'
          : '历史：${epInfo.epName}';

      stringSelectCubit.setDate(
        '$historyPrefix / ${pageIndex - 1} / $currentTime',
      );
    }

    // 写入数据库
    _isInserting = true;
    try {
      if (from == From.bika && _bikaHistory != null) {
        final temp = (comicInfo as AllInfo).comicInfo;
        _bikaHistory!
          ..thumbFileServer = temp.thumb.fileServer
          ..thumbPath = temp.thumb.path
          ..thumbOriginalName = temp.thumb.originalName
          ..history = DateTime.now().toUtc()
          ..order = order
          ..epPageCount = pageIndex
          ..epTitle = epInfo.epName
          ..epId = epInfo.epId
          ..deleted = false;
        historyWriter.updateBikaHistory(_bikaHistory!);
      } else if (from == From.jm && _jmHistory != null) {
        final isJmAndSeriesEmpty =
            (comicInfo as JmComicInfoJson).series.isEmpty;
        _jmHistory!
          ..history = DateTime.now().toUtc()
          ..order = order
          ..epPageCount = pageIndex
          ..epTitle = isJmAndSeriesEmpty ? '' : epInfo.epName
          ..epId = epInfo.epId
          ..deleted = false;
        historyWriter.updateJmHistory(_jmHistory!);
      }
    } finally {
      _isInserting = false;
      _lastUpdateTime = DateTime.now();
    }
  }
}
