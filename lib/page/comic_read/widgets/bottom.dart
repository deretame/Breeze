import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/comic_info.dart';
import 'package:zephyr/page/comic_read/method/jump_chapter.dart';
import 'package:zephyr/page/jm/jm_comic_info/json/jm_comic_info_json.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';

import '../../../main.dart';
import '../../../type/enum.dart';
import '../../../util/router/router.dart';
import '../../../util/router/router.gr.dart';

class BottomWidget extends StatefulWidget {
  final ComicEntryType type;
  final bool isVisible;
  final dynamic comicInfo;
  final Widget sliderWidget;
  final int order;
  final int epsNumber;
  final String comicId;
  final From from;
  final JumpChapter jumpChapter;

  const BottomWidget({
    super.key,
    required this.isVisible,
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
  final int _bottomWidgetHeight = 100; // 底部悬浮组件高度

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
    final gloablSettingCubit = context.read<GlobalSettingCubit>();
    final globalSettingState = context.watch<GlobalSettingCubit>().state;

    return AnimatedPositioned(
      duration: _animationDuration,
      bottom: widget.isVisible ? 0 : -_bottomWidgetHeight.toDouble(),
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // 高斯模糊强度
          child: Container(
            height: _bottomWidgetHeight.toDouble(),
            width: context.screenWidth,
            color: context.backgroundColor.withValues(alpha: 0.5),
            // 半透明背景
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 10),
                    ChapterNavigationButton(
                      label: "上一章",
                      isEnabled: jumpChapter.havePrev,
                      onTap: () => _jumpToChapter(true),
                    ),
                    widget.sliderWidget,
                    ChapterNavigationButton(
                      label: "下一章",
                      isEnabled: jumpChapter.haveNext,
                      onTap: () => _jumpToChapter(false),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
                Center(
                  child: Container(
                    height: 1, // 设置高度为1像素
                    width: context.screenWidth * 48 / 50,
                    color: context.theme.colorScheme.secondaryFixedDim,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(Icons.home),
                      onPressed: () => popToRoot(context),
                    ),
                    SizedBox(
                      height: 51,
                      child: TextButton(
                        onPressed: seriesList.isEmpty && widget.from == From.jm
                            ? null
                            : () async => await _selectJumpChapter(),
                        child: Center(
                          child: Text('跳转章节', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: _getThemeIcon(),
                      onPressed: () {
                        final ThemeMode nextMode =
                            switch (globalSettingState.themeMode) {
                              ThemeMode.system => ThemeMode.light,
                              ThemeMode.light => ThemeMode.dark,
                              ThemeMode.dark => ThemeMode.system,
                            };

                        gloablSettingCubit.updateThemeMode(nextMode);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Icon _getThemeIcon() {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;

    return switch (globalSettingState.themeMode) {
      ThemeMode.system => const Icon(Icons.brightness_auto_outlined),
      ThemeMode.light => const Icon(Icons.brightness_7),
      ThemeMode.dark => const Icon(Icons.brightness_2_rounded),
    };
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
    return TextButton(onPressed: isEnabled ? onTap : null, child: Text(label));
  }
}
