import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/type/comic_ep_info.dart';
import 'package:zephyr/util/router.dart';

import '../../../../../../json/comic/comic_info.dart';
import '../../../../../../json/comic/eps.dart';
import 'method.dart';

class EpsWidget extends StatelessWidget {
  final ComicInfo comicInfo;

  const EpsWidget({super.key, required this.comicInfo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EpsBloc(comicInfo: comicInfo),
      child: BlocBuilder<EpsBloc, EpsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.error}'),
                  ElevatedButton(
                    onPressed: () {
                      context.read<EpsBloc>().add(FetchEpsEvent());
                    },
                    child: const Text('重新加载'),
                  ),
                ],
              ),
            );
          } else if (state.eps.isNotEmpty) {
            return Column(
              children: [
                ...state.eps.map(
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
      ),
    );
  }
}

class EpButtonWidget extends StatelessWidget {
  final Doc doc;
  final ComicInfo comicInfo;

  const EpButtonWidget({
    super.key,
    required this.doc,
    required this.comicInfo,
  });

  String timeDecode(DateTime originalTime) {
    DateTime newDateTime = originalTime.add(const Duration(hours: 8));
    String formattedTime =
        '${newDateTime.year}年${newDateTime.month}月${newDateTime.day}日${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}:${newDateTime.second.toString().padLeft(2, '0')}';
    return "$formattedTime 更新";
  }

  @override
  Widget build(BuildContext context) {
    var comicInfoPage = ComicEpInfo(
      comicId: comicInfo.comic.id,
      title: doc.title,
      order: doc.order,
      updatedAt: doc.updatedAt,
      id: doc.id,
    );

    return InkWell(
      onTap: () {
        navigateTo(context, '/comic', extra: comicInfoPage);
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 0),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: globalSetting.backgroundColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: globalSetting.themeType
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
                Spacer(), // 使用 Spacer 来代替 Expanded 和 Container
                Text(
                  doc.order.toString(),
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
