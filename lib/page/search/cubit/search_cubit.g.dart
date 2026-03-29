// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SearchStates _$SearchStatesFromJson(Map<String, dynamic> json) =>
    _SearchStates(
      from: $enumDecodeNullable(_$FromEnumMap, json['from']) ?? From.jm,
      searchKeyword: json['searchKeyword'] as String? ?? "",
      sortBy: (json['sortBy'] as num?)?.toInt() ?? 1,
      pluginExtern:
          json['pluginExtern'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );

Map<String, dynamic> _$SearchStatesToJson(_SearchStates instance) =>
    <String, dynamic>{
      'from': _$FromEnumMap[instance.from]!,
      'searchKeyword': instance.searchKeyword,
      'sortBy': instance.sortBy,
      'pluginExtern': instance.pluginExtern,
    };

const _$FromEnumMap = {
  From.bika: 'bika',
  From.jm: 'jm',
  From.unknown: 'unknown',
};
