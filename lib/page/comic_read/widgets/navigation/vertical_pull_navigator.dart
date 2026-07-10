import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/i18n/strings.g.dart';
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
    final brightness = Theme.of(context).brightness;
    final readSetting = context.select(
      (GlobalSettingCubit c) => c.state.readSetting,
    );
    final foregroundColor = readSetting.resolveReaderForegroundColor(
      brightness,
    );
    final textStyle = TextStyle(color: foregroundColor);
    final iconTheme = IconThemeData(color: foregroundColor);

    final activeHeader = ClassicHeader(
      dragText: t.reader.pullDownToPrevChapter,
      armedText: t.reader.releaseToJumpPrevChapter,
      readyText: t.reader.releaseToLoadPrevChapter,
      processingText: t.common.loading,
      processedText: '',
      showText: true,
      showMessage: false,
      iconDimension: 16,
      spacing: 16,
      iconTheme: iconTheme,
      processedDuration: Duration.zero,
      textStyle: textStyle,
      triggerOffset: triggerOffset,
    );

    final activeFooter = ClassicFooter(
      dragText: t.reader.pullUpToNextChapter,
      armedText: t.reader.releaseToJumpNextChapter,
      readyText: t.reader.releaseToLoadNextChapter,
      processingText: t.common.loading,
      processedText: '',
      showText: true,
      showMessage: false,
      iconDimension: 16,
      spacing: 16,
      iconTheme: iconTheme,
      processedDuration: Duration.zero,
      infiniteOffset: null,
      textStyle: textStyle,
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
