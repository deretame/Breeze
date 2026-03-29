part of 'search_bloc.dart';

@freezed
abstract class SearchEvent with _$SearchEvent {
  const factory SearchEvent({
    @Default(SearchStatus.initial) SearchStatus status,
    @Default(SearchStates()) SearchStates searchStates,
    @Default(1) int page,
  }) = _SearchEvent;

  factory SearchEvent.fromJson(Map<String, dynamic> json) =>
      _$SearchEventFromJson(json);
}
