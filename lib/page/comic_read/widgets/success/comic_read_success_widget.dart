import 'package:zephyr/util/ui/fluent_compat.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/comic_read/cubit/image_size_cubit.dart';
import 'package:zephyr/page/comic_read/method/image_size_cache_store.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/page/comic_read/widgets/layout/read_layout.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/context/context_extensions.dart';

class ComicReadSuccessWidget extends StatefulWidget {
  final String comicId;
  final From from;
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
    required this.comicId,
    required this.from,
    required this.epInfo,
    required this.buildInteractiveViewer,
    required this.buildPageCount,
    required this.buildAppBar,
    required this.buildBottom,
    required this.buildAutoReadControl,
    required this.onReady,
  });

  @override
  State<ComicReadSuccessWidget> createState() => _ComicReadSuccessWidgetState();
}

class _ComicReadSuccessWidgetState extends State<ComicReadSuccessWidget> {
  late final List<String> _pageKeys;
  late final Future<Map<int, Size>> _persistedSizeFuture;

  @override
  void initState() {
    super.initState();
    _pageKeys = _buildPageKeys();
    _persistedSizeFuture = ImageSizeCacheStore(
      sourceTag: widget.from.name,
      pageKeys: _pageKeys,
    ).readIndexedSizes(pageKeys: _pageKeys, count: widget.epInfo.length);
  }

  @override
  Widget build(BuildContext context) {
    final width = context.screenWidth;
    return FutureBuilder<Map<int, Size>>(
      future: _persistedSizeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final persistedSize = snapshot.data ?? const <int, Size>{};
        return BlocProvider(
          create: (_) => ImageSizeCubit.create(
            defaultWidth: width,
            count: widget.epInfo.length,
            sourceTag: widget.from.name,
            pageKeys: _pageKeys,
            persistedCache: persistedSize,
          ),
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
                imageCount: widget.epInfo.length,
                enableDoublePage: readSetting.doublePageMode,
              );
              cubit.updateTotalSlots(totalSlots);
              widget.onReady(innerContext, readSetting, readMode);

              return Container(
                color: backgroundColor,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: widget.buildInteractiveViewer(innerContext),
                    ),
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
                    widget.buildPageCount(innerContext),
                    widget.buildAppBar(innerContext),
                    widget.buildBottom(innerContext),
                    widget.buildAutoReadControl(innerContext),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<String> _buildPageKeys() {
    return List<String>.generate(widget.epInfo.length, (index) {
      if (index >= widget.epInfo.docs.length) {
        return '${widget.comicId}|${widget.epInfo.epId}|index_$index';
      }

      final doc = widget.epInfo.docs[index];
      final imageId = doc.id.isNotEmpty
          ? doc.id
          : (doc.originalName.isNotEmpty ? doc.originalName : doc.path);
      return '${widget.comicId}|${widget.epInfo.epId}|$imageId';
    }, growable: false);
  }
}


