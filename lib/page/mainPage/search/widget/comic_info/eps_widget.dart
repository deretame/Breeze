import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zephyr/type/comic_ep_info.dart';
import 'package:zephyr/util/router.dart';

import '../../../../../json/comic/comic_info.dart';
import '../../../../../json/comic/eps.dart';
import '../../../../../network/http/http_request.dart';
import '../../../../../type/stack.dart';
import '../../../../../util/state_management.dart';

class EpsWidget extends StatefulWidget {
  final ComicInfo comicInfo;

  const EpsWidget({super.key, required this.comicInfo});

  @override
  State<EpsWidget> createState() => _EpWidgetState();
}

class _EpWidgetState extends State<EpsWidget> {
  ComicInfo get comicInfo => widget.comicInfo;
  late Future<List<Doc>> _fetchEp;

  @override
  void initState() {
    super.initState();
    _fetchEp = fetchEp();
  }

  // 获取章节列表并正序
  Future<List<Doc>> fetchEp() async {
    List<Doc> eps = [];
    StackList epsStack = StackList();
    for (int i = 1; i <= (comicInfo.comic.epsCount / 40 + 1); i++) {
      var result = await getEps(comicInfo.comic.id, i);
      if (result['error'] != null) {
        throw Exception(result);
      } else {
        epsStack.push(Eps.fromJson(result));
      }
    }

    if (epsStack.isEmpty) {
      throw Exception("No Episodes Found");
    }

    List<Eps> epsList = [];
    while (epsStack.isNotEmpty) {
      epsList.add(epsStack.pop());
    }

    if (epsList.isEmpty) {
      throw Exception("No Episodes Found");
    }

    while (epsList.isNotEmpty) {
      Eps ep = epsList.removeAt(0);
      StackList epStackList = StackList();
      for (int i = 0; i < ep.eps.docs.length; i++) {
        epStackList.push(ep.eps.docs[i]);
      }

      while (epStackList.isNotEmpty) {
        eps.add(epStackList.pop());
      }
    }

    return eps;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Doc>>(
      future: _fetchEp,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _fetchEp =
                          fetchEp(); // 更新 _fetchEp 变量以触发 FutureBuilder 重建
                    });
                  },
                  child: const Text('重新加载'),
                ),
              ],
            ),
          );
        } else if (snapshot.hasData) {
          List<Doc> docs = snapshot.data!;
          return Column(
            children: [
              // 使用 map 和 Padding 创建 EpButton 列表
              ...docs.map(
                (doc) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: EpButtonWidget(doc: doc, comicInfo: comicInfo),
                ),
              ),
            ],
          );
        } else {
          return const Center(child: Text('No Episodes Found'));
        }
      },
    );
  }
}

class EpButtonWidget extends ConsumerStatefulWidget {
  final Doc doc;
  final ComicInfo comicInfo;

  const EpButtonWidget({super.key, required this.doc, required this.comicInfo});

  @override
  ConsumerState<EpButtonWidget> createState() => _EpButtonWidgetState();
}

class _EpButtonWidgetState extends ConsumerState<EpButtonWidget> {
  Doc get doc => widget.doc;

  ComicInfo get comicInfo => widget.comicInfo;

  String timeDecode(DateTime originalTime) {
    DateTime newDateTime = originalTime.add(const Duration(hours: 8));
    String formattedTime =
        '${newDateTime.year}年${newDateTime.month}月${newDateTime.day}日 ${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}:${newDateTime.second.toString().padLeft(2, '0')}';
    return "$formattedTime 更新";
  }

  @override
  Widget build(BuildContext context) {
    final colorNotifier = ref.watch(defaultColorProvider);
    colorNotifier.initialize(context);

    var comicInfoPage = ComicEpInfo(
        comicId: comicInfo.comic.id,
        title: doc.title,
        order: doc.order,
        updatedAt: doc.updatedAt,
        id: doc.id);

    return InkWell(
      onTap: () {
        navigateTo(context, '/comic', extra: comicInfoPage);
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 0),
        // Add horizontal margin
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorNotifier.defaultBackgroundColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: colorNotifier.themeType
                  ? Colors.black.withOpacity(0.2)
                  : Colors.white.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              doc.title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Row(
              children: <Widget>[
                Text(
                  timeDecode(doc.updatedAt),
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Expanded(
                  child: Container(),
                ),
                Text(
                  ' 第${doc.order}话',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
