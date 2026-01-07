import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/bika/http_request.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/json/bika/comic_info/comic_info.dart';
import 'package:zephyr/page/comic_info/json/bika/eps/eps.dart' show Doc, Eps;
import 'package:zephyr/page/comic_info/json/bika/recommend/recommend_json.dart'
    as recommend_json;
import 'package:zephyr/page/comic_info/method/type_conversion.dart';
import 'package:zephyr/page/comic_info/models/all_info.dart';
import 'package:zephyr/page/download/json/comic_all_info_json/comic_all_info_json.dart'
    as bika_download;
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
  var comicDownload = objectbox.bikaDownloadBox
      .query(BikaComicDownload_.comicId.equals(comicId))
      .build()
      .findFirst()!;

  var comicAllInfo = bika_download.comicAllInfoJsonFromJson(
    comicDownload.comicInfoAll,
  );

  var comicInfo = comicAllInfo2Comic(comicAllInfo);
  var epsDoc = comicAllInfo.eps.docs;

  var epsInfo = <Doc>[];
  for (var epDoc in epsDoc) {
    epsInfo.add(
      Doc(
        id: epDoc.id,
        title: epDoc.title,
        order: epDoc.order,
        updatedAt: epDoc.updatedAt,
        docId: epDoc.docId,
      ),
    );
  }

  return AllInfo(comicInfo: comicInfo, eps: epsInfo, recommendJson: []);
}
