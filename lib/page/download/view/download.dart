import 'dart:convert';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/download/json/comic_all_info_json_no_freeze/comic_all_info_json_no_freeze.dart'
    as temp_json;
import 'package:zephyr/page/download/widgets/eps.dart';

import '../../../config/global.dart';
import '../../../network/http/http_request.dart';
import '../../../network/http/picture.dart';
import '../../../object_box/model.dart';
import '../../../page/comic_read/json/page.dart' as comic_page_json;
import '../../comic_info/json/comic_info/comic_info.dart';
import '../../comic_info/json/eps/eps.dart';
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
    final query = objectbox.bikaDownloadBox
        .query(BikaComicDownload_.comicId.equals(comicInfo.id));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ScrollableTitle(
          text: comicInfo.title,
        ),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          width: screenWidth,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(width: screenWidth / 50),
              Flexible(
                fit: FlexFit.loose,
                child: Column(
                  children: [
                    ...epsInfo.map(
                      (doc) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: EpsWidget(
                          doc: doc,
                          downloaded: _downloadInfo[doc.order]!,
                          onUpdateDownloadInfo: onUpdateDownloadInfo,
                        ),
                      ),
                    ),
                    const SizedBox(height: 85),
                  ],
                ),
              ),
              SizedBox(width: screenWidth / 50),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        width: 100, // 设置容器宽度，以容纳更长的文本
        height: 56, // 设置容器高度，与默认的FloatingActionButton高度一致
        child: FloatingActionButton(
          onPressed: () {
            debugPrint("开始下载");
            download();
          },
          child: Text(
            "开始下载",
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
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

    // 使用 Card 显示进度条
    final overlay = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 200.0, // 调整到状态栏下面
        left: 16.0,
        right: 16.0,
        child: Material(
          color: Colors.transparent, // 设置 Material 背景为透明，这样可以显示背景底色
          elevation: 4,
          child: Container(
            decoration: BoxDecoration(
              color: globalSetting.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: mediaList.isNotEmpty
                      ? (downloadCount / mediaList.length)
                      : null,
                ),
                SizedBox(height: 8),
              ],
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
        debugPrint('Error getting comic info: ${e.toString()}');
        if (e.toString().contains("404")) {
          getCoverSuccess = false;
          break;
        }
      }
    }

    for (var ep in epsInfo) {
      if (!_downloadInfo[ep.order]!) {
        continue;
      }
      int page = 1, pages = 1;
      while (true) {
        try {
          temp_json.Pages pagesDocs = temp_json.Pages.empty();
          do {
            var result = await getPages(comicId, ep.order, page,
                imageQuality: "original");
            var temp = comic_page_json.Page.fromJson(result);
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
          eps[ep.order - 1].pages = pagesDocs;
          break;
        } catch (e) {
          debugPrint('Error getting pages: ${e.toString()}');
        }
        break;
      }
    }

    message = "下载进度："
        "${(downloadCount / mediaList.length * 100.0).toStringAsFixed(2)}%";
    // 更新进度条内容
    overlayEntry.markNeedsBuild();

    final List<Future<void>> downloadTasks = mediaList.map((media) async {
      await downloadPicture(
        from: 'bika',
        url: media.fileServer,
        path: media.path,
        cartoonId: comicInfo.id,
        pictureType: 'comic',
        chapterId: media.epId,
      ).catchError((e) {
        debugPrint('Error downloading ${media.fileServer}: $e');
        return "";
      });

      downloadCount++;
      message = "下载进度："
          "${(downloadCount / mediaList.length * 100.0).toStringAsFixed(2)}%";

      // 更新进度条内容
      overlayEntry.markNeedsBuild();

      return;
    }).toList();

    await Future.wait(downloadTasks);

    // 创建一个空的 ComicAllInfoJsonNoFreeze 实例
    var comicAllInfoJsonNoFreeze = temp_json.ComicAllInfoJsonNoFreeze.empty();

    comicAllInfoJsonNoFreeze.comic.id = comicInfo.id;
    comicAllInfoJsonNoFreeze.comic.creator.id = comicInfo.creator.id;
    comicAllInfoJsonNoFreeze.comic.creator.gender = comicInfo.creator.gender;
    comicAllInfoJsonNoFreeze.comic.creator.name = comicInfo.creator.name;
    comicAllInfoJsonNoFreeze.comic.creator.verified =
        comicInfo.creator.verified;
    comicAllInfoJsonNoFreeze.comic.creator.exp = comicInfo.creator.exp;
    comicAllInfoJsonNoFreeze.comic.creator.level = comicInfo.creator.level;
    comicAllInfoJsonNoFreeze.comic.creator.role = comicInfo.creator.role;
    if (getCoverSuccess) {
      comicAllInfoJsonNoFreeze.comic.creator.avatar.fileServer =
          comicInfo.creator.avatar.fileServer;
      comicAllInfoJsonNoFreeze.comic.creator.avatar.path =
          comicInfo.creator.avatar.path;
      comicAllInfoJsonNoFreeze.comic.creator.avatar.originalName =
          comicInfo.creator.avatar.originalName;
    } else {
      comicAllInfoJsonNoFreeze.comic.creator.avatar.fileServer = "";
      comicAllInfoJsonNoFreeze.comic.creator.avatar.path = "";
      comicAllInfoJsonNoFreeze.comic.creator.avatar.originalName = "";
    }
    comicAllInfoJsonNoFreeze.comic.creator.characters =
        comicInfo.creator.characters;
    comicAllInfoJsonNoFreeze.comic.creator.title = comicInfo.creator.title;
    comicAllInfoJsonNoFreeze.comic.creator.slogan = comicInfo.creator.slogan;
    comicAllInfoJsonNoFreeze.comic.title = comicInfo.title;
    comicAllInfoJsonNoFreeze.comic.description = comicInfo.description;
    comicAllInfoJsonNoFreeze.comic.thumb.fileServer =
        comicInfo.thumb.fileServer;
    comicAllInfoJsonNoFreeze.comic.thumb.path = comicInfo.thumb.path;
    comicAllInfoJsonNoFreeze.comic.thumb.originalName =
        comicInfo.thumb.originalName;
    comicAllInfoJsonNoFreeze.comic.author = comicInfo.author;
    comicAllInfoJsonNoFreeze.comic.chineseTeam = comicInfo.chineseTeam;
    comicAllInfoJsonNoFreeze.comic.categories = comicInfo.categories;
    comicAllInfoJsonNoFreeze.comic.tags = comicInfo.tags;
    comicAllInfoJsonNoFreeze.comic.totalComments = comicInfo.totalComments;
    comicAllInfoJsonNoFreeze.comic.pagesCount = comicInfo.pagesCount;
    comicAllInfoJsonNoFreeze.comic.epsCount = comicInfo.epsCount;
    comicAllInfoJsonNoFreeze.comic.finished = comicInfo.finished;
    comicAllInfoJsonNoFreeze.comic.updatedAt = comicInfo.updatedAt;
    comicAllInfoJsonNoFreeze.comic.createdAt = comicInfo.createdAt;
    comicAllInfoJsonNoFreeze.comic.allowDownload = comicInfo.allowDownload;
    comicAllInfoJsonNoFreeze.comic.allowComment = comicInfo.allowComment;
    comicAllInfoJsonNoFreeze.comic.totalLikes = comicInfo.totalLikes;
    comicAllInfoJsonNoFreeze.comic.totalViews = comicInfo.totalViews;
    comicAllInfoJsonNoFreeze.comic.totalComments = comicInfo.totalComments;
    comicAllInfoJsonNoFreeze.comic.viewsCount = comicInfo.viewsCount;
    comicAllInfoJsonNoFreeze.comic.likesCount = comicInfo.likesCount;
    comicAllInfoJsonNoFreeze.comic.commentsCount = comicInfo.commentsCount;
    comicAllInfoJsonNoFreeze.comic.isFavourite = comicInfo.isFavourite;
    comicAllInfoJsonNoFreeze.comic.isLiked = comicInfo.isLiked;
    comicAllInfoJsonNoFreeze.eps = eps;

    var comicAllInfoStr = json.encode(comicAllInfoJsonNoFreeze.toJson());

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
      downloadTime: DateTime.now(),
      epsTitle: epsTitle,
      comicInfoAll: comicAllInfoStr,
    );

    var temp = objectbox.bikaDownloadBox
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

    // var temp = await objectbox.bikaDownloadBox.getAllAsync();
    // for (var item in temp) {
    //   debugPrint(item.toString());
    // }
    // TODO: 下载完成后检查一下有什么变动，删掉现在不需要的图片
  }
}
