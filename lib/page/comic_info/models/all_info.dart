import 'package:zephyr/page/comic_info/json/bika/comic_info/comic_info.dart'
    show Comic;
import 'package:zephyr/page/comic_info/json/bika/eps/eps.dart' show Doc;
import 'package:zephyr/page/comic_info/json/bika/recommend/recommend_json.dart'
    as recommend_json;

class AllInfo {
  Comic comicInfo;
  List<Doc> eps;
  List<recommend_json.Comic> recommendJson;

  AllInfo({
    required this.comicInfo,
    required this.eps,
    required this.recommendJson,
  });
}
