import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/util/context/context_extensions.dart';

import '../../../main.dart';

class SliderWidget extends StatefulWidget {
  final int totalSlots;
  final double currentSliderValue;
  final ValueChanged<double> changeSliderValue;
  final ValueChanged<bool> changeSliderRollState;
  final ValueChanged<bool> changeComicRollState;
  final ItemScrollController itemScrollController;
  final PageController pageController;

  const SliderWidget({
    super.key,
    required this.totalSlots,
    required this.changeSliderValue,
    required this.currentSliderValue,
    required this.changeSliderRollState,
    required this.changeComicRollState,
    required this.itemScrollController,
    required this.pageController,
  });

  @override
  State<SliderWidget> createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget> {
  double get currentSliderValue => widget.currentSliderValue;

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
    maxValue = widget.totalSlots > 0 ? widget.totalSlots.toDouble() - 1 : 0;
    return Expanded(
      child: Slider(
        value: currentSliderValue,
        min: 0,
        max: maxValue,
        label: (currentSliderValue.toInt() + 1).toString(),
        onChanged: (double newValue) {
          if (currentSliderValue.toInt() != newValue.toInt()) {
            widget.changeSliderValue(newValue);
          }

          widget.changeSliderRollState(true);
          _sliderIsRollingTimer?.cancel();

          // 显示 Overlay 提示框
          _showOverlayToast((newValue.toInt() + 1).toString());

          // 设置新的定时器以防止多次触发
          _sliderIsRollingTimer = Timer(const Duration(milliseconds: 300), () {
            displayedSlot = newValue.toInt() + 1;

            widget.changeComicRollState(true);
            widget.changeSliderRollState(true);
            _comicRollingTimer = Timer(const Duration(milliseconds: 350), () {
              widget.changeComicRollState(false);
              widget.changeSliderRollState(false);

              // 移除 Overlay 提示框
              _overlayEntry?.remove();
              _overlayEntry = null;
            });

            final globalSettingState = context.read<GlobalSettingCubit>().state;

            // 滚动到指定的索引
            if (globalSettingState.readMode == 0) {
              widget.itemScrollController.scrollTo(
                index: currentSliderValue.toInt() + 1,
                alignment: 0.0,
                duration: const Duration(milliseconds: 300),
              );
            } else {
              widget.pageController.animateToPage(
                currentSliderValue.toInt(),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }

            logger.d('滑块值：$newValue , 显示的槽位：$displayedSlot');
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
