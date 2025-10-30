import 'package:flutter/cupertino.dart';

import '../json/bika/comic_info/comic_info.dart';

// 描述，或者说介绍？我不太清楚这玩意儿到底怎么分类
class SynopsisWidget extends StatelessWidget {
  final Comic comicInfo;

  const SynopsisWidget({super.key, required this.comicInfo});

  @override
  Widget build(BuildContext context) {
    return Text(comicInfo.description);
  }
}
