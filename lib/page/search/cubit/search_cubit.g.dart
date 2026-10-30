// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SearchStates _$SearchStatesFromJson(Map<String, dynamic> json) =>
    _SearchStates(
      from: json['from'] as String? ?? '',
      searchKeyword: json['searchKeyword'] as String? ?? "",
      pluginExtern:
          json['pluginExtern'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
      aggregateSources:
          (json['aggregateSources'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as bool),
          ) ??
          const <String, bool>{},
      isSearchAggregate: json['isSearchAggregate'] as bool? ?? false,
    );

Map<String, dynamic> _$SearchStatesToJson(_SearchStates instance) =>
    <String, dynamic>{
      'from': instance.from,
      'searchKeyword': instance.searchKeyword,
      'pluginExtern': instance.pluginExtern,
      'aggregateSources': instance.aggregateSources,
    };
