// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SearchStates _$SearchStatesFromJson(Map<String, dynamic> json) =>
    _SearchStates(
      from: json['from'] as String? ?? '',
      searchKeyword: json['searchKeyword'] as String? ?? "",
      sortBy: (json['sortBy'] as num?)?.toInt() ?? 1,
      pluginExtern:
          json['pluginExtern'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );

Map<String, dynamic> _$SearchStatesToJson(_SearchStates instance) =>
    <String, dynamic>{
      'from': instance.from,
      'searchKeyword': instance.searchKeyword,
      'sortBy': instance.sortBy,
      'pluginExtern': instance.pluginExtern,
    };
