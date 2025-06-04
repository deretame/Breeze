part of 'suggestion_bloc.dart';

@freezed
class SuggestionEvent with _$SuggestionEvent {
  const factory SuggestionEvent.started() = _Started;
}
