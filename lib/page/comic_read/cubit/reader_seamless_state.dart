import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/page/comic_read/model/seamless_transition_state.dart';

part 'reader_seamless_state.freezed.dart';

/// 半无缝拼接中已加载的章节数据。
class SeamlessChapter {
  const SeamlessChapter({required this.order, required this.epInfo});

  final int order;
  final NormalComicEpInfo epInfo;
}

/// 半无缝章节拼接状态。
///
/// 该状态只包含 UI 需要监听的数据；章节目录等纯内部数据留在 Cubit 中。
@freezed
abstract class ReaderSeamlessState with _$ReaderSeamlessState {
  const factory ReaderSeamlessState({
    @Default(<SeamlessChapter>[]) List<SeamlessChapter> loadedChapters,
    @Default(<int, SeamlessTransitionStatus>{})
    Map<int, SeamlessTransitionStatus> transitionStatusByNextOrder,
    @Default(<int>{}) Set<int> visibleTransitionNextOrders,
    @Default(<int>{}) Set<int> loadingChapterOrders,
    @Default(<int>{}) Set<int> prefetchingChapterOrders,
    @Default(<int, NormalComicEpInfo>{})
    Map<int, NormalComicEpInfo> prefetchedChapterInfoByOrder,
    int? currentChapterOrder,
    @Default(0) int currentChapterStartSlot,
    @Default(0) int currentChapterSlotCount,
  }) = _ReaderSeamlessState;
}
