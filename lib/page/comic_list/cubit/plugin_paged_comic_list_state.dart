import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/widgets/comic_entry/models/models.dart';

part 'plugin_paged_comic_list_state.freezed.dart';

enum PluginPagedComicListStatus {
  initial,
  success,
  failure,
  loadingMore,
  loadingMoreFailure,
}

@freezed
abstract class PluginPagedComicListState with _$PluginPagedComicListState {
  const factory PluginPagedComicListState({
    @Default(PluginPagedComicListStatus.initial)
    PluginPagedComicListStatus status,
    @Default(<UnifiedComicListItem>[]) List<UnifiedComicListItem> list,
    @Default(false) bool hasReachedMax,
    @Default(1) int page,
    @Default('') String result,
  }) = _PluginPagedComicListState;
}
