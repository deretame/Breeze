// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_task_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DownloadChapterTaskRef _$DownloadChapterTaskRefFromJson(
  Map<String, dynamic> json,
) => _DownloadChapterTaskRef(
  chapterId: json['chapterId'] as String? ?? '',
  requestId: json['requestId'] as String? ?? '',
  storageChapterId: json['storageChapterId'] as String? ?? '',
  logicalKey: json['logicalKey'] as String? ?? '',
  title: json['title'] as String? ?? '',
  order: (json['order'] as num?)?.toInt() ?? 0,
  extern: json['extern'] as Map<String, dynamic>? ?? const <String, dynamic>{},
);

Map<String, dynamic> _$DownloadChapterTaskRefToJson(
  _DownloadChapterTaskRef instance,
) => <String, dynamic>{
  'chapterId': instance.chapterId,
  'requestId': instance.requestId,
  'storageChapterId': instance.storageChapterId,
  'logicalKey': instance.logicalKey,
  'title': instance.title,
  'order': instance.order,
  'extern': instance.extern,
};

_DownloadTaskJson _$DownloadTaskJsonFromJson(Map<String, dynamic> json) =>
    _DownloadTaskJson(
      from: json['from'] as String,
      comicId: json['comicId'] as String,
      comicName: json['comicName'] as String,
      chapterRef: DownloadChapterTaskRef.fromJson(
        json['chapterRef'] as Map<String, dynamic>,
      ),
      schemaVersion:
          (json['schemaVersion'] as num?)?.toInt() ??
          currentDownloadTaskSchemaVersion,
      stateCode: json['stateCode'] as String? ?? 'queued',
      phaseCode: json['phaseCode'] as String? ?? '',
      completedImages: (json['completedImages'] as num?)?.toInt() ?? 0,
      reusedImages: (json['reusedImages'] as num?)?.toInt() ?? 0,
      totalImages: (json['totalImages'] as num?)?.toInt() ?? 0,
      imagePaths:
          (json['imagePaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      attempt: (json['attempt'] as num?)?.toInt() ?? 0,
      lastErrorCode: json['lastErrorCode'] as String? ?? '',
      lastErrorMessage: json['lastErrorMessage'] as String? ?? '',
    );

Map<String, dynamic> _$DownloadTaskJsonToJson(_DownloadTaskJson instance) =>
    <String, dynamic>{
      'from': instance.from,
      'comicId': instance.comicId,
      'comicName': instance.comicName,
      'chapterRef': instance.chapterRef.toJson(),
      'schemaVersion': instance.schemaVersion,
      'stateCode': instance.stateCode,
      'phaseCode': instance.phaseCode,
      'completedImages': instance.completedImages,
      'reusedImages': instance.reusedImages,
      'totalImages': instance.totalImages,
      'imagePaths': instance.imagePaths,
      'attempt': instance.attempt,
      'lastErrorCode': instance.lastErrorCode,
      'lastErrorMessage': instance.lastErrorMessage,
    };
