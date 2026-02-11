import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/comic_read/cubit/image_size_cubit.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/util/context/context_extensions.dart';

import '../../../main.dart';

class SliderWidget extends StatefulWidget {
  final ListObserverController observerController;
  final PageController pageController;

  const SliderWidget({
    super.key,
    required this.observerController,
    required this.pageController,
  });

  @override
  State<SliderWidget> createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget> {
  Timer? _sliderIsRollingTimer; // 用来控制滚动隐藏组件的操作
  Timer? _comicRollingTimer; // 漫画本身是否在滚动
  OverlayEntry? _overlayEntry; // 用于存储 OverlayEntry
  int displayedSlot = 1; // 显示的当前槽位

  @override
  void dispose() {
    _sliderIsRollingTimer?.cancel();
    _comicRollingTimer?.cancel();
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double maxValue = 0;
    final cubit = context.read<ReaderCubit>();
    final totalSlots = context.select(
      (ReaderCubit cubit) => cubit.state.totalSlots,
    );
    final sliderValue = context.select(
      (ReaderCubit cubit) => cubit.state.sliderValue,
    );
    maxValue = totalSlots > 0 ? totalSlots.toDouble() - 1 : 0;
    return Expanded(
      child: Slider(
        value: sliderValue,
        min: 0,
        max: maxValue,
        label: (sliderValue.toInt() + 1).toString(),
        onChanged: (double newValue) {
          if (sliderValue.toInt() != newValue.toInt()) {
            cubit.updateSliderChanged(newValue);
          }

          cubit.updateIsComicRolling(true);
          _sliderIsRollingTimer?.cancel();

          // 显示 Overlay 提示框
          _showOverlayToast((newValue.toInt() + 1).toString());

          // 设置新的定时器以防止多次触发
          _sliderIsRollingTimer = Timer(const Duration(milliseconds: 300), () {
            displayedSlot = newValue.toInt() + 1;

            cubit.updateSliderRolling(true);
            cubit.updateIsComicRolling(true);
            _comicRollingTimer = Timer(const Duration(milliseconds: 350), () {
              cubit.updateSliderRolling(false);
              cubit.updateIsComicRolling(false);

              // 移除 Overlay 提示框
              _overlayEntry?.remove();
              _overlayEntry = null;
            });

            final globalSettingState = context.read<GlobalSettingCubit>().state;

            try {
              // 滚动到指定的索引
              if (globalSettingState.readMode == 0) {
                widget.observerController.controller?.animateTo(
                  getOffset(context, newValue.toInt()),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                widget.pageController.animateToPage(
                  newValue.toInt(),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            } catch (e) {
              logger.e(e);
            }
          });
        },
      ),
    );
  }

  void _showOverlayToast(String message) {
    // 移除之前的 Overlay
    _overlayEntry?.remove();

    // 创建新的 OverlayEntry
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // 提示信息
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 48.0,
                      vertical: 24.0,
                    ),
                    decoration: BoxDecoration(
                      color: context.theme.colorScheme.surfaceBright.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: RichText(
                      text: TextSpan(
                        text: message,
                        style: TextStyle(
                          fontSize: 60,
                          color: context.textColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    // 插入 Overlay
    Overlay.of(context).insert(_overlayEntry!);
  }
}

double getOffset(BuildContext context, int index) {
  final sizeCubit = context.read<ImageSizeCubit>();

  final targetListIndex = index + 1;

  double targetItemStartY = 0;
  for (int i = 0; i < targetListIndex; i++) {
    targetItemStartY += sizeCubit.state.getSizeValue(i).height;
  }

  double finalOffset = targetItemStartY - context.statusBarHeight;
  if (finalOffset < 0) {
    finalOffset = 0;
  }

  return finalOffset;
}
