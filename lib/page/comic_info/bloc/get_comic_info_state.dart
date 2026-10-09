import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';

part 'get_comic_info_state.freezed.dart';

enum GetComicInfoStatus { initial, success, failure }

@freezed
abstract class GetComicInfoState with _$GetComicInfoState {
  const factory GetComicInfoState({
    @Default(GetComicInfoStatus.initial) GetComicInfoStatus status,
    NormalComicAllInfo? allInfo,
    // 用来存储漫画的原本的信息
    dynamic comicInfo,
    String? comicId,
    @Default('') String result,
  }) = _GetComicInfoState;
}
