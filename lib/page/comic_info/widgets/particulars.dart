import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/page/comic_info/comic_info.dart';

import '../../../config/global.dart';
import '../../../main.dart';
import '../../../util/router/router.gr.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';
import '../../search_result/models/search_enter.dart';
import '../json/comic_info/comic_info.dart';

// 显示漫画的一些信息
// 封面，名字，作家，汉化组，收藏人数，章节信息
class ComicParticularsWidget extends StatelessWidget {
  final Comic comicInfo;

  const ComicParticularsWidget({super.key, required this.comicInfo});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: screenWidth * (48 / 50),
      child: Observer(
        builder: (context) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Cover(
                pictureInfo: PictureInfo(
                  from: "bika",
                  url: comicInfo.thumb.fileServer,
                  path: comicInfo.thumb.path,
                  chapterId: comicInfo.id,
                  pictureType: "cover",
                ),
              ),
              SizedBox(width: screenWidth / 60),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SelectableText(
                      comicInfo.title,
                      style: TextStyle(
                        color: globalSetting.textColor,
                        fontSize: 18,
                      ),
                    ),
                    if (comicInfo.author != '') ...[
                      const SizedBox(height: 2),
                      InkWell(
                        onTap: () {
                          AutoRouter.of(context).push(
                            SearchResultRoute(
                              searchEnterConst:
                                  SearchEnterConst(keyword: comicInfo.author),
                            ),
                          );
                        },
                        onLongPress: () {
                          // 长按时触发的事件
                          Clipboard.setData(
                              ClipboardData(text: comicInfo.author));
                          EasyLoading.showSuccess(
                              "已将${comicInfo.author}复制到剪贴板");
                        },
                        child: Text(
                          '作者：${comicInfo.author}',
                          style: TextStyle(
                            color: globalSetting.themeType
                                ? Colors.red
                                : Colors.yellow,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    if (comicInfo.chineseTeam != "") ...[
                      InkWell(
                        onTap: () {
                          // 点击时触发的事件
                          var enter = SearchEnter();
                          enter.keyword = comicInfo.chineseTeam;
                          AutoRouter.of(context).push(
                            SearchResultRoute(
                              searchEnterConst:
                                  SearchEnterConst(keyword: comicInfo.author),
                            ),
                          );
                        },
                        onLongPress: () {
                          // 长按时触发的事件
                          Clipboard.setData(
                              ClipboardData(text: comicInfo.chineseTeam));
                          EasyLoading.showSuccess(
                              "已将${comicInfo.chineseTeam}复制到剪贴板");
                        },
                        child: Text(
                          '汉化组：${comicInfo.chineseTeam}',
                          style: TextStyle(
                            color: globalSetting.themeType
                                ? Colors.blue.shade300
                                : Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ],
                    Text("页数：${comicInfo.pagesCount}"),
                    const SizedBox(height: 2),
                    Text("章节数：${comicInfo.epsCount}"),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}