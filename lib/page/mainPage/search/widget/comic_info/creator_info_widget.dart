import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../../../config/global.dart';
import '../../../../../json/comic/comic_info.dart';
import '../../../../../network/http/picture.dart';
import '../../../../../util/state_management.dart';
import '../../../../../widgets/full_screen_image_view.dart';

// 显示上传者信息
class CreatorInfoWidget extends ConsumerStatefulWidget {
  final ComicInfo comicInfo;

  const CreatorInfoWidget({super.key, required this.comicInfo});

  @override
  ConsumerState<CreatorInfoWidget> createState() => _CreatorInfoWidgetState();
}

class _CreatorInfoWidgetState extends ConsumerState<CreatorInfoWidget>
    with AutomaticKeepAliveClientMixin<CreatorInfoWidget> {
  ComicInfo get comicInfo => widget.comicInfo;
  late Future<String> _getCachePicture;

  @override
  bool get wantKeepAlive => true; // 这将告诉Flutter保持这个页面状态

  @override
  void initState() {
    super.initState();
    _getCachePicture = getCachePicture(
      comicInfo.comic.creator.avatar.fileServer,
      comicInfo.comic.creator.avatar.path,
      comicInfo.comic.id,
      chapterId: "creator",
    );
  }

  String timeDecode(DateTime originalTime) {
    // 加上8个小时
    DateTime newDateTime = originalTime.add(const Duration(hours: 8));

    // 按照指定格式输出
    String formattedTime =
        '${newDateTime.year}年${newDateTime.month}月${newDateTime.day}日 ${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}:${newDateTime.second.toString().padLeft(2, '0')}';

    return "$formattedTime 更新";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 确保调用super.build
    final colorNotifier = ref.watch(defaultColorProvider);
    colorNotifier.initialize(context); // 显式初始化

    return Container(
      height: 75,
      width: screenWidth * (48 / 50),
      decoration: BoxDecoration(
        color: colorNotifier.defaultBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: colorNotifier.themeType
                ? Colors.black.withOpacity(0.2)
                : Colors.white.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            height: 75,
            width: 75,
            child: FutureBuilder<String>(
              future: _getCachePicture,
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: LoadingAnimationWidget.waveDots(
                      color: Colors.black,
                      size: 25,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return const Text('Error');
                } else if (snapshot.hasData) {
                  return Center(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FullScreenImageView(imagePath: snapshot.data!),
                          ),
                        );
                      },
                      child: Hero(
                        tag: snapshot.data!,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Image.file(
                              File(snapshot.data!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Error loading image: $error');
                                return const Icon(Icons.error,
                                    color: Colors.red);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return const Text('No data');
                }
              },
            ),
          ),
          const SizedBox(width: 15),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  comicInfo.comic.creator.title,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
                Text(
                  timeDecode(comicInfo.comic.updatedAt),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ImagerWidget extends ConsumerStatefulWidget {
  final String fileServer;
  final String path;
  final String id;
  final String pictureType;

  const ImagerWidget({
    super.key,
    required this.fileServer,
    required this.path,
    required this.id,
    required this.pictureType,
  });

  @override
  ConsumerState<ImagerWidget> createState() => _ImagerWidgetState();
}

class _ImagerWidgetState extends ConsumerState<ImagerWidget> {
  get fileServer => widget.fileServer;

  get path => widget.path;

  get id => widget.id;

  get pictureType => widget.pictureType;

  late Future<String> _getCachePicture;

  @override
  void initState() {
    super.initState();
    _getCachePicture = getCachePicture(
      fileServer,
      path,
      id,
      chapterId: pictureType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorNotifier = ref.watch(defaultColorProvider);
    colorNotifier.initialize(context);

    return SizedBox(
      height: 75,
      width: 75,
      child: FutureBuilder<String>(
        future: _getCachePicture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              // 如果有错误，显示错误信息和一个重新加载的按钮
              return InkWell(
                onTap: () {
                  _getCachePicture.then((value) {
                    setState(() {
                      // 更新UI
                    });
                  });
                },
                child: Center(
                  child: Icon(
                    Icons.refresh,
                    size: 25,
                  ),
                ),
              );
            } else {
              // 没有错误，正常显示图片
              return Center(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FullScreenImageView(imagePath: snapshot.data!),
                      ),
                    );
                  },
                  child: Hero(
                    tag: snapshot.data!,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Image.file(
                          File(snapshot.data!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Error loading image: $error');
                            return const Icon(Icons.error, color: Colors.red);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          } else {
            // 图片正在加载中
            return Center(
              child: LoadingAnimationWidget.waveDots(
                color: Colors.black,
                size: 25,
              ),
            );
          }
        },
      ),
    );
  }
}
