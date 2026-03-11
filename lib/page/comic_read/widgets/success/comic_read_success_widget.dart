import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/comic_read/cubit/image_size_cubit.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/page/comic_read/widgets/layout/read_layout.dart';
import 'package:zephyr/util/context/context_extensions.dart';

class ComicReadSuccessWidget extends StatelessWidget {
  final NormalComicEpInfo epInfo;
  final WidgetBuilder buildInteractiveViewer;
  final WidgetBuilder buildPageCount;
  final WidgetBuilder buildAppBar;
  final WidgetBuilder buildBottom;
  final WidgetBuilder buildAutoReadControl;
  final void Function(
    BuildContext innerContext,
    ReadSettingState readSetting,
    int readMode,
  )
  onReady;

  const ComicReadSuccessWidget({
    super.key,
    required this.epInfo,
    required this.buildInteractiveViewer,
    required this.buildPageCount,
    required this.buildAppBar,
    required this.buildBottom,
    required this.buildAutoReadControl,
    required this.onReady,
  });

  @override
  Widget build(BuildContext context) {
    final width = context.screenWidth;

    return BlocProvider(
      create: (_) =>
          ImageSizeCubit.create(defaultWidth: width, count: epInfo.length),
      child: Builder(
        builder: (innerContext) {
          final cubit = innerContext.read<ReaderCubit>();
          final readMode = innerContext.select(
            (GlobalSettingCubit c) => c.state.readMode,
          );
          final readSetting = innerContext.select(
            (GlobalSettingCubit c) => c.state.readSetting,
          );
          final backgroundColor = readSetting.resolveReaderBackgroundColor(
            Theme.of(innerContext).brightness,
          );
          final isDarkMode =
              Theme.of(innerContext).brightness == Brightness.dark;
          final filterOpacityPercent = readSetting.readFilterOpacityPercent
              .clamp(0, 100)
              .toDouble();
          final enableReaderFilter =
              isDarkMode &&
              readSetting.readFilterEnabled &&
              filterOpacityPercent > 0;

          final totalSlots = getReadModeSlotCount(
            imageCount: epInfo.length,
            enableDoublePage: readSetting.doublePageMode,
          );
          cubit.updateTotalSlots(totalSlots);
          onReady(innerContext, readSetting, readMode);

          return Container(
            color: backgroundColor,
            child: Stack(
              children: [
                Positioned.fill(child: buildInteractiveViewer(innerContext)),
                if (enableReaderFilter)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: Container(
                        color: Colors.black.withValues(
                          alpha: filterOpacityPercent / 100,
                        ),
                      ),
                    ),
                  ),
                buildPageCount(innerContext),
                buildAppBar(innerContext),
                buildBottom(innerContext),
                buildAutoReadControl(innerContext),
              ],
            ),
          );
        },
      ),
    );
  }
}
