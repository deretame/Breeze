import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/comic_read/widgets/read_image_widget.dart';
import 'package:zephyr/util/context/context_extensions.dart';

import '../../../config/global/global.dart';
import '../../../type/enum.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';
import '../json/common_ep_info_json/common_ep_info_json.dart';
import 'image_size_cache.dart';

class ColumnModeWidget extends StatefulWidget {
  final int length;
  final List<Doc> docs;
  final String comicId;
  final String epsId;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final From from;

  const ColumnModeWidget({
    super.key,
    required this.length,
    required this.docs,
    required this.comicId,
    required this.epsId,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.from,
  });

  @override
  State<ColumnModeWidget> createState() => _ColumnModeWidgetState();
}

class _ColumnModeWidgetState extends State<ColumnModeWidget> {
  final _sizeCache = ImageSizeCache();
  bool _isPreloading = false;

  @override
  void initState() {
    super.initState();
    // 延迟预加载，避免阻塞初始渲染
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadVisibleImageSizes();
    });
  }

  /// 预加载可见范围内的图片尺寸
  Future<void> _preloadVisibleImageSizes() async {
    if (_isPreloading) return;
    _isPreloading = true;

    // 获取当前可见的图片索引范围
    final positions = widget.itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) {
      _isPreloading = false;
      return;
    }

    final visibleIndices = positions.map((p) => p.index).toList();
    final minIndex = visibleIndices.reduce((a, b) => a < b ? a : b);
    final maxIndex = visibleIndices.reduce((a, b) => a > b ? a : b);

    // 预加载可见范围前后各 5 张图片
    final startIndex = (minIndex - 5).clamp(1, widget.length);
    final endIndex = (maxIndex + 5).clamp(1, widget.length);

    // 批量预加载（限制并发数量避免卡顿）
    for (int i = startIndex; i <= endIndex; i++) {
      if (!mounted) break;

      final doc = widget.docs[i - 1];
      final cacheKey = '${widget.comicId}_${widget.epsId}_${doc.path}';

      // 如果已经有缓存，跳过
      if (_sizeCache.getSize(cacheKey) != null) continue;

      // 这里需要知道图片的本地路径，但这需要 PictureBloc 的逻辑
      // 暂时跳过，让图片自然加载时缓存
    }

    _isPreloading = false;
  }

  @override
  Widget build(BuildContext context) {
    // 减少预加载范围，避免 GPU 内存溢出
    // 从 2.0 倍屏幕高度减少到 1.0 倍
    return useSkia
        ? ScrollablePositionedList.separated(
            // 带分隔符的版本
            itemCount: widget.length + 2,
            itemBuilder: itemBuilder,
            separatorBuilder: (_, _) =>
                Container(height: 2, color: Colors.black),
            itemScrollController: widget.itemScrollController,
            itemPositionsListener: widget.itemPositionsListener,
            minCacheExtent: context.screenHeight * 1.0,
          )
        : ScrollablePositionedList.builder(
            // 不带分隔符的版本
            itemCount: widget.length + 2,
            itemBuilder: itemBuilder,
            itemScrollController: widget.itemScrollController,
            itemPositionsListener: widget.itemPositionsListener,
            minCacheExtent: context.screenHeight * 1.0,
          );
  }

  Widget itemBuilder(BuildContext context, int index) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;

    if (index == 0) {
      return Container(
        width: context.screenWidth,
        height: globalSettingState.comicReadTopContainer
            ? context.statusBarHeight
            : 0,
        color: Colors.black,
      );
    } else if (index == widget.length + 1) {
      return Container(
        height: 75,
        width: context.screenWidth,
        alignment: Alignment.center,
        color: Colors.black,
        child: Text(
          "章节结束",
          style: TextStyle(fontSize: 20, color: Color(0xFFCCCCCC)),
        ),
      );
    } else {
      return Container(
        color: Colors.black,
        child: ReadImageWidget(
          pictureInfo: PictureInfo(
            from: widget.from.toString().split('.').last,
            url: widget.docs[index - 1].fileServer,
            path: widget.docs[index - 1].path,
            cartoonId: widget.comicId,
            chapterId: widget.epsId,
            pictureType: 'comic',
          ),
          index: index - 1,
          isColumn: true,
        ),
      );
    }
  }
}
