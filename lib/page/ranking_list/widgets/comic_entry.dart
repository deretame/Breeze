import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/ranking_list/widgets/comic_picture.dart';
import 'package:zephyr/widgets/picture_bloc/picture_bloc.dart';

import '../../../config/global.dart';
import '../../../json/search_bar/hot_list.dart';
import '../../../main.dart';
import '../../../util/router.dart';

class ComicEntryWidget extends StatefulWidget {
  final String type;
  final Comic comic;

  const ComicEntryWidget({
    super.key,
    required this.type,
    required this.comic,
  });

  @override
  State<ComicEntryWidget> createState() => _ComicEntryWidgetState();
}

class _ComicEntryWidgetState extends State<ComicEntryWidget> {
  String get type => widget.type;

  late String _type;

  Comic get comic => widget.comic;

  @override
  initState() {
    if (type == "H24") {
      _type = "过去24小时观看量";
    } else if (type == "D7") {
      _type = "过去一周观看量";
    } else if (type == "D30") {
      _type = "过去一月观看量";
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // 跳转到漫画详情页
        navigateTo(context, '/comicInfo', extra: comic.id);
      },
      child: Column(
        children: <Widget>[
          SizedBox(height: (screenHeight / 10) * 0.1),
          Container(
            height: 180,
            width: ((screenWidth / 10) * 9.5),
            margin: EdgeInsets.symmetric(horizontal: (screenWidth / 10) * 0.25),
            decoration: BoxDecoration(
              color: globalSetting.backgroundColor,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: globalSetting.themeType
                      ? Colors.black.withOpacity(0.2)
                      : Colors.white.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                BlocProvider(
                  create: (_) => PictureBloc()
                    ..add(
                      GetPicture(
                        PictureInfo(
                          from: "bika",
                          url: comic.thumb.fileServer,
                          path: comic.thumb.path,
                          cartoonId: comic.id,
                          pictureType: "cover",
                        ),
                      ),
                    ),
                  child: ComicPictureWidget(
                    fileServer: comic.thumb.fileServer,
                    path: comic.thumb.path,
                    id: comic.id,
                    pictureType: "cover",
                  ),
                ),
                SizedBox(width: screenWidth / 60),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: screenWidth / 200),
                      RichText(
                        text: TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text: _getLimitedTitle(comic.title, 30),
                              style: TextStyle(
                                color: globalSetting.textColor,
                                fontSize: 18,
                              ),
                            ),
                            TextSpan(
                              text: comic.finished ? "(完)" : "",
                              style: TextStyle(
                                color: globalSetting.themeType
                                    ? Colors.red
                                    : Colors.yellow,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (comic.author.toString() != '') ...[
                        const SizedBox(height: 5),
                        Text(
                          _getLimitedTitle(comic.author.toString(), 40),
                          style: TextStyle(
                            color: globalSetting.themeType
                                ? Colors.red
                                : Colors.yellow,
                          ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      Text(
                        _getCategories(comic.categories),
                        style: TextStyle(
                          color: globalSetting.textColor,
                        ),
                      ),
                      Spacer(),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 24.0,
                          ),
                          // const SizedBox(width: 10.0),
                          Text(
                            "$_type：${comic.leaderboardCount.toString()}",
                          ),
                        ],
                      ),
                      SizedBox(height: screenWidth / 200),
                    ],
                  ),
                ),
                SizedBox(width: screenWidth / 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 截取部分分类
  String _getCategories(List<String>? categories) {
    int count = 0;
    int mainCount = 8;
    if (categories == null) {
      return "";
    } else {
      String temp = "";
      for (var category in categories) {
        temp += "$category ";
        count++;
        if (count == mainCount) {
          break;
        }
      }
      return "分类: $temp";
    }
  }

  // 截断过长的标题
  String _getLimitedTitle(String title, int maxLength) {
    if (title.length > maxLength) {
      return '${title.substring(0, maxLength)}...';
    }
    return title;
  }
}
