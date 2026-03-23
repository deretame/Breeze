import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/bika/http_request.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/json/bika/comic_info/comic_info.dart';
import 'package:zephyr/page/comic_info/json/bika/eps/eps.dart' show Doc, Eps;
import 'package:zephyr/page/comic_info/json/bika/recommend/recommend_json.dart'
    as recommend_json;
import 'package:zephyr/page/comic_info/models/all_info.dart';
import 'package:zephyr/type/enum.dart';

Future<AllInfo> getBikaComicAllInfo(String comicId, ComicEntryType type) async {
  if (type == ComicEntryType.download) {
    return await _getBikaComicAllInfoFromLocal(comicId);
  }

  var result = await getComicInfo(comicId);

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

  var comicInfo = ComicInfo.fromJson(result);

  final [eps, recommendJson] = await Future.wait([
    _getEps(comicInfo.data.comic),
    _fetchRecommend(comicId),
  ]);
  return AllInfo(
    comicInfo: comicInfo.data.comic,
    eps: eps as List<Doc>,
    recommendJson: recommendJson as List<recommend_json.Comic>,
  );
}

Future<List<Doc>> _getEps(Comic comic) async {
  List<Doc> eps = [];

  // 计算需要请求的页数
  int totalPages = (comic.epsCount / 40 + 1).ceil();

  // 创建一个Future列表，用于并行请求
  List<Future<Map<String, dynamic>>> futures = [];
  for (int i = 1; i <= totalPages; i++) {
    futures.add(getEps(comic.id, i));
  }

  // 并行执行所有请求
  List<Map<String, dynamic>> results = await Future.wait(futures);

  // 处理结果
  for (var result in results) {
    for (var ep in Eps.fromJson(result).data.eps.docs) {
      eps.add(ep);
    }
  }

  eps.sort((a, b) => a.order.compareTo(b.order));
  return eps;
}

Future<List<recommend_json.Comic>> _fetchRecommend(String comicId) async {
  final result = await getRecommend(comicId);

  final comics = result['data']['comics'] as List;

  List<recommend_json.Comic> comicList = [];
  for (var comic in comics) {
    comic['author'] ??= '';
    if (comic['likesCount'] is String) {
      comic['likesCount'] = int.parse(comic['likesCount']);
    }
    comic['thumb'] ??= {"fileServer": "", "path": "", "originalName": ""};
    comic['thumb']['fileServer'] ??= '';
    comic['thumb']['path'] ??= '';
    comic['thumb']['originalName'] ??= '';
  }
  final temp = recommend_json.RecommendJson.fromJson(result);
  for (var comic in temp.data.comics) {
    comicList.add(comic);
  }
  return comicList;
}

Future<AllInfo> _getBikaComicAllInfoFromLocal(String comicId) async {
  var comicDownload = objectbox.unifiedDownloadBox
      .query(UnifiedComicDownload_.uniqueKey.equals('bika:$comicId'))
      .build()
      .findFirst()!;

  final comic = ComicInfo.fromJson({
    'data': {
      'comic': {
        '_id': comicId,
        '_creator': {
          '_id': (comicDownload.creator ?? const {})['id'] ?? '',
          'gender': '',
          'name': (comicDownload.creator ?? const {})['name'] ?? '',
          'verified': false,
          'exp': 0,
          'level': 0,
          'characters': const <String>[],
          'role': '',
          'avatar': {
            'fileServer': ((comicDownload.creator ?? const {})['avatar'] as Map?)?['url'] ?? '',
            'path': (((comicDownload.creator ?? const {})['avatar'] as Map?)?['extension'] as Map?)?['path'] ?? '',
            'originalName': ((comicDownload.creator ?? const {})['avatar'] as Map?)?['name'] ?? '',
          },
          'title': '',
          'slogan': '',
        },
        'title': comicDownload.title,
        'description': comicDownload.description,
        'thumb': {
          'fileServer': ((comicDownload.cover ?? const {})['extension'] as Map?)?['fileServer'] ?? (comicDownload.cover ?? const {})['url'] ?? '',
          'path': ((comicDownload.cover ?? const {})['extension'] as Map?)?['path'] ?? '',
          'originalName': (comicDownload.cover ?? const {})['name'] ?? '',
        },
        'author': '',
        'chineseTeam': '',
        'categories': const <String>[],
        'tags': const <String>[],
        'pagesCount': 0,
        'epsCount': (comicDownload.chapters ?? const []).length,
        'finished': false,
        'updated_at': comicDownload.updatedAt.toIso8601String(),
        'created_at': comicDownload.createdAt.toIso8601String(),
        'allowDownload': comicDownload.allowDownload,
        'allowComment': comicDownload.allowComment,
        'totalLikes': comicDownload.totalLikes,
        'totalViews': comicDownload.totalViews,
        'totalComments': comicDownload.totalComments,
        'viewsCount': comicDownload.totalViews,
        'likesCount': comicDownload.totalLikes,
        'commentsCount': comicDownload.totalComments,
        'isFavourite': comicDownload.isFavourite,
        'isLiked': comicDownload.isLiked,
      },
    },
  }).data.comic;

  final epsDoc = (comicDownload.chapters ?? const <Map<String, dynamic>>[]);

  var epsInfo = <Doc>[];
  for (var epDoc in epsDoc) {
    epsInfo.add(
      Doc(
        id: epDoc['id']?.toString() ?? '',
        title: epDoc['name']?.toString() ?? '',
        order: (epDoc['order'] as num?)?.toInt() ?? 0,
        updatedAt: comicDownload.updatedAt,
        docId: epDoc['extension'] is Map
            ? (epDoc['extension'] as Map)['docId']?.toString() ?? ''
            : '',
      ),
    );
  }

  return AllInfo(comicInfo: comic, eps: epsInfo, recommendJson: []);
}
