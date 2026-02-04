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

_Bika _$BikaFromJson(Map<String, dynamic> json) => _Bika(
  Doc.fromJson(json['comics'] as Map<String, dynamic>),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$BikaToJson(_Bika instance) => <String, dynamic>{
  'comics': instance.comics,
  'runtimeType': instance.$type,
};

_Jm _$JmFromJson(Map<String, dynamic> json) => _Jm(
  Content.fromJson(json['comics'] as Map<String, dynamic>),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$JmToJson(_Jm instance) => <String, dynamic>{
  'comics': instance.comics,
  'runtimeType': instance.$type,
};
