import 'package:zephyr/page/comic_info/json/bika/comic_info/comic_info.dart'
    show ComicInfo;
import 'package:zephyr/page/comic_info/json/bika/eps/eps.dart' show Doc;
import 'package:zephyr/page/comic_info/json/bika/recommend/recommend_json.dart'
    show Comic;

class AllInfo {
  ComicInfo? comicInfo;
  List<Doc>? eps;
  List<Comic>? recommendJson;

  AllInfo({this.comicInfo, this.eps, this.recommendJson});
}
