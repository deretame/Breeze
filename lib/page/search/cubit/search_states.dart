part of 'search_cubit.dart';

@freezed
abstract class SearchStates with _$SearchStates {
  const factory SearchStates({
    @Default('') String from,
    @Default("") String searchKeyword,
    @Default(<String, dynamic>{}) Map<String, dynamic> pluginExtern,
    @Default(<String, bool>{}) Map<String, bool> aggregateSources,
    // 书签跳转回放：只在跳转这一次请求里为 true，随 core.isSearchAggregate 发给插件；
    // 成功后 bloc 复位为 false，后续翻页走正常逻辑。json 持久化忽略。
    @Default(false) @JsonKey(includeToJson: false) bool isSearchAggregate,
  }) = _SearchStates;

  factory SearchStates.initial() => const SearchStates();

  factory SearchStates.fromJson(Map<String, dynamic> json) =>
      _$SearchStatesFromJson(json);
}
