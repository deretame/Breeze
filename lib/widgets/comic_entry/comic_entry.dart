import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../../config/global.dart';
import '../../main.dart';
import '../full_screen_image_view.dart';
import '../picture_bloc/bloc/picture_bloc.dart';
import '../picture_bloc/models/picture_info.dart';
import 'comic_entry_info.dart';

enum ComicEntryType {
  normal,
  history,
  download,
  historyAndDownload,
}

class ComicEntryWidget extends StatefulWidget {
  final ComicEntryInfo comicEntryInfo;
  final ComicEntryType? type;
  final Function()? refresh;

  const ComicEntryWidget({
    super.key,
    required this.comicEntryInfo,
    this.type,
    this.refresh,
  });

  @override
  State<ComicEntryWidget> createState() => _ComicEntryWidgetState();
}

class _ComicEntryWidgetState extends State<ComicEntryWidget> {
  ComicEntryInfo get comicEntryInfo => widget.comicEntryInfo;

  ComicEntryType? get type => widget.type;

  Function()? get refresh => widget.refresh;

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
      return "分类: $temp";
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = AutoRouter.of(context); // 获取 router 实例
    return GestureDetector(
      onTap: () {
        // 跳转到漫画详情页
        router.push(ComicInfoRoute(
          comicId: comicEntryInfo.id,
          type: _type,
        ));
      },
      onLongPress: () {
        if (_type == ComicEntryType.normal ||
            _type == ComicEntryType.historyAndDownload) {
          return;
        }
        deleteDialog();
      },
      child: Column(
        children: <Widget>[
          SizedBox(height: (screenHeight / 10) * 0.1),
          Observer(builder: (context) {
            return Container(
              height: 180,
              width: ((screenWidth / 10) * 9.5),
              margin:
                  EdgeInsets.symmetric(horizontal: (screenWidth / 10) * 0.25),
              decoration: BoxDecoration(
                color: globalSetting.backgroundColor,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: materialColorScheme.secondaryFixedDim,
                    spreadRadius: 0,
                    blurRadius: 2,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Builder(
                    builder: (BuildContext context) {
                      return ImageWidget(
                        key: ValueKey(comicEntryInfo.id),
                        fileServer: comicEntryInfo.thumb.fileServer,
                        path: comicEntryInfo.thumb.path,
                        id: comicEntryInfo.id,
                        pictureType: "cover",
                      );
                    },
                  ),
                  SizedBox(width: screenWidth / 60),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(height: screenWidth / 200),
                        Text(
                          comicEntryInfo.title,
                          style: TextStyle(
                            color: globalSetting.textColor,
                            fontSize: 18,
                          ),
                          maxLines: 3, // 最大行数
                          overflow: TextOverflow.ellipsis, // 超出时使用省略号
                        ),
                        if (comicEntryInfo.author.toString() != '') ...[
                          const SizedBox(height: 4),
                          Text(
                            comicEntryInfo.author.toString(),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: materialColorScheme.primary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 5),
                        Text(
                          _getCategories(comicEntryInfo.categories),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            color: globalSetting.textColor,
                          ),
                        ),
                        Spacer(),
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 24.0,
                            ),
                            const SizedBox(width: 10.0),
                            Text(
                              comicEntryInfo.likesCount.toString(),
                            ),
                            SizedBox(width: 10.0),
                            Text(
                              comicEntryInfo.finished ? "完结" : "",
                              style: TextStyle(
                                color: materialColorScheme.tertiary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenWidth / 200),
                      ],
                    ),
                  ),
                  SizedBox(width: screenWidth / 50),
                ],
              ),
            );
          })
        ],
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
    debugPrint(_type.toString());
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: Text("取消"),
              onPressed: () {
                // 执行操作1
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("确定"),
              onPressed: () {
                if (_type == ComicEntryType.history) {
                  var temp = objectbox.bikaHistoryBox
                      .query(
                          BikaComicHistory_.comicId.equals(comicEntryInfo.id))
                      .build()
                      .findFirst();
                  if (temp != null) {
                    temp.deleted = true;
                    temp.deletedAt = DateTime.now().toUtc();
                    objectbox.bikaHistoryBox.put(temp);
                    refresh!();
                  }
                }
                if (_type == ComicEntryType.download) {
                  var temp = objectbox.bikaDownloadBox
                      .query(
                          BikaComicDownload_.comicId.equals(comicEntryInfo.id))
                      .build()
                      .findFirst();
                  if (temp != null) {
                    objectbox.bikaDownloadBox.remove(temp.id);
                    refresh!();
                    deleteDirectory(comicEntryInfo.id);
                  }
                }
                Navigator.of(context).pop();
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
        debugPrint('目录已成功删除: $path');
      } catch (e) {
        debugPrint('删除目录时发生错误: $e');
      }
    } else {
      debugPrint('目录不存在: $path');
    }
  }
}

class ImageWidget extends StatelessWidget {
  final String fileServer;
  final String path;
  final String id;
  final String pictureType;

  const ImageWidget({
    super.key,
    required this.fileServer,
    required this.path,
    required this.id,
    required this.pictureType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PictureBloc()
        ..add(
          GetPicture(
            PictureInfo(
              from: "bika",
              url: fileServer,
              path: path,
              cartoonId: id,
              pictureType: pictureType,
            ),
          ),
        ),
      child: BlocBuilder<PictureBloc, PictureLoadState>(
        builder: (context, state) {
          switch (state.status) {
            case PictureLoadStatus.initial:
              return Center(
                child: SizedBox(
                  width: (screenWidth / 10) * 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LoadingAnimationWidget.waveDots(
                      color: materialColorScheme.primaryFixedDim,
                      size: 50,
                    ),
                  ),
                ),
              );
            case PictureLoadStatus.success:
              final uuid = Uuid().v4();
              // 没有错误，正常显示图片
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageView(
                        imagePath: state.imagePath!,
                        uuid: uuid,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: state.imagePath! + uuid,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      bottomLeft: Radius.circular(10.0),
                    ),
                    child: Image.file(
                      File(state.imagePath!),
                      fit: BoxFit.cover,
                      width: (screenWidth / 10) * 3,
                      height: 180,
                    ),
                  ),
                ),
              );
            case PictureLoadStatus.failure:
              if (state.result.toString().contains('404')) {
                return SizedBox(
                  width: (screenWidth / 10) * 3,
                  child: Image.asset('asset/image/error_image/404.png'),
                );
              } else {
                return SizedBox(
                  width: (screenWidth / 10) * 3,
                  child: InkWell(
                    onTap: () {
                      context.read<PictureBloc>().add(
                            GetPicture(
                              PictureInfo(
                                from: "bika",
                                url: fileServer,
                                path: path,
                                cartoonId: id,
                                pictureType: pictureType,
                              ),
                            ),
                          );
                    },
                    child: Center(
                      child: Text(
                        '加载图片失败\n点击重新加载',
                        style: TextStyle(
                          color: globalSetting.textColor,
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
