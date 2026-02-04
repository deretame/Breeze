part of 'search_cubit.dart';

@freezed
abstract class SearchStates with _$SearchStates {
  const factory SearchStates({
    @Default(From.jm) From from,
    @Default("") String searchKeyword,
    @Default(1) int sortBy,
    @Default({}) Map<String, bool> categories,
    @Default({}) Map<String, bool> categoriesBlock,
    @Default(1) int readModel, // 精简列表还是详细列表，仅针对哔咔
  }) = _SearchStates;

  factory SearchStates.fromJson(Map<String, dynamic> json) =>
      _$SearchStatesFromJson(json);
}
