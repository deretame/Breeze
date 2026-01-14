import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/util/context/context_extensions.dart';

class VerticalPullNavigator extends StatelessWidget {
  final bool havePrev;
  final bool haveNext;
  final Future<void> Function() onPrev;
  final Future<void> Function() onNext;
  final Widget Function(BuildContext context, ScrollPhysics physics) builder;

  const VerticalPullNavigator({
    super.key,
    required this.havePrev,
    required this.haveNext,
    required this.onPrev,
    required this.onNext,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    const offset = 8;
    final triggerOffset = context.screenHeight / offset;

    final activeHeader = ClassicHeader(
      dragText: '下拉上一章',
      armedText: '松手跳转上一章',
      readyText: '松手加载上一章',
      processingText: '加载中...',
      processedText: '',
      showText: true,
      showMessage: false,
      iconDimension: 0,
      spacing: 0,
      processedDuration: Duration.zero,
      textStyle: const TextStyle(color: Colors.white),
      triggerOffset: triggerOffset,
    );

    final activeFooter = ClassicFooter(
      dragText: '上拉下一章',
      armedText: '松手跳转下一章',
      readyText: '松手加载下一章',
      processingText: '加载中...',
      processedText: '',
      showText: true,
      showMessage: false,
      iconDimension: 0,
      spacing: 0,
      processedDuration: Duration.zero,
      infiniteOffset: null,
      textStyle: const TextStyle(color: Colors.white),
      triggerOffset: triggerOffset,
    );

    return EasyRefresh.builder(
      header: activeHeader,
      footer: activeFooter,
      triggerAxis: Axis.vertical,

      onRefresh: havePrev ? onPrev : null,
      onLoad: haveNext ? onNext : null,

      notRefreshHeader: const NotRefreshHeader(
        clamping: false,
        hitOver: true,
        position: IndicatorPosition.locator,
      ),
      notLoadFooter: const NotLoadFooter(
        clamping: false,
        hitOver: true,
        position: IndicatorPosition.locator,
      ),

      // 将 physics 传递给外部提供的子组件构建器
      childBuilder: (context, physics) {
        return builder(context, physics);
      },
    );
  }
}
