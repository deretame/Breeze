// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comic_number.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ComicNumber _$ComicNumberFromJson(Map<String, dynamic> json) => _ComicNumber(
  buildNumber: (json['buildNumber'] as num).toInt(),
  comicInfo: ComicInfo.fromJson(json['comicInfo'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ComicNumberToJson(_ComicNumber instance) =>
    <String, dynamic>{
      'buildNumber': instance.buildNumber,
      'comicInfo': instance.comicInfo,
    };

Bika _$BikaFromJson(Map<String, dynamic> json) => Bika(
  Doc.fromJson(json['comics'] as Map<String, dynamic>),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$BikaToJson(Bika instance) => <String, dynamic>{
  'comics': instance.comics,
  'runtimeType': instance.$type,
};

Jm _$JmFromJson(Map<String, dynamic> json) => Jm(
  Content.fromJson(json['comics'] as Map<String, dynamic>),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$JmToJson(Jm instance) => <String, dynamic>{
  'comics': instance.comics,
  'runtimeType': instance.$type,
};
