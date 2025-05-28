import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/type/pipe.dart';

import '../../../../main.dart';
import '../../../../type/enum.dart';
import '../../../../util/router/router.gr.dart';
import '../json/jm_comic_info_json.dart';

class EpWidget extends StatelessWidget {
  final String comicId;
  final Series series;
  final JmComicInfoJson comicInfo;
  final int epsNumber;
  final ComicEntryType type;

  const EpWidget({
    super.key,
    required this.comicId,
    required this.series,
    required this.comicInfo,
    required this.epsNumber,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.pushRoute(
          ComicReadRoute(
            comicId: comicId,
            order: series.id.let(int.parse),
            epsNumber: epsNumber,
            from: From.jm,
            type:
                type == ComicEntryType.download
                    ? ComicEntryType.download
                    : ComicEntryType.normal,
            comicInfo: comicInfo,
          ),
        );
      },
      child: Observer(
        builder: (context) {
          return Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: globalSetting.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: materialColorScheme.secondaryFixedDim,
                  spreadRadius: 0,
                  blurRadius: 2,
                ),
              ],
            ),
            child: Text(series.name, style: TextStyle(fontSize: 16)),
          );
        },
      ),
    );
  }
}
