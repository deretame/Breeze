import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/util/sundry.dart';

import '../../main.dart';
import '../../type/enum.dart';
import '../picture_bloc/bloc/picture_bloc.dart';
import '../picture_bloc/models/picture_info.dart';
import 'comic_entry_info.dart';

class ComicEntryWidget extends StatefulWidget {
  final ComicEntryInfo comicEntryInfo;
  final ComicEntryType? type;
  final VoidCallback? refresh;
  final PictureType? pictureType;

  const ComicEntryWidget({
    super.key,
    required this.comicEntryInfo,
    this.type,
    this.refresh,
    this.pictureType,
  });

  @override
  State<ComicEntryWidget> createState() => _ComicEntryWidgetState();
}

class _ComicEntryWidgetState extends State<ComicEntryWidget> {
  ComicEntryInfo get comicEntryInfo => widget.comicEntryInfo;

  ComicEntryType? get type => widget.type;

  VoidCallback? get refresh => widget.refresh;

  PictureType? get pictureType => widget.pictureType;

  ComicEntryType? _type;

  @override
  void initState() {
    super.initState();
    _type = type ?? ComicEntryType.normal;
  }

  String _getCategories(List<String>? categories) {
    if (categories == null) {
      return "";
    } else {
      String temp = "";
      for (var category in categories) {
        temp += "$category ";
      }
      return "分类: ${temp.let(t2s)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    const double coverWidth = 100.0;
    const double coverHeight = 133.0;

    return GestureDetector(
      onTap: () {
        context.pushRoute(
          ComicInfoRoute(
            comicId: comicEntryInfo.id,
            type: _type!,
            from: From.bika,
          ),
        );
      },
      onLongPress: () {
        if (_type == ComicEntryType.normal ||
            _type == ComicEntryType.historyAndDownload) {
          return;
        }
        deleteDialog();
      },
      child: Container(
        width: ((context.screenWidth / 10) * 9.5),
        margin: EdgeInsets.symmetric(
          horizontal: (context.screenWidth / 10) * 0.25,
          vertical: 6.0,
        ),
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primaryFixedDim,
              spreadRadius: 0,
              blurRadius: 2,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (BuildContext context) {
                return ImageWidget(
                  key: ValueKey(comicEntryInfo.id),
                  fileServer: comicEntryInfo.thumb.fileServer,
                  path: comicEntryInfo.thumb.path,
                  id: comicEntryInfo.id,
                  pictureType: pictureType ?? PictureType.cover,
                  targetWidth: coverWidth,
                  targetHeight: coverHeight,
                );
              },
            ),

            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: coverHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comicEntryInfo.title,
                            style: TextStyle(
                              color: context.textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (comicEntryInfo.author.toString().isNotEmpty) ...[
                            Text(
                              comicEntryInfo.author.toString(),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            _getCategories(comicEntryInfo.categories),
                            style: TextStyle(
                              color: context.textColor.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 20.0,
                          ),
                          const SizedBox(width: 6.0),
                          Text(
                            comicEntryInfo.likesCount.toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 12.0),
                          Text(
                            comicEntryInfo.finished ? "完结" : "连载中",
                            style: TextStyle(
                              color: theme.colorScheme.tertiary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future deleteDialog() {
    var title = "";
    if (_type == ComicEntryType.history) {
      title = "删除历史记录";
    } else if (_type == ComicEntryType.download) {
      title = "删除下载记录";
    }
    var content = "确定要删除（${comicEntryInfo.title}）的";
    if (_type == ComicEntryType.history) {
      content += "历史记录吗？";
    } else if (_type == ComicEntryType.download) {
      content += "下载记录及文件吗？";
    }
    logger.d(_type.toString());
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(child: Text("取消"), onPressed: () => context.pop()),
            TextButton(
              child: Text("确定"),
              onPressed: () {
                if (_type == ComicEntryType.history) {
                  var temp = objectbox.bikaHistoryBox
                      .query(
                        BikaComicHistory_.comicId.equals(comicEntryInfo.id),
                      )
                      .build()
                      .findFirst();
                  if (temp != null) {
                    temp.deleted = true;
                    temp.history = DateTime.now().toUtc();
                    objectbox.bikaHistoryBox.put(temp);
                    refresh!();
                  }
                }
                if (_type == ComicEntryType.download) {
                  var temp = objectbox.bikaDownloadBox
                      .query(
                        BikaComicDownload_.comicId.equals(comicEntryInfo.id),
                      )
                      .build()
                      .findFirst();
                  if (temp != null) {
                    objectbox.bikaDownloadBox.remove(temp.id);
                    refresh!();
                    deleteDirectory(comicEntryInfo.id);
                  }
                }
                context.pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteDirectory(String id) async {
    String path =
        '/data/data/com.zephyr.breeze/files/downloads/bika/original/$id';
    final directory = Directory(path);

    // 检查目录是否存在
    if (await directory.exists()) {
      try {
        // 删除目录及其内容
        await directory.delete(recursive: true);
        logger.d('目录已成功删除: $path');
      } catch (e) {
        logger.e('删除目录时发生错误: $e');
      }
    } else {
      logger.e('目录不存在: $path');
    }
  }
}

class ImageWidget extends StatelessWidget {
  final String fileServer;
  final String path;
  final String id;
  final PictureType pictureType;
  final double targetWidth;
  final double targetHeight;

  const ImageWidget({
    super.key,
    required this.fileServer,
    required this.path,
    required this.id,
    required this.pictureType,
    this.targetWidth = 100,
    this.targetHeight = 133,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final pictureInfo = PictureInfo(
      from: From.bika,
      url: fileServer,
      path: path,
      cartoonId: id,
      pictureType: pictureType,
    );

    return BlocProvider(
      create: (context) => PictureBloc()..add(GetPicture(pictureInfo)),
      child: BlocBuilder<PictureBloc, PictureLoadState>(
        builder: (context, state) {
          Widget containerWrapper(Widget child) {
            return SizedBox(
              width: targetWidth,
              height: targetHeight,
              child: child,
            );
          }

          // 定义统一的圆角
          const borderRadius = BorderRadius.only(
            topLeft: Radius.circular(10.0),
            bottomLeft: Radius.circular(10.0),
          );

          switch (state.status) {
            case PictureLoadStatus.initial:
              return containerWrapper(
                Center(
                  child: LoadingAnimationWidget.waveDots(
                    color: theme.colorScheme.primaryFixedDim,
                    size: 30,
                  ),
                ),
              );
            case PictureLoadStatus.success:
              return InkWell(
                onTap: () {
                  context.pushRoute(
                    FullRouteImageRoute(imagePath: state.imagePath!),
                  );
                },
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: Image.file(
                    File(state.imagePath!),
                    fit: BoxFit.cover,
                    width: targetWidth,
                    height: targetHeight,
                  ),
                ),
              );
            case PictureLoadStatus.failure:
              if (state.result.toString().contains('404')) {
                return ClipRRect(
                  borderRadius: borderRadius,
                  child: Image.asset(
                    'asset/image/error_image/404.png',
                    fit: BoxFit.cover,
                    width: targetWidth,
                    height: targetHeight,
                  ),
                );
              } else {
                return containerWrapper(
                  InkWell(
                    onTap: () {
                      context.read<PictureBloc>().add(GetPicture(pictureInfo));
                    },
                    child: Center(
                      child: Text(
                        '重试',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }
          }
        },
      ),
    );
  }
}
