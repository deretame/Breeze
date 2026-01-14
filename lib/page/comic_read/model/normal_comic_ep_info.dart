import 'package:zephyr/page/comic_read/json/common_ep_info_json/common_ep_info_json.dart';

class NormalComicEpInfo {
  int length;
  String epPages;
  List<Doc> docs;
  String epId;
  String epName;

  NormalComicEpInfo({
    this.length = 0,
    this.epPages = "0",
    this.docs = const [],
    this.epId = "",
    this.epName = "",
  });
}
