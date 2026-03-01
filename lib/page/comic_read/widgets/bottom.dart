import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/comic_info.dart';
import 'package:zephyr/page/comic_info/json/jm/jm_comic_info_json.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/method/jump_chapter.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';

import '../../../main.dart';
import '../../../type/enum.dart';
import '../../../util/router/router.dart';
import '../../../util/router/router.gr.dart';
import 'reader_settings_sheet.dart';

class BottomWidget extends StatefulWidget {
  final ComicEntryType type;
  final dynamic comicInfo;
  final Widget sliderWidget;
  final int order;
  final int epsNumber;
  final String comicId;
  final From from;
  final JumpChapter jumpChapter;

  const BottomWidget({
    super.key,
    required this.type,
    required this.comicInfo,
    required this.sliderWidget,
    required this.order,
    required this.epsNumber,
    required this.comicId,
    required this.from,
    required this.jumpChapter,
  });

  @override
  State<BottomWidget> createState() => _BottomWidgetState();
}

class _BottomWidgetState extends State<BottomWidget> {
  bool get isDownload =>
      widget.type == ComicEntryType.download ||
      widget.type == ComicEntryType.historyAndDownload;

  JumpChapter get jumpChapter => widget.jumpChapter;

  final Duration _animationDuration = const Duration(milliseconds: 300); // 动画时长

  late ComicEntryType tempType;
  late String comicId;
  List<Series> seriesList = [];

  @override
  void initState() {
    super.initState();

    tempType = widget.type;
    comicId = widget.comicId;
    if (tempType == ComicEntryType.historyAndDownload) {
      tempType = ComicEntryType.download;
    }
    if (tempType == ComicEntryType.history) {
      tempType = ComicEntryType.normal;
    }
    if (widget.from == From.jm) {
      seriesList = (widget.comicInfo as JmComicInfoJson).series;
      if (isDownload) {
        final epsIds = objectbox.jmDownloadBox
            .query(JmDownload_.comicId.equals(comicId))
            .build()
            .findFirst()!
            .epsIds;
        seriesList = seriesList.toList()
          ..removeWhere((series) => !epsIds.contains(series.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMenuVisible = context.select(
      (ReaderCubit cubit) => cubit.state.isMenuVisible,
    );
    final colorScheme = context.theme.colorScheme;
    final bottomSafeHeight = context.bottomSafeHeight;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !isMenuVisible,
        child: AnimatedSlide(
          duration: _animationDuration,
          curve: Curves.easeOutCubic,
          offset: isMenuVisible ? Offset.zero : const Offset(0, 1),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: context.screenWidth,
                padding: EdgeInsets.fromLTRB(10, 6, 10, 6 + bottomSafeHeight),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.76),
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        ChapterNavigationButton(
                          label: "上一章",
                          isEnabled: jumpChapter.havePrev,
                          onTap: () => _jumpToChapter(true),
                        ),
                        const SizedBox(width: 6),
                        widget.sliderWidget,
                        const SizedBox(width: 6),
                        ChapterNavigationButton(
                          label: "下一章",
                          isEnabled: jumpChapter.haveNext,
                          onTap: () => _jumpToChapter(false),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Divider(
                        height: 1,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: '返回首页',
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.secondaryContainer
                                .withValues(alpha: 0.7),
                          ),
                          icon: const Icon(Icons.home_rounded),
                          onPressed: () => popToRoot(context),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed:
                                seriesList.isEmpty && widget.from == From.jm
                                ? null
                                : _selectJumpChapter,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(40),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('跳转章节'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          tooltip: '阅读设置',
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.secondaryContainer
                                .withValues(alpha: 0.7),
                          ),
                          icon: const Icon(Icons.tune_rounded),
                          onPressed: _openSettingsPanel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openSettingsPanel() {
    final readerCubit = context.read<ReaderCubit>();
    showReaderSettingsSheet(
      context,
      changePageIndex: (int value) {
        readerCubit.updatePageIndex(value);
        readerCubit.updateSliderChanged(0.0);
      },
    );
  }

  Future<bool> _bottomButtonDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // 不允许点击外部区域关闭对话框
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                TextButton(
                  child: Text('取消'),
                  onPressed: () {
                    Navigator.of(context).pop(false); // 返回 false
                  },
                ),
                TextButton(
                  child: Text('确定'),
                  onPressed: () {
                    Navigator.of(context).pop(true); // 返回 true
                  },
                ),
              ],
            );
          },
        ) ??
        false; // 处理返回值为空的情况
  }

  Future<void> _jumpToChapter(bool isPrev) async {
    final dialogMessage = isPrev ? '上一章' : '下一章';
    final result = await _bottomButtonDialog(
      context,
      '跳转',
      '是否要跳转到$dialogMessage？',
    );
    if (!result) return;
    if (!mounted) return;
    jumpChapter.jumpToChapter(context, isPrev);
  }

  Future<void> _selectJumpChapter() async {
    final router = AutoRouter.of(context);
    final result = await showDialog<int?>(
      context: context,
      barrierDismissible: false, // 不允许点击外部区域关闭对话框
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('选择章节'),
          content: SingleChildScrollView(
            child: widget.from == From.bika
                ? _bikaEpSelector(context)
                : _jmEpSelector(context),
          ),
          actions: [
            TextButton(
              child: Text('取消'),
              onPressed: () {
                context.pop();
              },
            ),
          ],
        );
      },
    );
    if (result != null && mounted) {
      router.replace(
        ComicReadRoute(
          key: Key(Uuid().v4()),
          comicInfo: widget.comicInfo,
          comicId: comicId,
          type: tempType,
          order: result,
          epsNumber: widget.epsNumber,
          from: widget.from,
          stringSelectCubit: context.read<StringSelectCubit>(),
        ),
      );
    }
  }

  Widget _bikaEpSelector(BuildContext context) {
    var epsList = (widget.comicInfo as AllInfo).eps;

    return ListBody(
      children: [
        for (final ep in epsList)
          TextButton(
            child: Text(ep.title),
            onPressed: () =>
                Navigator.of(context, rootNavigator: false).pop(ep.order),
          ),
      ],
    );
  }

  Widget _jmEpSelector(BuildContext context) => ListBody(
    children: [
      for (final series in seriesList)
        TextButton(
          child: Text(series.name),
          onPressed: () => Navigator.of(
            context,
            rootNavigator: false,
          ).pop(series.id.let(toInt)),
        ),
    ],
  );
}

class ChapterNavigationButton extends StatelessWidget {
  final String label;
  final bool isEnabled;
  final VoidCallback onTap;

  const ChapterNavigationButton({
    super.key,
    required this.label,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: isEnabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          side: BorderSide(
            color: context.theme.colorScheme.outlineVariant.withValues(
              alpha: 0.7,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}
