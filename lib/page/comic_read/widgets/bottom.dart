import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/page/comic_info/json/bika/eps/eps.dart' as eps;

import '../../../config/global/global.dart';
import '../../../main.dart';
import '../../../type/enum.dart';
import '../../../util/router/router.dart';
import '../../../util/router/router.gr.dart';
import '../../comic_info/json/bika/comic_info/comic_info.dart';

class BottomWidget extends StatefulWidget {
  final ComicEntryType type;
  final bool isVisible;
  final eps.Doc doc;
  final List<eps.Doc> epsInfo;
  final Comic comicInfo;
  final Widget sliderWidget;

  const BottomWidget({
    super.key,
    required this.isVisible,
    required this.type,
    required this.doc,
    required this.epsInfo,
    required this.comicInfo,
    required this.sliderWidget,
  });

  @override
  State<BottomWidget> createState() => _BottomWidgetState();
}

class _BottomWidgetState extends State<BottomWidget> {
  final Duration _animationDuration = const Duration(milliseconds: 300); // 动画时长
  final int _bottomWidgetHeight = 100; // 底部悬浮组件高度

  late ComicEntryType tempType;
  bool havePrev = true;
  bool haveNext = true;

  @override
  void initState() {
    super.initState();
    tempType = widget.type;
    if (tempType == ComicEntryType.historyAndDownload) {
      tempType = ComicEntryType.download;
    }
    if (tempType == ComicEntryType.history) {
      tempType = ComicEntryType.normal;
    }
    if (widget.doc.order == widget.epsInfo[0].order) {
      havePrev = false;
    }
    if (widget.doc.order == widget.epsInfo[widget.epsInfo.length - 1].order) {
      haveNext = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
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
                width: screenWidth,
                color: globalSetting.backgroundColor.withValues(alpha: 0.5),
                // 半透明背景
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        ChapterNavigationButton(
                          label: "上一章",
                          isEnabled: havePrev,
                          onTap: () => _jumpToChapter(true),
                        ),
                        widget.sliderWidget,
                        ChapterNavigationButton(
                          label: "下一章",
                          isEnabled: haveNext,
                          onTap: () => _jumpToChapter(false),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                    Center(
                      child: Container(
                        height: 1, // 设置高度为1像素
                        width: screenWidth * 48 / 50,
                        color: materialColorScheme.secondaryFixedDim,
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
                          child: GestureDetector(
                            onTap: () async => await _selectJumpChapter(),
                            child: Center(
                              child: Text(
                                '跳转章节',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: _getThemeIcon(),
                          onPressed: () {
                            final nextMode =
                                (globalSetting.themeMode.index + 1) % 3;
                            globalSetting.setThemeMode(nextMode);
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
      },
    );
  }

  Icon _getThemeIcon() {
    return switch (globalSetting.themeMode) {
      ThemeMode.system => const Icon(Icons.brightness_auto_outlined),
      ThemeMode.light => const Icon(Icons.brightness_7),
      ThemeMode.dark => const Icon(Icons.brightness_2_rounded),
    };
  }

  Future<bool> _bottomButtonDialog(
    BuildContext context,
    String title,
    String content,
    eps.Doc doc,
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
    final router = AutoRouter.of(context);
    final result = await _bottomButtonDialog(
      context,
      '跳转',
      '是否要跳转到$dialogMessage？',
      widget.epsInfo[widget.doc.order],
    );
    if (result) {
      router.popAndPush(
        ComicReadRoute(
          comicInfo: widget.comicInfo,
          epsInfo: widget.epsInfo,
          doc:
              isPrev
                  ? widget.epsInfo[widget.doc.order - 2]
                  : widget.epsInfo[widget.doc.order],
          comicId: widget.comicInfo.id,
          type: tempType,
        ),
      );
    }
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
            child: ListBody(
              children: [
                for (final ep in widget.epsInfo)
                  TextButton(
                    child: Text(ep.title),
                    onPressed: () {
                      Navigator.of(context).pop(ep.order);
                    },
                  ),
              ],
            ),
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
      router.popAndPush(
        ComicReadRoute(
          comicInfo: widget.comicInfo,
          epsInfo: widget.epsInfo,
          doc: widget.epsInfo[result - 1],
          comicId: widget.comicInfo.id,
          type: tempType,
        ),
      );
    }
  }
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
