import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';

part 'page_state.freezed.dart';

enum PageStatus { initial, success, failure }

@freezed
abstract class PageState with _$PageState {
  const factory PageState({
    @Default(PageStatus.initial) PageStatus status,
    NormalComicEpInfo? epInfo,
    @Default('') String errorMessage,
  }) = _PageState;
}
