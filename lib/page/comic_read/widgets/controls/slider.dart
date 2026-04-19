import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/comic_read/cubit/image_size_cubit.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/widgets/layout/read_layout.dart';
import 'package:zephyr/util/context/context_extensions.dart';

import 'package:zephyr/main.dart';

class SliderWidget extends StatefulWidget {
  final ListObserverController observerController;
  final PageController pageController;
  final int Function()? getCurrentChapterSlotCount;
  final int Function(int globalSlot)? mapGlobalToLocalSlot;
  final int Function(int localSlot)? mapLocalToGlobalSlot;
  final bool Function(int globalSlot)? isTransitionSlot;
  final String transitionLabel;

  const SliderWidget({
    super.key,
    required this.observerController,
    required this.pageController,
    this.getCurrentChapterSlotCount,
    this.mapGlobalToLocalSlot,
    this.mapLocalToGlobalSlot,
    this.isTransitionSlot,
    this.transitionLabel = '章节过渡中',
  });

  @override
  State<SliderWidget> createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget> {
  Timer? _sliderIsRollingTimer; // 用来控制滚动隐藏组件的操作
  Timer? _comicRollingTimer; // 漫画本身是否在滚动
  Timer? _secondCorrectionTimer; // 滑块跳转后延迟二次校正
  OverlayEntry? _overlayEntry; // 用于存储 OverlayEntry
  int? _lastHapticStep;

  @override
  void dispose() {
    _sliderIsRollingTimer?.cancel();
    _comicRollingTimer?.cancel();
    _secondCorrectionTimer?.cancel();
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReaderCubit>();
    final totalSlots = context.select(
      (ReaderCubit cubit) => cubit.state.totalSlots,
    );
    final readSetting = context.select<GlobalSettingCubit, ReadSettingState>(
      (cubit) => cubit.state.readSetting,
    );
    final sliderValue = context.select(
      (ReaderCubit cubit) => cubit.state.sliderValue,
    );
    final globalMaxValue = totalSlots > 0 ? totalSlots.toDouble() - 1 : 0;
    final safeGlobalSliderValue = sliderValue
        .clamp(0.0, globalMaxValue)
        .toDouble();
    final currentChapterSlotCount =
        widget.getCurrentChapterSlotCount?.call() ?? totalSlots;
    final localMaxValue = currentChapterSlotCount > 0
        ? currentChapterSlotCount.toDouble() - 1
        : 0.0;
    final mappedLocalSliderValue =
        widget.mapGlobalToLocalSlot?.call(safeGlobalSliderValue.round()) ??
        safeGlobalSliderValue.round();
    final safeSliderValue = mappedLocalSliderValue.toDouble().clamp(
      0.0,
      localMaxValue,
    );

    final sliderDisplayPage = getDisplayPageNumber(
      slotIndex: safeSliderValue.round(),
      enableDoublePage: readSetting.doublePageMode,
    );
    final currentGlobalSlot = safeGlobalSliderValue.round();
    final isCurrentTransitionSlot =
        widget.isTransitionSlot?.call(currentGlobalSlot) ?? false;
    final sliderLabelText = isCurrentTransitionSlot
        ? widget.transitionLabel
        : sliderDisplayPage.toString();

    if (safeGlobalSliderValue != sliderValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        cubit.updateSliderChanged(safeGlobalSliderValue);
      });
    }

    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: context.theme.colorScheme.surfaceContainerHigh.withValues(
                alpha: 0.9,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: context.theme.colorScheme.outlineVariant.withValues(
                  alpha: 0.35,
                ),
              ),
            ),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: context.theme.colorScheme.primary,
                inactiveTrackColor: context.theme.colorScheme.primary
                    .withValues(alpha: 0.22),
                thumbColor: context.theme.colorScheme.primary,
                overlayColor: context.theme.colorScheme.primary.withValues(
                  alpha: 0.16,
                ),
                showValueIndicator: ShowValueIndicator.never,
              ),
              child: Slider(
                value: safeSliderValue,
                min: 0,
                max: localMaxValue,
                divisions: localMaxValue > 0 ? localMaxValue.toInt() : null,
                label: sliderLabelText,
                onChangeStart: (value) {
                  _lastHapticStep = value.round();
                },
                onChanged: (double newValue) {
                  final clampedLocalValue = newValue.clamp(0.0, localMaxValue);
                  final currentStep = clampedLocalValue.round();
                  final targetGlobalSlot =
                      widget.mapLocalToGlobalSlot?.call(currentStep) ??
                      currentStep;
                  final targetGlobalValue = targetGlobalSlot.toDouble();
                  if (_lastHapticStep != currentStep) {
                    HapticFeedback.selectionClick();
                    _lastHapticStep = currentStep;
                  }

                  if (sliderValue != targetGlobalValue) {
                    cubit.updateSliderChanged(targetGlobalValue);
                  }

                  cubit.updateIsComicRolling(true);
                  _sliderIsRollingTimer?.cancel();

                  final displayPage = getDisplayPageNumber(
                    slotIndex: currentStep,
                    enableDoublePage: readSetting.doublePageMode,
                  );
                  final toastMessage =
                      widget.isTransitionSlot?.call(targetGlobalSlot) ?? false
                      ? widget.transitionLabel
                      : displayPage.toString();
                  _showOverlayToast(toastMessage);

                  _sliderIsRollingTimer = Timer(
                    const Duration(milliseconds: 300),
                    () {
                      cubit.updateSliderRolling(true);
                      cubit.updateIsComicRolling(true);
                      _comicRollingTimer = Timer(
                        const Duration(milliseconds: 350),
                        () {
                          cubit.updateSliderRolling(false);
                          cubit.updateIsComicRolling(false);
                          _overlayEntry?.remove();
                          _overlayEntry = null;
                        },
                      );

                      final globalSettingState = context
                          .read<GlobalSettingCubit>()
                          .state;

                      try {
                        if (globalSettingState.readSetting.readMode == 0) {
                          _jumpColumnWithSecondCorrection(targetGlobalSlot);
                        } else {
                          widget.pageController.animateToPage(
                            targetGlobalSlot,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      } catch (e) {
                        logger.e(e);
                      }
                    },
                  );
                },
                onChangeEnd: (_) {
                  _lastHapticStep = null;
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showOverlayToast(String message) {
    final isNumeric = int.tryParse(message) != null;
    final fontSize = isNumeric ? 60.0 : 34.0;
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
                          fontSize: fontSize,
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

  void _jumpColumnWithSecondCorrection(int targetGlobalSlot) {
    void jumpNow() {
      widget.observerController.jumpTo(
        index: targetGlobalSlot,
        offset: (offset) => MediaQuery.of(context).padding.top + 5.0,
      );
    }

    jumpNow();
    _secondCorrectionTimer?.cancel();
    _secondCorrectionTimer = Timer(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      final readMode = context
          .read<GlobalSettingCubit>()
          .state
          .readSetting
          .readMode;
      if (readMode != 0) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          jumpNow();
        } catch (e) {
          logger.e(e);
        }
      });
    });
  }
}

double getOffset(BuildContext context, int index, {double? imageWidth}) {
  final sizeCubit = context.read<ImageSizeCubit>();

  final targetListIndex = index;

  double targetItemStartY = 0;
  for (int i = 0; i < targetListIndex; i++) {
    final cachedSize = sizeCubit.state.getSizeValue(i);
    if (imageWidth != null &&
        cachedSize.width > 0 &&
        cachedSize.height > 0 &&
        (cachedSize.width - imageWidth).abs() >= 0.1) {
      final aspectRatio = cachedSize.height / cachedSize.width;
      targetItemStartY += imageWidth * aspectRatio;
    } else {
      targetItemStartY += cachedSize.height;
    }
  }

  double finalOffset = targetItemStartY - context.statusBarHeight;
  if (finalOffset < 0) {
    finalOffset = 0;
  }

  return finalOffset;
}
