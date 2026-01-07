import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';

import '../../../type/enum.dart';
import '../../../util/router/router.gr.dart';

class EpButtonWidget extends StatelessWidget {
  final Ep doc;
  final dynamic allInfo;
  final int epsLength;
  final ComicEntryType type;
  final String comicId;
  final From from;

  const EpButtonWidget({
    super.key,
    required this.doc,
    required this.allInfo,
    required this.epsLength,
    required this.type,
    required this.comicId,
    required this.from,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (from == From.bika) {
          context.pushRoute(
            ComicReadRoute(
              comicInfo: allInfo,
              comicId: comicId,
              type: type == ComicEntryType.history
                  ? ComicEntryType.normal
                  : type,
              order: doc.order,
              epsNumber: epsLength,
              from: From.bika,
              stringSelectCubit: context.read<StringSelectCubit>(),
            ),
          );
        } else {
          context.pushRoute(
            ComicReadRoute(
              comicId: comicId,
              order: doc.id.let(toInt),
              epsNumber: epsLength,
              from: From.jm,
              type: type == ComicEntryType.download
                  ? ComicEntryType.download
                  : ComicEntryType.normal,
              comicInfo: allInfo,
              stringSelectCubit: context.read<StringSelectCubit>(),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 0),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(doc.name, style: TextStyle(fontSize: 16))],
        ),
      ),
    );
  }
}
