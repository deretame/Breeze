import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/comic_read/controller/reader_volume_controller.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/widgets/layout/read_layout.dart';
import 'package:zephyr/page/comic_read/widgets/modes/read_mode_slot_builder.dart';
import 'package:zephyr/page/comic_read/widgets/modes/read_mode_transition_style.dart';
import 'package:zephyr/page/comic_read/widgets/modes/read_mode_utils.dart';
import 'package:zephyr/util/context/context_extensions.dart';

class ColumnModeWidget extends StatefulWidget {
  final List<ReadModeEntry> entries;
  final bool enableDoublePage;
  final bool isRtl;
  final String comicId;
  final ListObserverController observerController;
  final ScrollController scrollController;
  final String from;
  final ScrollPhysics? parentPhysics;
  final bool disableScroll;
  final ReaderVolumeController volumeController;
  final ValueChanged<bool> onUserScrollActiveChanged;
  final ValueChanged<int> onGlobalSlotChanged;
  final ValueChanged<int> onTransitionAction;

  const ColumnModeWidget({
    super.key,
    required this.entries,
    required this.enableDoublePage,
    required this.isRtl,
    required this.comicId,
    required this.observerController,
    required this.scrollController,
    required this.from,
    this.parentPhysics,
    this.disableScroll = false,
    required this.volumeController,
    required this.onUserScrollActiveChanged,
    required this.onGlobalSlotChanged,
    required this.onTransitionAction,
  });

  @override
  State<ColumnModeWidget> createState() => _ColumnModeWidgetState();
}

class _ColumnModeWidgetState extends State<ColumnModeWidget> {
  bool get _isDoublePage => widget.enableDoublePage;

  @override
  Widget build(BuildContext context) {
    final basePhysics = widget.parentPhysics != null
        ? widget.parentPhysics!.applyTo(const AlwaysScrollableScrollPhysics())
        : const AlwaysScrollableScrollPhysics();
    final physics = widget.disableScroll
        ? const NeverScrollableScrollPhysics()
        : basePhysics;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hideTop = context.select(
          (GlobalSettingCubit c) => !c.state.readSetting.comicReadTopContainer,
        );
        final mediaQuery = MediaQuery.of(context);
        final readSetting = context.select(
          (GlobalSettingCubit c) => c.state.readSetting,
        );
        final backgroundColor = readSetting.resolveReaderBackgroundColor(
          Theme.of(context).brightness,
        );
        final sidePaddingEnabled = readSetting.sidePaddingEnabled;
        final sidePaddingPercent = readSetting.sidePaddingPercent;
        final topInset = mediaQuery.padding.top > 0
            ? mediaQuery.padding.top
            : mediaQuery.viewPadding.top;
        final bottomInset = mediaQuery.padding.bottom > 0
            ? mediaQuery.padding.bottom
            : mediaQuery.viewPadding.bottom;

        final double topPadding = hideTop ? 0 : topInset;
        final double bottomPadding = bottomInset + 50;

        final containerWidth = constraints.maxWidth;
        final contentWidth = getConstrainedImageWidth(
          containerWidth: containerWidth,
          enableSidePadding: sidePaddingEnabled,
          sidePaddingPercent: sidePaddingPercent,
        );
        final viewportShortEdge = math.min(
          contentWidth,
          MediaQuery.of(context).size.height,
        );

        final doublePageSlots = _isDoublePage
            ? buildReadModeDoublePageSlots(
                widget.entries,
                insertLeadingBlank: readSetting.doublePageLeadingBlank,
              )
            : const <ReadModeDoublePageSlot>[];
        final slotCount = _isDoublePage
            ? doublePageSlots.length
            : widget.entries.length;

        final transitionStyle = ReadModeTransitionStyle.column(
          shortEdge: viewportShortEdge,
        );

        final listView = ListView.builder(
          padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
          physics: physics,
          itemCount: slotCount,
          itemBuilder: (ctx, index) => buildReadModeSlot(
            context: ctx,
            slotIndex: index,
            singleItem: _isDoublePage
                ? null
                : ReadModeSlotItem(
                    entryIndex: index,
                    entry: widget.entries[index],
                  ),
            doublePageSlot: _isDoublePage ? doublePageSlots[index] : null,
            axis: ReadModeAxis.column,
            containerWidth: containerWidth,
            contentWidth: contentWidth,
            backgroundColor: backgroundColor,
            isRtl: widget.isRtl,
            comicId: widget.comicId,
            from: widget.from,
            onTransitionAction: widget.onTransitionAction,
            transitionStyle: transitionStyle,
          ),
          scrollCacheExtent: ScrollCacheExtent.pixels(context.screenHeight * 2),
          controller: widget.scrollController,
        );

        // 维护"用户正在滚动"标记：仅由真实拖拽（dragDetails 非空）开始，
        // 直到松手后的惯性/回弹完全结束（ScrollEnd）才复位，供自动滚动让位。
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification &&
                notification.dragDetails != null) {
              widget.onUserScrollActiveChanged(true);
            } else if (notification is ScrollEndNotification) {
              widget.onUserScrollActiveChanged(false);
            }
            return false;
          },
          child: ListViewObserver(
            controller: widget.observerController,
            onObserve: (resultMap) {
              final all = resultMap.displayingChildIndexList;
              if (all.isEmpty) return;

              final int middleValue = all[all.length ~/ 2];
              if (slotCount <= 0) return;

              final clampedPageIndex = middleValue.clamp(0, slotCount - 1);
              widget.onGlobalSlotChanged(clampedPageIndex);

              final cubit = context.read<ReaderCubit>();
              if (cubit.state.currentSlot != clampedPageIndex) {
                cubit.updateCurrentSlot(clampedPageIndex);
              }

              if (cubit.state.isMenuVisible) {
                cubit.updateMenuVisible(visible: false);
                widget.volumeController.enableInterception();
              }
            },
            child: listView,
          ),
        );
      },
    );
  }
}
