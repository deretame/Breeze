import 'package:freezed_annotation/freezed_annotation.dart';

part 'reader_state.freezed.dart';

@freezed
abstract class ReaderState with _$ReaderState {
  const factory ReaderState({
    @Default(0) int pageIndex, // 当前页码
    @Default(0) int totalSlots, // 总页数/槽位数
    @Default(true) bool isMenuVisible, // 菜单显隐
    @Default(0.0) double sliderValue, // 滑块进度
    @Default(false) bool isSliderRolling, // 是否正在拖动滑块
  }) = _ReaderState;
}
