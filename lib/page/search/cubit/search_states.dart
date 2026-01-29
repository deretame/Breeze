part of 'search_cubit.dart';

@freezed
abstract class SearchStates with _$SearchStates {
  const factory SearchStates({
    @Default(0) @JsonKey(name: "comic_choice") int comicChoice,
    @Default("") @JsonKey(name: "search_keyword") String searchKeyword,
    @Default("") @JsonKey(name: "sort_by") String sortBy,
    @Default([]) @JsonKey(name: "categories") List<String> categories,
  }) = _SearchStates;

  factory SearchStates.fromJson(Map<String, dynamic> json) =>
      _$SearchStatesFromJson(json);
}
