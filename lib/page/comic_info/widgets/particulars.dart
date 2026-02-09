import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/comic_info/comic_info.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    show ComicInfo;
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../widgets/picture_bloc/models/picture_info.dart';

// 显示漫画的一些信息
// 封面，名字，作家，汉化组，收藏人数，章节信息
class ComicParticularsWidget extends StatelessWidget {
  final ComicInfo comicInfo;
  final From from;

  const ComicParticularsWidget({
    super.key,
    required this.comicInfo,
    required this.from,
  });

  @override
  Widget build(BuildContext context) {
    final stringSelectDate = context.watch<StringSelectCubit>().state;

    late PictureInfo pictureInfo;
    if (from == From.jm) {
      pictureInfo = PictureInfo(
        from: 'jm',
        url: getJmCoverUrl(comicInfo.id),
        path: '${comicInfo.id}.jpg',
        cartoonId: comicInfo.id,
        pictureType: 'cover',
      );
    } else {
      pictureInfo = PictureInfo(
        from: "bika",
        url: comicInfo.cover.url,
        path: comicInfo.cover.path,
        chapterId: comicInfo.id,
        pictureType: "cover",
        cartoonId: comicInfo.id,
      );
    }

    return SizedBox(
      width: context.screenWidth * (48 / 50),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Cover(pictureInfo: pictureInfo),
          SizedBox(width: context.screenWidth / 60),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SelectableText(
                  comicInfo.title,
                  style: TextStyle(color: context.textColor, fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  "更新时间：${DateFormat('yyyy-MM-dd HH:mm').format(comicInfo.updatedAt.toLocal())}",
                ),
                const SizedBox(height: 2),
                if (comicInfo.pagesCount != 0) ...[
                  Text("页数：${comicInfo.pagesCount}"),
                  const SizedBox(height: 2),
                ],
                Text("章节数：${comicInfo.epsCount}"),
                if (from == From.jm) ...[
                  GestureDetector(
                    onLongPress: () async {
                      final String copyText = comicInfo.id;
                      await Clipboard.setData(ClipboardData(text: copyText));
                      showSuccessToast("已复制id：$copyText");
                    },
                    child: Text("禁漫车：JM${comicInfo.id}"),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  stringSelectDate,
                  style: TextStyle(color: context.theme.colorScheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
