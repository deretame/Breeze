import 'dart:convert';

import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/widgets/comic_entry/models/models.dart';

/// 追更列表展示层纯函数：无 Flutter 依赖，方便单测。
Map<String, dynamic> decodeFollowJsonMap(String raw) {
  if (raw.trim().isEmpty) {
    return const <String, dynamic>{};
  }
  final decoded = jsonDecode(raw);
  if (decoded is Map) {
    return Map<String, dynamic>.from(decoded);
  }
  return const <String, dynamic>{};
}

/// 解析封面，脏数据回退为空占位（用 comicId 兜底）。
UnifiedComicCover resolveFollowCover(ComicFollow follow) {
  try {
    final map = decodeFollowJsonMap(follow.cover);
    if (map.isNotEmpty) {
      return UnifiedComicCover.fromJson(map);
    }
  } catch (_) {}
  return UnifiedComicCover(
    id: follow.comicId,
    url: '',
    path: '',
    extern: const <String, dynamic>{},
  );
}

/// 解析创建者（作者）名称，缺失或脏数据返回 null。
String? parseFollowCreatorName(String raw) {
  try {
    final map = decodeFollowJsonMap(raw);
    if (map.isEmpty) {
      return null;
    }
    final name = Creator.fromJson(map).name.trim();
    return name.isEmpty ? null : name;
  } catch (_) {
    return null;
  }
}

/// 短检测时间：当天只显示时分，同年省略年份（去掉秒，列表更干净）。
String formatFollowCheckTime(DateTime time, {DateTime? now}) {
  final local = time.toLocal();
  final current = (now ?? DateTime.now()).toLocal();
  final hm =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  final sameDay =
      local.year == current.year &&
      local.month == current.month &&
      local.day == current.day;
  if (sameDay) {
    return hm;
  }
  if (local.year == current.year) {
    return '${local.month}-${local.day} $hm';
  }
  return '${local.year}-${local.month}-${local.day} $hm';
}

/// 阅读进度 0..1，数据缺失或越界时钳制。
double followReadProgress({
  required int readOrder,
  required int detectedTotal,
}) {
  if (readOrder <= 0 || detectedTotal <= 0) {
    return 0;
  }
  return (readOrder / detectedTotal).clamp(0.0, 1.0).toDouble();
}
