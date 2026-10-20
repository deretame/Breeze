import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/page/comic_list/models/comic_list_scene.dart';
import 'package:zephyr/page/comic_list/models/list_filter_bundle.dart';

part 'comic_list_state.freezed.dart';

@freezed
abstract class ComicListState with _$ComicListState {
  const ComicListState._();

  const factory ComicListState({
    @Default('') String currentFrom,
    ComicListScene? scene,
    @Default(false) bool sceneLoading,
    String? sceneError,
    // scene/filter 请求的登录错误插件 uuid（空 = 非登录错误）。
    // 只有新两页传 suppressNeedLoginEvent=true 才会有值，其他页走全局弹窗。
    @Default('') String sceneLoginPluginId,
    @Default(false) bool filterLoading,
    String? filterError,
    @Default('') String filterLoginPluginId,
    ListFilterBundle? filterBundle,
    @Default({}) Map<String, String> filterSelections,
    @Default({}) Map<String, dynamic> resolvedUiParams,
    @Default({}) Map<String, dynamic> resolvedFilterCore,
    @Default({}) Map<String, dynamic> resolvedFilterExtern,
  }) = _ComicListState;

  bool get requiresFilter => scene?.filter != null;
  bool get hasResolvedFilter => filterBundle != null;
}
