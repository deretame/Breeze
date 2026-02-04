part of 'search_cubit.dart';

@freezed
abstract class SearchStates with _$SearchStates {
  const factory SearchStates({
    @Default(From.jm) From from,
    @Default("") String searchKeyword,
    @Default(1) int sortBy,
    @Default({}) Map<String, bool> categories,
    @Default({}) Map<String, bool> categoriesBlock,
    @Default(false) bool brevity, // 精简列表还是详细列表，仅针对哔咔
  }) = _SearchStates;

  factory SearchStates.initial(
    BuildContext context, {
    Map<String, bool>? category,
  }) {
    final bikaSettingCubitState = context.read<BikaSettingCubit>().state;

    return SearchStates().copyWith(
      categories: category ?? Map.of(categoryMap),
      categoriesBlock: Map.of(bikaSettingCubitState.shieldCategoryMap),
      brevity: bikaSettingCubitState.brevity,
    );
  }

  factory SearchStates.fromJson(Map<String, dynamic> json) =>
      _$SearchStatesFromJson(json);
}
