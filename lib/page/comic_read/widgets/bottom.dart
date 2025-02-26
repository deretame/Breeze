import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/page/comic_info/json/eps/eps.dart' as eps;

import '../../../config/global.dart';
import '../../../main.dart';
import '../../../util/router/router.gr.dart';
import '../../../widgets/comic_entry/comic_entry.dart';
import '../../../widgets/toast.dart';
import '../../comic_info/json/comic_info/comic_info.dart';

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

  @override
  Widget build(BuildContext context) {
    final router = AutoRouter.of(context);
    ComicEntryType tempType = widget.type;
    if (tempType == ComicEntryType.historyAndDownload) {
      tempType = ComicEntryType.download;
    }
    if (tempType == ComicEntryType.history) {
      tempType = ComicEntryType.normal;
    }
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
                        SizedBox(width: 10),
                        GestureDetector(
                          child: Text("上一章"),
                          onTap: () async {
                            if (widget.doc.order == widget.epsInfo[0].order) {
                              showInfoToast("已经是第一章了");
                              return;
                            }
                            final result = await _bottomButtonDialog(
                              context,
                              '跳转',
                              '是否要跳转到上一章？',
                              widget.epsInfo[widget.doc.order - 2],
                            );
                            if (result && mounted) {
                              router.popAndPush(
                                ComicReadRoute(
                                  comicInfo: widget.comicInfo,
                                  epsInfo: widget.epsInfo,
                                  doc: widget.epsInfo[widget.doc.order - 2],
                                  comicId: widget.comicInfo.id,
                                  type: tempType,
                                ),
                              );
                            }
                          },
                        ),
                        widget.sliderWidget,
                        GestureDetector(
                          child: Text("下一章"),
                          onTap: () async {
                            debugPrint('下一章');
                            if (widget.doc.order ==
                                widget
                                    .epsInfo[widget.epsInfo.length - 1]
                                    .order) {
                              showInfoToast("已经是最后一章了");
                              return;
                            }

                            final result = await _bottomButtonDialog(
                              context,
                              '跳转',
                              '是否要跳转到下一章？',
                              widget.epsInfo[widget.doc.order],
                            );
                            if (result) {
                              router.popAndPush(
                                ComicReadRoute(
                                  comicInfo: widget.comicInfo,
                                  epsInfo: widget.epsInfo,
                                  doc: widget.epsInfo[widget.doc.order],
                                  comicId: widget.comicInfo.id,
                                  type: tempType,
                                ),
                              );
                            }
                          },
                        ),
                        SizedBox(width: 10),
                      ],
                    ),
                    Center(
                      child: Container(
                        height: 1, // 设置高度为1像素
                        width: screenWidth * 48 / 50,
                        color:
                            globalSetting.themeType
                                ? materialColorScheme.secondaryFixedDim
                                : materialColorScheme.secondaryFixedDim,
                      ),
                    ),
                    Row(
                      children: [
                        Spacer(),
                        Expanded(
                          child: Center(
                            child: IconButton(
                              icon:
                                  globalSetting.themeMode == ThemeMode.light
                                      ? Icon(Icons.brightness_7)
                                      : Icon(Icons.brightness_5_outlined),
                              onPressed: () {
                                globalSetting.setThemeMode(1);
                              },
                            ),
                          ),
                        ),
                        Spacer(),
                        SizedBox(
                          height: 51,
                          child: GestureDetector(
                            onTap: () async {
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
                                                Navigator.of(
                                                  context,
                                                ).pop(ep.order);
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        child: Text('取消'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
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
                            },
                            child: Center(
                              child: Text(
                                '跳转章节',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon:
                              globalSetting.themeMode == ThemeMode.dark
                                  ? Icon(Icons.brightness_2_rounded)
                                  : Icon(Icons.brightness_2_outlined),
                          onPressed: () {
                            globalSetting.setThemeMode(2);
                          },
                        ),
                        Spacer(),
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
}
