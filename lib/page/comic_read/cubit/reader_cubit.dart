import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/comic_read/cubit/reader_state.dart';

class ReaderCubit extends Cubit<ReaderState> {
  ReaderCubit() : super(const ReaderState());

  // 切换菜单显隐
  void updateMenuVisible({bool? visible}) {
    emit(state.copyWith(isMenuVisible: visible ?? !state.isMenuVisible));
  }

  // 更新总页数
  void updateTotalSlots(int total) => emit(state.copyWith(totalSlots: total));

  // 更新页面索引（同步计算滑块值）
  void updatePageIndex(int index) {
    if (state.pageIndex == index) return;

    double newSliderValue = state.sliderValue;
    // 如果不是在拖动滑块，则根据页面自动同步滑块位置
    if (!state.isSliderRolling && state.totalSlots > 0) {
      final maxSlot = (state.totalSlots - 1).clamp(0, 999999);
      newSliderValue = (index - 2).clamp(0, maxSlot).toDouble();
    }

    emit(state.copyWith(pageIndex: index, sliderValue: newSliderValue));
  }

  // 滑块拖动逻辑
  void updateSliderChanged(double value) =>
      emit(state.copyWith(sliderValue: value));

  void updateSliderRolling(bool rolling) =>
      emit(state.copyWith(isSliderRolling: rolling));

  void updateIsComicRolling(bool rolling) =>
      emit(state.copyWith(isComicRolling: rolling));
}
