import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/http/picture.dart';
import '../util/state_management.dart';

class ImageBuildWidget extends ConsumerStatefulWidget {
  final String fileServer;
  final String path;
  final String comicId;
  final String? pictureType;
  final String? chapterId;
  final Widget loadingWidget;
  final Widget buildErrorWidget;
  final Widget Function(String data) imageWidgetBuilder;
  final ValueNotifier<bool> isReloading;

  const ImageBuildWidget({
    super.key,
    required this.fileServer,
    required this.path,
    required this.comicId,
    required this.pictureType,
    required this.chapterId,
    required this.loadingWidget,
    required this.buildErrorWidget,
    required this.imageWidgetBuilder,
    required this.isReloading,
  });

  @override
  ConsumerState<ImageBuildWidget> createState() => _ImageBuildWidgetState();
}

class _ImageBuildWidgetState extends ConsumerState<ImageBuildWidget> {
  String get fileServer => widget.fileServer;

  String get path => widget.path;

  String get comicId => widget.comicId;

  String? get pictureType => widget.pictureType;

  String? get chapterId => widget.chapterId;

  Widget get loadingWidget => widget.loadingWidget;

  Widget get buildErrorWidget => widget.buildErrorWidget;

  Widget Function(String data) get imageWidgetBuilder =>
      widget.imageWidgetBuilder;

  ValueNotifier<bool> get isReloading => widget.isReloading;

  late String localPictureType = '';
  late String localChapterId = '';

  @override
  void initState() {
    localPictureType = pictureType ?? '';
    localChapterId = chapterId ?? '';
    super.initState();
  }

  Future<String> _reloadPicture(BuildContext context) async {
    isReloading.value = true;
    String data = ''; // 初始化一个字符串来保存图片数据
    try {
      data = await getCachePicture(fileServer, path, comicId,
          pictureType: localPictureType, chapterId: localChapterId);
    } catch (e) {
      // Handle error if needed
    } finally {
      isReloading.value = false;
    }
    return data; // 返回加载完成的图片数据
  }

  Widget _buildErrorWidget(BuildContext context) {
    return InkWell(
      onTap: () async {
        await _reloadPicture(context);
        setState(() {});
      },
      child: Center(
        child: buildErrorWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorNotifier = ref.watch(defaultColorProvider);
    colorNotifier.initialize(context);
    final future = getCachePicture(fileServer, path, comicId,
        pictureType: localPictureType, chapterId: localChapterId);

    return ValueListenableBuilder<bool>(
      valueListenable: isReloading,
      builder: (context, isReloadingValue, child) {
        if (isReloadingValue) {
          return loadingWidget;
        }
        return FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return loadingWidget;
            } else if (snapshot.hasError) {
              return _buildErrorWidget(context);
            } else if (snapshot.hasData) {
              return imageWidgetBuilder(snapshot.data!);
            } else {
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }
}
