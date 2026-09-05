import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/comic_read/cubit/reader_state.dart';

class ReaderCubit extends Cubit<ReaderState> {
  ReaderCubit() : super(const ReaderState());

  // 切换菜单显隐
  void updateMenuVisible({bool? visible}) {
    final nextVisible = visible ?? !state.isMenuVisible;
    if (state.isMenuVisible == nextVisible) return;
    emit(state.copyWith(isMenuVisible: nextVisible));
  }

  // 更新总页数
  void updateTotalSlots(int total) {
    if (state.totalSlots == total) return;
    emit(state.copyWith(totalSlots: total));
  }

  // 更新当前全局槽位（同步计算滑块值）
  void updateCurrentSlot(int index) {
    if (state.currentSlot == index) return;

    double newSliderValue = state.sliderValue;
    // 如果不是在拖动滑块，则根据槽位自动同步滑块位置
    if (!state.isSliderRolling && state.totalSlots > 0) {
      final maxIndex = (state.totalSlots - 1).clamp(0, 999999);
      newSliderValue = index.clamp(0, maxIndex).toDouble();
    }

    emit(state.copyWith(currentSlot: index, sliderValue: newSliderValue));
  }

  // 滑块拖动逻辑
  void updateSliderChanged(double value) {
    if (state.sliderValue == value) return;
    emit(state.copyWith(sliderValue: value));
  }

  void updateSliderRolling(bool rolling) {
    if (state.isSliderRolling == rolling) return;
    emit(state.copyWith(isSliderRolling: rolling));
  }

  void updateIsComicRolling(bool rolling) {
    if (state.isComicRolling == rolling) return;
    emit(state.copyWith(isComicRolling: rolling));
  }
}
