import 'dart:convert';
import 'dart:io';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/download/json/comic_all_info_json_no_freeze/comic_all_info_json_no_freeze.dart'
    as temp_json;
import 'package:zephyr/page/download/widgets/eps.dart';

import '../../../config/global/global.dart';
import '../../../network/http/bika/http_request.dart';
import '../../../network/http/picture/picture.dart';
import '../../../object_box/model.dart';
import '../../../util/get_path.dart';
import '../../comic_info/json/bika/comic_info/comic_info.dart';
import '../../comic_info/json/bika/eps/eps.dart';
import '../../comic_read/json/bika_ep_info_json/page.dart' show Page;
import '../../comments/widgets/title.dart';
import '../method/download_comic.dart';

@RoutePage()
class DownloadPage extends StatefulWidget {
  final Comic comicInfo;
  final List<Doc> epsInfo;

  const DownloadPage({
    super.key,
    required this.comicInfo,
    required this.epsInfo,
  });

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  Comic get comicInfo => widget.comicInfo;

  List<Doc> get epsInfo => widget.epsInfo;

  late Map<int, bool> _downloadInfo;
  late BikaComicDownload? bikaComicDownloadInfo;

  void onUpdateDownloadInfo(int order) {
    setState(() {
      _downloadInfo[order] = !_downloadInfo[order]!;
    });
  }

  @override
  void initState() {
    super.initState();
    _downloadInfo = {};
    for (var ep in epsInfo) {
      _downloadInfo[ep.order] = false;
    }
    final query = objectbox.bikaDownloadBox.query(
      BikaComicDownload_.comicId.equals(comicInfo.id),
    );
    bikaComicDownloadInfo = query.build().findFirst();
    if (bikaComicDownloadInfo != null) {
      for (var epTitle in bikaComicDownloadInfo!.epsTitle) {
        for (var ep in epsInfo) {
          if (ep.title == epTitle) {
            _downloadInfo[ep.order] = true;
          }
        }
      }
    }
  }

  // 判断是否所有章节都被选中
  bool get isAllSelected {
    return epsInfo.every((ep) => _downloadInfo[ep.order] == true);
  }

  // 切换全选或取消全选
  void toggleSelectAll() {
    setState(() {
      bool newState = !isAllSelected; // 如果当前是全选，则取消全选；反之亦然
      for (var ep in epsInfo) {
        _downloadInfo[ep.order] = newState;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ScrollableTitle(text: comicInfo.title),
        actions: [
          // 动态切换全选/取消全选按钮
          IconButton(
            icon: Icon(isAllSelected ? Icons.deselect : Icons.select_all),
            onPressed: toggleSelectAll,
          ),
        ],
      ),
      body: ListView.builder(
        // 设置 ListView 的宽度为屏幕宽度
        padding: EdgeInsets.symmetric(horizontal: screenWidth / 50),
        itemCount: epsInfo.length, // 列表项的数量
        itemBuilder: (context, index) {
          final doc = epsInfo[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: EpsWidget(
              doc: doc,
              downloaded: _downloadInfo[doc.order]!,
              onUpdateDownloadInfo: onUpdateDownloadInfo,
            ),
          );
        },
      ),
      floatingActionButton: SizedBox(
        width: 100, // 设置容器宽度，以容纳更长的文本
        height: 56, // 设置容器高度，与默认的FloatingActionButton高度一致
        child: FloatingActionButton(
          onPressed: () {
            logger.d("开始下载");
            download();
          },
          child: Text("开始下载", overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ),
    );
  }

  Future<void> download() async {
    bool getCoverSuccess = false;
    var message = "";
    var downloadCount = 0;
    temp_json.Eps eps = temp_json.Eps.empty();

    for (var ep in epsInfo) {
      if (_downloadInfo[ep.order]!) {
        eps.add(
          temp_json.EpsDoc(
            id: ep.id,
            title: ep.title,
            order: ep.order,
            updatedAt: ep.updatedAt,
            docId: ep.docId,
            pages: temp_json.Pages.empty(),
          ),
        );
      }
    }

    message = "开始下载，请不要关闭应用或放入后台。\n正在获取章节漫画信息...";
    downloadCount = 0;
    List<MediaInfoAll> mediaList = [];

    final overlay = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).padding.top + 200.0, // 调整到状态栏下面
            left: 16.0,
            right: 16.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10), // 设置圆角
              child: Material(
                color: materialColorScheme.secondaryFixedDim,
                // 设置 Material 背景为透明
                elevation: 2,
                // 设置阴影
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: globalSetting.backgroundColor,
                      borderRadius: BorderRadius.circular(10), // 内部容器的圆角
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(message, style: TextStyle(fontSize: 18)),
                        SizedBox(height: 8),
                        LinearProgressIndicator(
                          value:
                              mediaList.isNotEmpty
                                  ? (downloadCount / mediaList.length)
                                  : null,
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);

    var comicId = comicInfo.id;

    while (true) {
      try {
        await downloadPicture(
          from: 'bika',
          url: comicInfo.thumb.fileServer,
          path: comicInfo.thumb.path,
          cartoonId: comicInfo.id,
          pictureType: 'cover',
          chapterId: comicInfo.id,
        );
        getCoverSuccess = true;
        break;
      } catch (e) {
        logger.e('Error getting comic info: ${e.toString()}');
        if (e.toString().contains("404")) {
          getCoverSuccess = false;
          break;
        }
      }
    }

    int i = 0;

    for (var ep in epsInfo) {
      if (!_downloadInfo[ep.order]!) {
        continue;
      }
      int page = 1, pages = 1;
      while (true) {
        try {
          temp_json.Pages pagesDocs = temp_json.Pages.empty();
          do {
            var result = await getPages(
              comicId,
              ep.order,
              page,
              // 锁定下载图片的质量为原图
              imageQuality: "original",
            );
            var temp = Page.fromJson(result);
            page += 1;
            pages = temp.data.pages.pages;

            for (var doc in temp.data.pages.docs) {
              mediaList.add(
                MediaInfoAll(
                  originalName: doc.media.originalName,
                  path: doc.media.path,
                  fileServer: doc.media.fileServer,
                  epId: ep.id,
                ),
              );
              pagesDocs.add(
                temp_json.PagesDoc(
                  id: doc.id,
                  media: temp_json.Thumb(
                    originalName: doc.media.originalName,
                    path: doc.media.path,
                    fileServer: doc.media.fileServer,
                  ),
                  docId: doc.docId,
                ),
              );
            }
          } while (page <= pages);
          eps[i].pages = pagesDocs;
          i++;
          break;
        } catch (e) {
          logger.e('Error getting pages: ${e.toString()}');
        }
        break;
      }
    }

    List<String> picturePaths = [];

    message =
        "下载进度："
        "${(downloadCount / mediaList.length * 100.0).toStringAsFixed(2)}%";
    // 更新进度条内容
    overlayEntry.markNeedsBuild();

    final List<Future<void>> downloadTasks =
        mediaList.map((media) async {
          var picturePath = await downloadPicture(
            from: 'bika',
            url: media.fileServer,
            path: media.path,
            cartoonId: comicInfo.id,
            pictureType: 'comic',
            chapterId: media.epId,
          ).catchError((e) {
            logger.e('Error downloading ${media.fileServer}: $e');
            return "";
          });

          downloadCount++;
          message =
              "下载进度："
              "${(downloadCount / mediaList.length * 100.0).toStringAsFixed(2)}%";

          // 更新进度条内容
          overlayEntry.markNeedsBuild();

          picturePaths.add(picturePath);

          return;
        }).toList();

    await Future.wait(downloadTasks);

    // 创建一个空的 ComicAllInfoJsonNoFreeze 实例
    var a = temp_json.ComicAllInfoJsonNoFreeze.empty();

    a.comic.id = comicInfo.id;
    a.comic.creator.id = comicInfo.creator.id;
    a.comic.creator.gender = comicInfo.creator.gender;
    a.comic.creator.name = comicInfo.creator.name;
    a.comic.creator.verified = comicInfo.creator.verified;
    a.comic.creator.exp = comicInfo.creator.exp;
    a.comic.creator.level = comicInfo.creator.level;
    a.comic.creator.role = comicInfo.creator.role;
    if (getCoverSuccess) {
      a.comic.creator.avatar.fileServer = comicInfo.creator.avatar.fileServer;
      a.comic.creator.avatar.path = comicInfo.creator.avatar.path;
      a.comic.creator.avatar.originalName =
          comicInfo.creator.avatar.originalName;
    } else {
      a.comic.creator.avatar.fileServer = "";
      a.comic.creator.avatar.path = "";
      a.comic.creator.avatar.originalName = "";
    }
    a.comic.creator.characters = comicInfo.creator.characters;
    a.comic.creator.title = comicInfo.creator.title;
    a.comic.creator.slogan = comicInfo.creator.slogan;
    a.comic.title = comicInfo.title;
    a.comic.description = comicInfo.description;
    a.comic.thumb.fileServer = comicInfo.thumb.fileServer;
    a.comic.thumb.path = comicInfo.thumb.path;
    a.comic.thumb.originalName = comicInfo.thumb.originalName;
    a.comic.author = comicInfo.author;
    a.comic.chineseTeam = comicInfo.chineseTeam;
    a.comic.categories = comicInfo.categories;
    a.comic.tags = comicInfo.tags;
    a.comic.totalComments = comicInfo.totalComments;
    a.comic.pagesCount = comicInfo.pagesCount;
    a.comic.epsCount = comicInfo.epsCount;
    a.comic.finished = comicInfo.finished;
    a.comic.updatedAt = comicInfo.updatedAt;
    a.comic.createdAt = comicInfo.createdAt;
    a.comic.allowDownload = comicInfo.allowDownload;
    a.comic.allowComment = comicInfo.allowComment;
    a.comic.totalLikes = comicInfo.totalLikes;
    a.comic.totalViews = comicInfo.totalViews;
    a.comic.totalComments = comicInfo.totalComments;
    a.comic.viewsCount = comicInfo.viewsCount;
    a.comic.likesCount = comicInfo.likesCount;
    a.comic.commentsCount = comicInfo.commentsCount;
    a.comic.isFavourite = comicInfo.isFavourite;
    a.comic.isLiked = comicInfo.isLiked;
    a.eps = eps;

    var comicAllInfoStr = json.encode(a.toJson());

    List<String> epsTitle = [];
    for (int i = 1; i <= epsInfo.length; i++) {
      if (_downloadInfo[i]!) {
        epsTitle.add(epsInfo[i - 1].title);
      }
    }

    epsTitle = epsTitle.toSet().toList();

    // 保存到数据库
    var bikaComicDownload = BikaComicDownload(
      comicId: comicInfo.id,
      creatorId: comicInfo.creator.id,
      creatorGender: comicInfo.creator.gender,
      creatorName: comicInfo.creator.name,
      creatorVerified: comicInfo.creator.verified,
      creatorExp: comicInfo.creator.exp,
      creatorLevel: comicInfo.creator.level,
      creatorCharacters: comicInfo.creator.characters,
      creatorCharactersString: comicInfo.creator.characters.join(","),
      creatorRole: comicInfo.creator.role,
      creatorTitle: comicInfo.creator.title,
      creatorAvatarOriginalName: comicInfo.creator.avatar.originalName,
      creatorAvatarPath: comicInfo.creator.avatar.path,
      creatorAvatarFileServer: comicInfo.creator.avatar.fileServer,
      creatorSlogan: comicInfo.creator.slogan,
      title: comicInfo.title,
      description: comicInfo.description,
      thumbOriginalName: comicInfo.thumb.originalName,
      thumbPath: comicInfo.thumb.path,
      thumbFileServer: comicInfo.thumb.fileServer,
      author: comicInfo.author,
      chineseTeam: comicInfo.chineseTeam,
      categories: comicInfo.categories,
      categoriesString: comicInfo.categories.join(","),
      tags: comicInfo.tags,
      tagsString: comicInfo.tags.join(","),
      pagesCount: comicInfo.pagesCount,
      epsCount: comicInfo.epsCount,
      finished: comicInfo.finished,
      updatedAt: comicInfo.updatedAt,
      createdAt: comicInfo.createdAt,
      allowDownload: comicInfo.allowDownload,
      allowComment: comicInfo.allowComment,
      totalLikes: comicInfo.totalLikes,
      totalViews: comicInfo.totalViews,
      totalComments: comicInfo.totalComments,
      viewsCount: comicInfo.viewsCount,
      likesCount: comicInfo.likesCount,
      commentsCount: comicInfo.commentsCount,
      isFavourite: comicInfo.isFavourite,
      isLiked: comicInfo.isLiked,
      downloadTime: DateTime.now().toUtc(),
      epsTitle: epsTitle,
      comicInfoAll: comicAllInfoStr,
    );

    var temp =
        objectbox.bikaDownloadBox
            .query(BikaComicDownload_.comicId.equals(comicInfo.id))
            .build()
            .find();

    // 这个是为了避免重复放置数据
    for (var item in temp) {
      objectbox.bikaDownloadBox.remove(item.id);
    }

    await objectbox.bikaDownloadBox.putAsync(bikaComicDownload);

    message = "下载完成，共下载 $downloadCount 张图片。";

    // 更新并移除 Overlay
    overlayEntry.markNeedsBuild();
    Future.delayed(Duration(seconds: 2), () {
      overlayEntry.remove();
    });

    String downloadPath = await getDownloadPath();
    var epsDir = "$downloadPath/bika/original/${comicInfo.id}/comic/";
    // 创建 Directory 对象
    Directory directory = Directory(epsDir);

    // 检查目录是否存在
    if (!await directory.exists()) {
      logger.d("目录不存在: $epsDir");
    }

    // 列出目录下的所有文件和子目录
    List<FileSystemEntity> entities = directory.listSync();

    // 过滤出子目录
    List<Directory> epDirs = entities.whereType<Directory>().toList();

    List<String> downloadEpsDir = [];
    for (var element in a.eps.docs) {
      downloadEpsDir.add(
        "$downloadPath/bika/original/${comicInfo.id}/comic/${element.id}",
      );
    }

    // 过滤出需要删除的目录
    List<Directory> deleteDirs =
        epDirs.where((element) {
          return !downloadEpsDir.contains(element.path);
        }).toList();

    // 删除不需要的目录
    for (var element in deleteDirs) {
      await element.delete(recursive: true);
    }

    List<String> originalPicturePaths = [];

    for (var element in mediaList) {
      String sanitizedPath = element.path.replaceAll(
        RegExp(r'[^a-zA-Z0-9_\-.]'),
        '_',
      );
      var tempPath =
          "$downloadPath/bika/original/${comicInfo.id}/comic/${element.epId}/$sanitizedPath";
      originalPicturePaths.add(tempPath);
    }

    var allPicturePaths = await getAllFilePaths(
      "$downloadPath/bika/original/${comicInfo.id}/comic/",
    );

    // 过滤出需要删除的图片
    List<String> deletePictures =
        allPicturePaths.where((element) {
          return !originalPicturePaths.contains(element);
        }).toList();

    // 删除不需要的图片
    for (var element in deletePictures) {
      await File(element).delete();
    }
  }

  // 递归获取目录下的所有文件路径
  Future<List<String>> getAllFilePaths(String directoryPath) async {
    List<String> filePaths = [];
    Directory directory = Directory(directoryPath);

    // 检查目录是否存在
    if (!await directory.exists()) {
      throw Exception("目录不存在: $directoryPath");
    }

    // 遍历目录
    await for (FileSystemEntity entity in directory.list(recursive: true)) {
      if (entity is File) {
        filePaths.add(entity.path); // 如果是文件，添加到列表中
      }
    }

    return filePaths;
  }
}
