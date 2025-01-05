class MediaInfoAll {
  final String originalName;
  final String path;
  final String fileServer;
  final String epId;

  MediaInfoAll({
    required this.originalName,
    required this.path,
    required this.fileServer,
    required this.epId,
  });
}
//
// void downloadComic(String comicId) async {
//   // 确保初始化
//   f.WidgetsFlutterBinding.ensureInitialized();
//   late final ObjectBox objectbox;
//   objectbox = await ObjectBox.create();
//   var status = await Permission.notification.status;
//   if (!status.isDenied) {
//     EasyLoading.showInfo("请授予通知权限！");
//   }
//   final random = Random();
//   int notificationId = random.nextInt(1 << 32);
//
//   // 初始化
//   FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings(
//     'app_icon',
//   );
//
//   const InitializationSettings initializationSettings =
//       InitializationSettings(android: initializationSettingsAndroid);
//   flutterLocalNotificationsPlugin.initialize(initializationSettings);
//
//   const channelId = 'com.zephyr.breeze.downloadComic';
//   const channelName = '下载漫画';
//   const channelDescription = '下载进度通知';
//
//   AndroidNotificationDetails androidNotificationDetails =
//       AndroidNotificationDetails(
//     channelId,
//     channelName,
//     channelDescription: channelDescription,
//     importance: Importance.defaultImportance,
//   );
//   NotificationDetails notificationDetails =
//       NotificationDetails(android: androidNotificationDetails);
//   await flutterLocalNotificationsPlugin.show(
//     notificationId,
//     '下载中',
//     '正在获取漫画信息，请稍候...',
//     notificationDetails,
//   );
//
//   final dio = Dio();
//
//   ComicInfo comicInfo;
//   List<Doc> eps = [];
//   List<MediaInfoAll> mediaList = [];
//   bool downloadCoverSuccess = false;
//   int downloadCount = 0;
//
//   // 先获取一下漫画自己的信息
//   while (true) {
//     try {
//       var result = await getComicInfo(comicId, dio: dio);
//
//       // 打补丁
//       result['data']['comic']['_creator']['slogan'] ??= "";
//       result['data']['comic']['_creator']['title'] ??= '';
//       result['data']['comic']['_creator']['verified'] ??= false;
//       result['data']['comic']['chineseTeam'] ??= "";
//       result['data']['comic']['description'] ??= "";
//       result['data']['comic']['totalComments'] ??=
//           result['data']['comic']['commentsCount'] ?? 0;
//       result['data']['comic']['author'] ??= '';
//       result['data']['comic']['_creator']
//           ['avatar'] ??= {"fileServer": "", "path": "", "originalName": ""};
//
//       comicInfo = ComicInfo.fromJson(result);
//
//       break;
//     } catch (e) {
//       f.debugPrint(e.toString());
//     }
//   }
//
//   while (true) {
//     try {
//       // var filePath = await
//       downloadPicture(
//         from: 'bika',
//         url: comicInfo.data.comic.thumb.fileServer,
//         path: comicInfo.data.comic.thumb.path,
//         cartoonId: comicInfo.data.comic.id,
//         pictureType: 'cover',
//         chapterId: '',
//       );
//       downloadCoverSuccess = true;
//       break;
//     } catch (e) {
//       f.debugPrint(e.toString());
//       if (e.toString().contains("404")) {
//         break;
//       }
//     }
//   }
//
//   comic_all_info_json_no_freeze.Eps tempEps =
//       comic_all_info_json_no_freeze.Eps.empty();
//   // 获取章节的信息
//   while (true) {
//     try {
//       StackList epsStack = StackList();
//       for (int i = 1; i <= (comicInfo.data.comic.epsCount / 40 + 1); i++) {
//         var result = await getEps(comicInfo.data.comic.id, i, dio: dio);
//         epsStack.push(Eps.fromJson(result).data.eps);
//       }
//
//       if (epsStack.isEmpty) {
//         throw Exception("获取数据失败");
//       }
//
//       List<EpsClass> epsList = [];
//       while (epsStack.isNotEmpty) {
//         epsList.add(epsStack.pop());
//       }
//
//       if (epsList.isEmpty) {
//         throw Exception("获取数据失败");
//       }
//
//       while (epsList.isNotEmpty) {
//         EpsClass ep = epsList.removeAt(0);
//         StackList epStackList = StackList();
//         for (int i = 0; i < ep.docs.length; i++) {
//           epStackList.push(ep.docs[i]);
//         }
//         while (epStackList.isNotEmpty) {
//           var epDoc = epStackList.pop() as Doc;
//           eps.add(epDoc);
//           tempEps.add(
//             comic_all_info_json_no_freeze.EpsDoc(
//               id: epDoc.id,
//               title: epDoc.title,
//               order: epDoc.order,
//               updatedAt: epDoc.updatedAt,
//               docId: epDoc.docId,
//               pages: comic_all_info_json_no_freeze.Pages.empty(),
//             ),
//           );
//         }
//       }
//       break;
//     } catch (e) {
//       f.debugPrint(e.toString());
//     }
//   }
//
//   // 获取所有章节的图片信息
//   for (var ep in eps) {
//     int page = 1, pages = 1;
//     while (true) {
//       try {
//         comic_all_info_json_no_freeze.Pages pagesDocs =
//             comic_all_info_json_no_freeze.Pages.empty();
//         do {
//           var result = await getPages(comicId, ep.order, page,
//               dio: dio, imageQuality: "original");
//           var temp = comic_page_json.Page.fromJson(result);
//           page += 1;
//           pages = temp.data.pages.pages;
//           for (var doc in temp.data.pages.docs) {
//             mediaList.add(
//               MediaInfoAll(
//                 originalName: doc.media.originalName,
//                 path: doc.media.path,
//                 fileServer: doc.media.fileServer,
//                 epId: ep.id,
//               ),
//             );
//             pagesDocs.add(
//               comic_all_info_json_no_freeze.PagesDoc(
//                 id: doc.id,
//                 media: comic_all_info_json_no_freeze.Thumb(
//                   originalName: doc.media.originalName,
//                   path: doc.media.path,
//                   fileServer: doc.media.fileServer,
//                 ),
//                 docId: doc.docId,
//               ),
//             );
//           }
//         } while (page <= pages);
//         tempEps[ep.order - 1].pages = pagesDocs;
//         break;
//       } catch (e) {
//         f.debugPrint(e.toString());
//       }
//     }
//   }
//
//   final List<Future<void>> downloadTasks = mediaList.map((media) async {
//     var temp = await downloadPicture(
//       from: 'bika',
//       url: media.fileServer,
//       path: media.path,
//       cartoonId: comicInfo.data.comic.id,
//       pictureType: 'comic',
//       chapterId: media.epId,
//     ).catchError((e) {
//       f.debugPrint('Error downloading ${media.fileServer}: $e');
//       return "";
//     });
//     downloadCount += 1;
//
//     // 更新通知的进度
//     await flutterLocalNotificationsPlugin.show(
//       notificationId,
//       '正在下载漫画',
//       '下载进度：${(downloadCount / mediaList.length * 100.0).toStringAsFixed(2)}%',
//       notificationDetails,
//     );
//
//     return temp;
//   }).toList();
//
//   await Future.wait(downloadTasks);
//
//   // 创建一个空的 ComicAllInfoJsonNoFreeze 实例
//   comic_all_info_json_no_freeze.ComicAllInfoJsonNoFreeze
//       comicAllInfoJsonNoFreeze =
//       comic_all_info_json_no_freeze.ComicAllInfoJsonNoFreeze.empty();
//
//   comicAllInfoJsonNoFreeze.comic.id = comicInfo.data.comic.id;
//   comicAllInfoJsonNoFreeze.comic.creator.id = comicInfo.data.comic.creator.id;
//   comicAllInfoJsonNoFreeze.comic.creator.gender =
//       comicInfo.data.comic.creator.gender;
//   comicAllInfoJsonNoFreeze.comic.creator.name =
//       comicInfo.data.comic.creator.name;
//   comicAllInfoJsonNoFreeze.comic.creator.verified =
//       comicInfo.data.comic.creator.verified;
//   comicAllInfoJsonNoFreeze.comic.creator.exp = comicInfo.data.comic.creator.exp;
//   comicAllInfoJsonNoFreeze.comic.creator.level =
//       comicInfo.data.comic.creator.level;
//   comicAllInfoJsonNoFreeze.comic.creator.role =
//       comicInfo.data.comic.creator.role;
//   if (downloadCoverSuccess) {
//     comicAllInfoJsonNoFreeze.comic.creator.avatar.fileServer =
//         comicInfo.data.comic.creator.avatar.fileServer;
//     comicAllInfoJsonNoFreeze.comic.creator.avatar.path =
//         comicInfo.data.comic.creator.avatar.path;
//     comicAllInfoJsonNoFreeze.comic.creator.avatar.originalName =
//         comicInfo.data.comic.creator.avatar.originalName;
//   } else {
//     comicAllInfoJsonNoFreeze.comic.creator.avatar.fileServer = "";
//     comicAllInfoJsonNoFreeze.comic.creator.avatar.path = "";
//     comicAllInfoJsonNoFreeze.comic.creator.avatar.originalName = "";
//   }
//   comicAllInfoJsonNoFreeze.comic.creator.characters =
//       comicInfo.data.comic.creator.characters;
//   comicAllInfoJsonNoFreeze.comic.creator.title =
//       comicInfo.data.comic.creator.title;
//   comicAllInfoJsonNoFreeze.comic.title = comicInfo.data.comic.title;
//   comicAllInfoJsonNoFreeze.comic.description = comicInfo.data.comic.description;
//   comicAllInfoJsonNoFreeze.comic.thumb.fileServer =
//       comicInfo.data.comic.thumb.fileServer;
//   comicAllInfoJsonNoFreeze.comic.thumb.path = comicInfo.data.comic.thumb.path;
//   comicAllInfoJsonNoFreeze.comic.thumb.originalName =
//       comicInfo.data.comic.thumb.originalName;
//   comicAllInfoJsonNoFreeze.comic.author = comicInfo.data.comic.author;
//   comicAllInfoJsonNoFreeze.comic.chineseTeam = comicInfo.data.comic.chineseTeam;
//   comicAllInfoJsonNoFreeze.comic.tags = comicInfo.data.comic.tags;
//   comicAllInfoJsonNoFreeze.comic.totalComments =
//       comicInfo.data.comic.totalComments;
//   comicAllInfoJsonNoFreeze.comic.epsCount = comicInfo.data.comic.epsCount;
//   comicAllInfoJsonNoFreeze.comic.finished = comicInfo.data.comic.finished;
//   comicAllInfoJsonNoFreeze.comic.updatedAt = comicInfo.data.comic.updatedAt;
//   comicAllInfoJsonNoFreeze.comic.createdAt = comicInfo.data.comic.createdAt;
//   comicAllInfoJsonNoFreeze.comic.allowDownload =
//       comicInfo.data.comic.allowDownload;
//   comicAllInfoJsonNoFreeze.comic.allowComment =
//       comicInfo.data.comic.allowComment;
//   comicAllInfoJsonNoFreeze.comic.totalLikes = comicInfo.data.comic.totalLikes;
//   comicAllInfoJsonNoFreeze.comic.totalViews = comicInfo.data.comic.totalViews;
//   comicAllInfoJsonNoFreeze.comic.totalComments =
//       comicInfo.data.comic.totalComments;
//   comicAllInfoJsonNoFreeze.comic.viewsCount = comicInfo.data.comic.viewsCount;
//   comicAllInfoJsonNoFreeze.comic.likesCount = comicInfo.data.comic.likesCount;
//   comicAllInfoJsonNoFreeze.comic.commentsCount =
//       comicInfo.data.comic.commentsCount;
//   comicAllInfoJsonNoFreeze.comic.isFavourite = comicInfo.data.comic.isFavourite;
//   comicAllInfoJsonNoFreeze.comic.isLiked = comicInfo.data.comic.isLiked;
//   comicAllInfoJsonNoFreeze.eps = tempEps;
//
//   var comicAllInfoStr = json.encode(comicAllInfoJsonNoFreeze.toJson());
//
//   List<String> epsTitle = [];
//   for (int i = 1; i <= tempEps.length; i++) {
//     epsTitle.add(tempEps[i - 1].title);
//   }
//
//   // 保存到数据库
//   var bikaComicDownload = BikaComicDownload(
//     comicId: comicInfo.data.comic.id,
//     creatorId: comicInfo.data.comic.creator.id,
//     creatorGender: comicInfo.data.comic.creator.gender,
//     creatorName: comicInfo.data.comic.creator.name,
//     creatorVerified: comicInfo.data.comic.creator.verified,
//     creatorExp: comicInfo.data.comic.creator.exp,
//     creatorLevel: comicInfo.data.comic.creator.level,
//     creatorCharacters: comicInfo.data.comic.creator.characters,
//     creatorCharactersString: comicInfo.data.comic.creator.characters.join(","),
//     creatorRole: comicInfo.data.comic.creator.role,
//     creatorTitle: comicInfo.data.comic.creator.title,
//     creatorAvatarOriginalName: comicInfo.data.comic.creator.avatar.originalName,
//     creatorAvatarPath: comicInfo.data.comic.creator.avatar.path,
//     creatorAvatarFileServer: comicInfo.data.comic.creator.avatar.fileServer,
//     creatorSlogan: comicInfo.data.comic.creator.slogan,
//     title: comicInfo.data.comic.title,
//     description: comicInfo.data.comic.description,
//     thumbOriginalName: comicInfo.data.comic.thumb.originalName,
//     thumbPath: comicInfo.data.comic.thumb.path,
//     thumbFileServer: comicInfo.data.comic.thumb.fileServer,
//     author: comicInfo.data.comic.author,
//     chineseTeam: comicInfo.data.comic.chineseTeam,
//     categories: comicInfo.data.comic.categories,
//     categoriesString: comicInfo.data.comic.categories.join(","),
//     tags: comicInfo.data.comic.tags,
//     tagsString: comicInfo.data.comic.tags.join(","),
//     pagesCount: comicInfo.data.comic.pagesCount,
//     epsCount: comicInfo.data.comic.epsCount,
//     finished: comicInfo.data.comic.finished,
//     updatedAt: comicInfo.data.comic.updatedAt,
//     createdAt: comicInfo.data.comic.createdAt,
//     allowDownload: comicInfo.data.comic.allowDownload,
//     allowComment: comicInfo.data.comic.allowComment,
//     totalLikes: comicInfo.data.comic.totalLikes,
//     totalViews: comicInfo.data.comic.totalViews,
//     totalComments: comicInfo.data.comic.totalComments,
//     viewsCount: comicInfo.data.comic.viewsCount,
//     likesCount: comicInfo.data.comic.likesCount,
//     commentsCount: comicInfo.data.comic.commentsCount,
//     isFavourite: comicInfo.data.comic.isFavourite,
//     isLiked: comicInfo.data.comic.isLiked,
//     downloadTime: DateTime.now(),
//     epsTitle: [],
//     comicInfoAll: comicAllInfoStr,
//   );
//
//   objectbox.bikaDownloadBox.put(bikaComicDownload);
//
//   await flutterLocalNotificationsPlugin.show(
//     notificationId,
//     '下载完成',
//     '所有漫画下载完成。',
//     notificationDetails,
//   );
//
//   return;
// }
