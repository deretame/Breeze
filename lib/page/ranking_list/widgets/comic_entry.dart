import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/page/ranking_list/widgets/comic_picture.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/util/sundry.dart';

import '../../../config/global/global.dart';
import '../../../main.dart';
import '../../../type/enum.dart';
import '../json/leaderboard.dart';

class ComicEntryWidget extends StatefulWidget {
  final String type;
  final Comic comic;

  const ComicEntryWidget({super.key, required this.type, required this.comic});

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
      _type = "24小时观看量";
    } else if (type == "D7") {
      _type = "一周观看量";
    } else if (type == "D30") {
      _type = "一月观看量";
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 跳转到漫画详情页
        context.pushRoute(
          ComicInfoRoute(comicId: comic.id, type: ComicEntryType.normal),
        );
      },
      child: Column(
        children: <Widget>[
          SizedBox(height: (screenHeight / 10) * 0.1),
          Observer(
            builder: (context) {
              return Container(
                height: 180,
                width: ((screenWidth / 10) * 9.5),
                margin: EdgeInsets.symmetric(
                  horizontal: (screenWidth / 10) * 0.25,
                ),
                decoration: BoxDecoration(
                  color: globalSetting.backgroundColor,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: materialColorScheme.secondaryFixedDim,
                      spreadRadius: 0,
                      blurRadius: 2,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    ComicPictureWidget(
                      fileServer: comic.thumb.fileServer,
                      path: comic.thumb.path,
                      id: comic.id,
                      pictureType: "cover",
                    ),
                    SizedBox(width: screenWidth / 60),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(height: screenWidth / 200),
                          Text(
                            comic.title,
                            style: TextStyle(
                              color: globalSetting.textColor,
                              fontSize: 18,
                            ),
                            maxLines: 3, // 最大行数
                            overflow: TextOverflow.ellipsis, // 超出时使用省略号
                          ),
                          if (comic.author.toString() != '') ...[
                            const SizedBox(height: 4),
                            Text(
                              _getLimitedTitle(comic.author.toString(), 40),
                              style: TextStyle(
                                color: materialColorScheme.primary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 5),
                          Text(
                            _getCategories(comic.categories),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(color: globalSetting.textColor),
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
                              SizedBox(width: 10.0),
                              Text(
                                comic.finished ? "完结" : "",
                                style: TextStyle(
                                  color: materialColorScheme.tertiary,
                                ),
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
              );
            },
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
      return "分类: ${temp.let(t2s)}";
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
