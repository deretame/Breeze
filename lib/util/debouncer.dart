import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({this.milliseconds = 500});

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void cancel() {
    _timer?.cancel();
  }
}

/// 检查当前设备是否为平板
bool isTablet(BuildContext context) {
  // 获取 MediaQueryData 实例
  final MediaQueryData mediaQuery = MediaQuery.of(context);

  // 获取屏幕的最短边
  final double shortestSide = mediaQuery.size.shortestSide;

  // 定义平板的阈值，Material Design 官方推荐为 600
  const double tabletBreakpoint = 600.0;

  // 如果最短边大于等于 600，则认为是平板
  return shortestSide >= tabletBreakpoint;
}

/// 检查当前设备是否为平板
bool isTabletWithOutContext() {
  // 在 runApp 之前，手动计算屏幕的 shortestSide
  // 使用 PlatformDispatcher 来获取屏幕的物理尺寸和设备像素密度
  // 这是现代 Flutter 中推荐的方式
  final view = PlatformDispatcher.instance.views.first;
  final physicalSize = view.physicalSize;
  final devicePixelRatio = view.devicePixelRatio;

  // 计算逻辑像素的 shortestSide
  // 逻辑像素 = 物理像素 / 设备像素密度
  final double shortestSide = physicalSize.shortestSide / devicePixelRatio;

  // 3. 定义平板的阈值
  const double tabletBreakpoint = 600.0;

  return shortestSide >= tabletBreakpoint;
}

// 检测是否是横屏
bool isLandscapeWithOutContext() {
  final view = PlatformDispatcher.instance.views.first;

  return view.physicalSize.width > view.physicalSize.height;
}

bool isLandscape(BuildContext context) {
  final MediaQueryData mediaQuery = MediaQuery.of(context);

  return mediaQuery.orientation == Orientation.landscape;
}
