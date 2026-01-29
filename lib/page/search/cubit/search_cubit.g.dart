// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SearchStates _$SearchStatesFromJson(Map<String, dynamic> json) =>
    _SearchStates(
      comicChoice: (json['comic_choice'] as num?)?.toInt() ?? 0,
      searchKeyword: json['search_keyword'] as String? ?? "",
      sortBy: json['sort_by'] as String? ?? "",
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SearchStatesToJson(_SearchStates instance) =>
    <String, dynamic>{
      'comic_choice': instance.comicChoice,
      'search_keyword': instance.searchKeyword,
      'sort_by': instance.sortBy,
      'categories': instance.categories,
    };
