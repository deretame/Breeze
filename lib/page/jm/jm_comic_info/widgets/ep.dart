import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';

import '../../../../type/enum.dart';
import '../../../../util/router/router.gr.dart';
import '../json/jm_comic_info_json.dart';

class EpWidget extends StatelessWidget {
  final String comicId;
  final Series series;
  final JmComicInfoJson comicInfo;
  final int epsNumber;
  final ComicEntryType type;
  final StringSelectCubit cubit;

  const EpWidget({
    super.key,
    required this.comicId,
    required this.series,
    required this.comicInfo,
    required this.epsNumber,
    required this.type,
    required this.cubit,
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
            type: type == ComicEntryType.download
                ? ComicEntryType.download
                : ComicEntryType.normal,
            comicInfo: comicInfo,
            stringSelectCubit: cubit,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: context.theme.colorScheme.secondaryFixedDim,
              spreadRadius: 0,
              blurRadius: 2,
            ),
          ],
        ),
        child: Text(series.name, style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
