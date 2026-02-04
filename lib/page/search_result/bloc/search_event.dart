part of 'search_bloc.dart';

@freezed
abstract class SearchEvent with _$SearchEvent {
  const factory SearchEvent({
    @Default(SearchStatus.initial) SearchStatus status,
    @Default(SearchStates()) SearchStates searchStates,
    @Default(1) int page,
    @Default('') String url, // 用来应对哔咔的部分特殊情况，部分情况下哔咔是直接用url搜索的
  }) = _SearchEvent;

  factory SearchEvent.fromJson(Map<String, dynamic> json) =>
      _$SearchEventFromJson(json);
}
