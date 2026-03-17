import 'dart:async';
import 'dart:ui';

import 'package:zephyr/util/ui/fluent_compat.dart';
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
  int? _lastHapticStep;

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
    final readSetting = context.select<GlobalSettingCubit, ReadSettingState>(
      (cubit) => cubit.state.readSetting,
    );
    final sliderValue = context.select(
      (ReaderCubit cubit) => cubit.state.sliderValue,
    );
    maxValue = totalSlots > 0 ? totalSlots.toDouble() - 1 : 0;
    final safeSliderValue = sliderValue.clamp(0.0, maxValue).toDouble();

    final sliderDisplayPage = getDisplayPageNumber(
      slotIndex: safeSliderValue.round(),
      enableDoublePage: readSetting.doublePageMode,
    );

    if (safeSliderValue != sliderValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        cubit.updateSliderChanged(safeSliderValue);
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
                max: maxValue,
                divisions: maxValue > 0 ? maxValue.toInt() : null,
                label: sliderDisplayPage.toString(),
                onChangeStart: (value) {
                  _lastHapticStep = value.round();
                },
                onChanged: (double newValue) {
                  final currentStep = newValue.round();
                  if (_lastHapticStep != currentStep) {
                    HapticFeedback.selectionClick();
                    _lastHapticStep = currentStep;
                  }

                  if (sliderValue != newValue) {
                    cubit.updateSliderChanged(newValue);
                  }

                  cubit.updateIsComicRolling(true);
                  _sliderIsRollingTimer?.cancel();

                  final displayPage = getDisplayPageNumber(
                    slotIndex: newValue.round(),
                    enableDoublePage: readSetting.doublePageMode,
                  );
                  _showOverlayToast(displayPage.toString());

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
                        if (globalSettingState.readMode == 0) {
                          widget.observerController.jumpTo(
                            index: newValue.toInt(),
                            offset: (offset) {
                              return MediaQuery.of(context).padding.top + 5.0;
                            },
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


