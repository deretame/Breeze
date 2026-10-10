import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/page/comic_info/models/unified_plugin_preview.dart';

part 'comic_preview_state.freezed.dart';

enum ComicPreviewStatus {
  initial,
  success,
  failure,
  loadingMore,
  getMoreFailure,
}

@freezed
abstract class ComicPreviewState with _$ComicPreviewState {
  const factory ComicPreviewState({
    @Default(ComicPreviewStatus.initial) ComicPreviewStatus status,
    @Default(<UnifiedPluginPreviewItem>[]) List<UnifiedPluginPreviewItem> items,
    @Default(0) int page,
    @Default(false) bool hasReachedMax,
    @Default(<String, dynamic>{}) Map<String, dynamic> pluginExtern,
    @Default('') String result,
  }) = _ComicPreviewState;
}
