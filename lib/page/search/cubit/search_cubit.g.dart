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
      categories:
          (json['categories'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as bool),
          ) ??
          const {},
      categoriesBlock:
          (json['categoriesBlock'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as bool),
          ) ??
          const {},
      readModel: (json['readModel'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$SearchStatesToJson(_SearchStates instance) =>
    <String, dynamic>{
      'from': _$FromEnumMap[instance.from]!,
      'searchKeyword': instance.searchKeyword,
      'sortBy': instance.sortBy,
      'categories': instance.categories,
      'categoriesBlock': instance.categoriesBlock,
      'readModel': instance.readModel,
    };

const _$FromEnumMap = {From.bika: 'bika', From.jm: 'jm'};
