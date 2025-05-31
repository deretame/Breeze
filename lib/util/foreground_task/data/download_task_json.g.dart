// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_task_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DownloadTaskJson _$DownloadTaskJsonFromJson(Map<String, dynamic> json) =>
    _DownloadTaskJson(
      from: json['from'] as String,
      comicId: json['comicId'] as String,
      comicName: json['comicName'] as String,
      bikaInfo: BikaInfo.fromJson(json['bikaInfo'] as Map<String, dynamic>),
      selectedChapters:
          (json['selectedChapters'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      slowDownload: json['slowDownload'] as bool,
    );

Map<String, dynamic> _$DownloadTaskJsonToJson(_DownloadTaskJson instance) =>
    <String, dynamic>{
      'from': instance.from,
      'comicId': instance.comicId,
      'comicName': instance.comicName,
      'bikaInfo': instance.bikaInfo,
      'selectedChapters': instance.selectedChapters,
      'slowDownload': instance.slowDownload,
    };

_BikaInfo _$BikaInfoFromJson(Map<String, dynamic> json) => _BikaInfo(
  authorization: json['authorization'] as String,
  proxy: json['proxy'] as String,
);

Map<String, dynamic> _$BikaInfoToJson(_BikaInfo instance) => <String, dynamic>{
  'authorization': instance.authorization,
  'proxy': instance.proxy,
};
