// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_bloc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SearchEvent _$SearchEventFromJson(Map<String, dynamic> json) => _SearchEvent(
  status:
      $enumDecodeNullable(_$SearchStatusEnumMap, json['status']) ??
      SearchStatus.initial,
  searchStates: json['searchStates'] == null
      ? const SearchStates()
      : SearchStates.fromJson(json['searchStates'] as Map<String, dynamic>),
  page: (json['page'] as num?)?.toInt() ?? 1,
  url: json['url'] as String? ?? '',
);

Map<String, dynamic> _$SearchEventToJson(_SearchEvent instance) =>
    <String, dynamic>{
      'status': _$SearchStatusEnumMap[instance.status]!,
      'searchStates': instance.searchStates,
      'page': instance.page,
      'url': instance.url,
    };

const _$SearchStatusEnumMap = {
  SearchStatus.initial: 'initial',
  SearchStatus.success: 'success',
  SearchStatus.failure: 'failure',
  SearchStatus.loadingMore: 'loadingMore',
  SearchStatus.getMoreFailure: 'getMoreFailure',
};

_SearchState _$SearchStateFromJson(Map<String, dynamic> json) => _SearchState(
  status:
      $enumDecodeNullable(_$SearchStatusEnumMap, json['status']) ??
      SearchStatus.initial,
  comics:
      (json['comics'] as List<dynamic>?)
          ?.map((e) => ComicNumber.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  hasReachedMax: json['hasReachedMax'] as bool? ?? false,
  result: json['result'] as String? ?? '',
  searchEvent: json['searchEvent'] == null
      ? const SearchEvent()
      : SearchEvent.fromJson(json['searchEvent'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SearchStateToJson(_SearchState instance) =>
    <String, dynamic>{
      'status': _$SearchStatusEnumMap[instance.status]!,
      'comics': instance.comics,
      'hasReachedMax': instance.hasReachedMax,
      'result': instance.result,
      'searchEvent': instance.searchEvent,
    };
