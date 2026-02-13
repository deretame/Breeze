import 'dart:convert';
import 'dart:io';

import 'package:flutter_socks_proxy/socks_proxy.dart';
import 'package:pool/pool.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/bika/http_request.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/json/bika/eps/eps.dart' as eps;
import 'package:zephyr/page/comic_read/json/bika_ep_info_json/page.dart' as p;
import 'package:zephyr/page/download/json/comic_all_info_json/comic_all_info_json.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/foreground_task/data/download_task_json.dart';
import 'package:zephyr/util/foreground_task/main_task.dart';
import 'package:zephyr/util/get_path.dart';

Future<void> bikaDownloadTask(MyTaskHandler self, DownloadTaskJson task) async {
  // 先获取一下基本的信息
  final authorization = task.bikaInfo.authorization;
  if (task.globalProxy.isNotEmpty) {
    SocksProxy.initProxy(proxy: 'SOCKS5 ${task.globalProxy}');
  }
  self.message = "获取漫画信息中...";
  final comicInfo = await _getComicInfo(task.comicId, authorization);
  self.message = "获取章节信息中...";
  final epsList = await _getEps(comicInfo, authorization, task.slowDownload);
  List<EpsDoc> epsDocs = [];
  List<Pages> imageData = [];
  List<String> epsTitle = [];

  for (var ep in task.selectedChapters) {
    final pages = await _fetchBKMedia(
      task.comicId,
      ep.let(toInt),
      authorization,
    );
    final epInfo = epsList.firstWhere(
      (element) => element.order.toString() == ep.toString(),
    );
    epsDocs.add(
      EpsDoc(
        id: epInfo.id,
        title: epInfo.title,
        order: epInfo.order,
        updatedAt: epInfo.updatedAt,
        docId: epInfo.id,
        pages: pages,
      ),
    );
    for (var page in pages.docs) {
      imageData.add(
        Pages(
          docs: [PagesDoc(id: page.id, media: page.media, docId: epInfo.id)],
        ),
      );
    }
    epsTitle.add(epInfo.title);
  }

  var comicAllInfoJson = ComicAllInfoJson(
    comic: comicInfo,
    eps: Eps(docs: epsDocs),
  );

  logger.d(comicInfo.toJson());

  final coverPath = await downloadPicture(
    from: From.bika,
    url: comicInfo.thumb.fileServer,
    path: comicInfo.thumb.path,
    cartoonId: comicInfo.id,
    pictureType: PictureType.cover,
    chapterId: comicInfo.id,
    proxy: task.bikaInfo.proxy.let(toInt),
  );

  if (coverPath.startsWith('404')) {
    comicAllInfoJson = comicAllInfoJson.copyWith(
      comic: comicAllInfoJson.comic.copyWith(
        thumb: comicAllInfoJson.comic.thumb.copyWith(fileServer: ""),
      ),
    );
  }

  List<PagesDoc> pagesDocs = [];

  for (var media in imageData) {
    for (var doc in media.docs) {
      pagesDocs.add(doc);
    }
  }

  if (task.slowDownload) {
    int progress = 0;
    for (var doc in pagesDocs) {
      await downloadPicture(
        from: From.bika,
        url: doc.media.fileServer,
        path: doc.media.path,
        cartoonId: comicInfo.id,
        pictureType: PictureType.comic,
        chapterId: doc.docId,
        proxy: task.bikaInfo.proxy.let(toInt),
      );
      progress++;
      self.message =
          "漫画下载进度: ${(progress / pagesDocs.length * 100).toStringAsFixed(2)}%";
    }
  } else {
    final pool = Pool(10);

    int progress = 0;
    int lastReportedPercent = 0;

    final List<Future<void>> downloadTasks = pagesDocs.map((doc) {
      return pool.withResource(() async {
        await downloadPicture(
          from: From.bika,
          url: doc.media.fileServer,
          path: doc.media.path,
          cartoonId: comicInfo.id,
          pictureType: PictureType.comic,
          chapterId: doc.docId,
          proxy: task.bikaInfo.proxy.let(toInt),
        );

        progress++;

        final int currentPercent = (progress / pagesDocs.length * 100).floor();
        if (currentPercent > lastReportedPercent) {
          lastReportedPercent = currentPercent;
          self.message = "漫画下载进度: $currentPercent%";
        }
      });
    }).toList();

    await Future.wait(downloadTasks);
  }

  await _saveToDB(comicAllInfoJson, epsTitle);

  await checkFile(comicAllInfoJson);
}

Future<Comic> _getComicInfo(String comicId, String authorization) async {
  Map<String, dynamic> result = {};
  while (true) {
    try {
      result = await getComicInfo(
        comicId,
        authorization: authorization,
        imageQuality: "original",
      );
      break;
    } catch (e, s) {
      logger.e(e, stackTrace: s);
    }
  }

  // 打补丁
  result['data']['comic']['_creator']['slogan'] ??= "";
  result['data']['comic']['_creator']['title'] ??= '';
  result['data']['comic']['_creator']['verified'] ??= false;
  result['data']['comic']['chineseTeam'] ??= "";
  result['data']['comic']['description'] ??= "";
  result['data']['comic']['totalComments'] ??=
      result['data']['comic']['commentsCount'] ?? 0;
  result['data']['comic']['author'] ??= '';
  result['data']['comic']['_creator']['avatar'] ??= {
    "fileServer": "",
    "path": "",
    "originalName": "",
  };

  var comicInfo = Comic.fromJson(result['data']['comic']);
  return comicInfo;
}

// 获取所有的章节基本信息
Future<List<eps.Doc>> _getEps(
  Comic comic,
  String authorization,
  bool slowDownload,
) async {
  List<eps.Doc> epsList = [];

  // 计算需要请求的页数
  int totalPages = (comic.epsCount / 40 + 1).ceil();

  List<Map<String, dynamic>> results = [];
  if (slowDownload) {
    for (int i = 1; i <= totalPages; i++) {
      while (true) {
        try {
          results.add(
            await getEps(
              comic.id,
              i,
              authorization: authorization,
              imageQuality: "original",
            ),
          );
          break;
        } catch (e, s) {
          logger.e(e, stackTrace: s);
        }
      }
    }
  } else {
    // 创建一个Future列表，用于并行请求
    List<Future<Map<String, dynamic>>> futures = [];
    for (int i = 1; i <= totalPages; i++) {
      futures.add(
        getEps(
          comic.id,
          i,
          authorization: authorization,
          imageQuality: "original",
        ),
      );
    }

    // 并行执行所有请求
    while (true) {
      try {
        results = await Future.wait(futures);
        break;
      } catch (e, s) {
        logger.e(e, stackTrace: s);
      }
    }
  }

  // 处理结果
  for (var result in results) {
    final data = eps.Eps.fromJson(result).data;
    for (var ep in data.eps.docs) {
      epsList.add(ep);
    }
  }

  epsList.sort((a, b) => a.order.compareTo(b.order));
  return epsList;
}

/// 获取到一个章节里面的所有图片
Future<Pages> _fetchBKMedia(
  String comicId,
  int epsId,
  String authorization,
) async {
  int page = 1;
  List<PagesDoc> pagesDocs = [];

  while (true) {
    Map<String, dynamic> result = {};
    try {
      result = await getPages(
        comicId,
        epsId,
        page,
        authorization: authorization,
        imageQuality: "original",
      );
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      continue;
    }
    var temp = p.Page.fromJson(result);
    for (var doc in temp.data.pages.docs) {
      pagesDocs.add(
        PagesDoc(
          id: doc.id,
          media: Thumb(
            originalName: doc.media.originalName,
            path: doc.media.path,
            fileServer: doc.media.fileServer,
          ),
          docId: doc.docId,
        ),
      );
    }
    if (page == temp.data.pages.pages) {
      break;
    }
    page += 1;
  }

  return Pages(docs: pagesDocs);
}

Future<void> _saveToDB(
  ComicAllInfoJson comicAllInfoJson,
  List<String> epsTitle,
) async {
  final comicInfo = comicAllInfoJson.comic;

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
    comicInfoAll: comicAllInfoJson.toJson().let(jsonEncode),
  );

  var temp = objectbox.bikaDownloadBox
      .query(BikaComicDownload_.comicId.equals(comicInfo.id))
      .build()
      .find();

  objectbox.bikaDownloadBox.removeMany(temp.map((e) => e.id).toList());

  await objectbox.bikaDownloadBox.putAsync(bikaComicDownload);
}

Future<void> checkFile(ComicAllInfoJson comicAllInfoJson) async {
  final comicInfo = comicAllInfoJson.comic;

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
  for (var element in comicAllInfoJson.eps.docs) {
    downloadEpsDir.add("$epsDir${element.id}");
  }

  // 过滤出需要删除的目录
  List<Directory> deleteDirs = epDirs.where((element) {
    return !downloadEpsDir.contains(element.path);
  }).toList();

  // 删除不需要的目录
  for (var element in deleteDirs) {
    await element.delete(recursive: true);
  }

  // 获取本次下载的图片
  List<String> originalPicturePaths = [];
  for (var element in comicAllInfoJson.eps.docs) {
    for (var page in element.pages.docs) {
      String sanitizedPath = page.media.path.replaceAll(
        RegExp(r'[^a-zA-Z0-9_\-.]'),
        '_',
      );
      var tempPath = "$epsDir${element.id}/$sanitizedPath";
      originalPicturePaths.add(tempPath);
    }
  }

  var allPicturePaths = await getAllFilePaths(epsDir);

  // 过滤出需要删除的图片
  List<String> deletePictures = allPicturePaths.where((element) {
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
