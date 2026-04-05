part of 'search_cubit.dart';

@freezed
abstract class SearchStates with _$SearchStates {
  const factory SearchStates({
    @Default('') String from,
    @Default("") String searchKeyword,
    @Default(1) int sortBy,
    @Default(<String, dynamic>{}) Map<String, dynamic> pluginExtern,
  }) = _SearchStates;

  factory SearchStates.initial() => const SearchStates();

  factory SearchStates.fromJson(Map<String, dynamic> json) =>
      _$SearchStatesFromJson(json);
}
