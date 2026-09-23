// To parse this JSON data, do
//
//     final downloadTaskJson = downloadTaskJsonFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'download_task_json.freezed.dart';
part 'download_task_json.g.dart';

const currentDownloadTaskSchemaVersion = 3;

/// 整本下载记录（UnifiedComicDownload.uniqueKey）用的 key，依然按漫画粒度。
String buildDownloadTaskKey(String from, String comicId) {
  return '${from.trim()}:${comicId.trim()}';
}

/// 章节任务用的 key，精确到单章节。
///
/// [chapterKey] 必须是章节的逻辑身份（logicalKey > chapterId > requestId，
/// 兜底 order，见 [downloadChapterKeyOfRef]），绝不能用 storage 系 key
///（多分块可共享，如 EH 的 "Gallery"）或裸 order。
/// taskKey 只做整体字符串比较，从不按 ':' 切分，因此 key 里含 ':' 也无害。
String buildDownloadChapterTaskKey(
  String from,
  String comicId,
  String chapterKey,
) {
  return '${from.trim()}:${comicId.trim()}:${chapterKey.trim()}';
}

/// 从任务引用里算出章节逻辑身份，与
/// `DownloadChapterAdapter.fromTaskRef().id` 保持同一规则。
String downloadChapterKeyOfRef(DownloadChapterTaskRef ref) {
  for (final candidate in [
    ref.logicalKey.trim(),
    ref.chapterId.trim(),
    ref.requestId.trim(),
  ]) {
    if (candidate.isNotEmpty) return candidate;
  }
  return ref.order.toString();
}

DownloadTaskJson downloadTaskJsonFromJson(String str) =>
    DownloadTaskJson.fromJson(json.decode(str));

String downloadTaskJsonToJson(DownloadTaskJson data) =>
    json.encode(data.toJson());

@freezed
abstract class DownloadChapterTaskRef with _$DownloadChapterTaskRef {
  @JsonSerializable(explicitToJson: true)
  const factory DownloadChapterTaskRef({
    @Default('') String chapterId,
    @Default('') String requestId,
    @Default('') String storageChapterId,
    @Default('') String logicalKey,
    @Default('') String title,
    @Default(0) int order,
    @Default(<String, dynamic>{}) Map<String, dynamic> extern,
  }) = _DownloadChapterTaskRef;

  factory DownloadChapterTaskRef.fromJson(Map<String, dynamic> json) =>
      _$DownloadChapterTaskRefFromJson(json);
}

@Freezed(makeCollectionsUnmodifiable: false)
abstract class DownloadTaskJson with _$DownloadTaskJson {
  @JsonSerializable(explicitToJson: true)
  const factory DownloadTaskJson({
    required String from,
    required String comicId,
    required String comicName,
    required DownloadChapterTaskRef chapterRef,
    @Default(currentDownloadTaskSchemaVersion) int schemaVersion,
    @Default('queued') String stateCode,
    @Default('') String phaseCode,
    @Default(0) int completedImages,
    @Default(0) int reusedImages,
    @Default(0) int totalImages,
    @Default(<String>[]) List<String> imagePaths,
    @Default(0) int attempt,
    @Default('') String lastErrorCode,
    @Default('') String lastErrorMessage,
  }) = _DownloadTaskJson;

  factory DownloadTaskJson.fromJson(Map<String, dynamic> json) =>
      _$DownloadTaskJsonFromJson(json);

  const DownloadTaskJson._();

  String get chapterKey => downloadChapterKeyOfRef(chapterRef);

  String get taskKey => buildDownloadChapterTaskKey(from, comicId, chapterKey);
}
