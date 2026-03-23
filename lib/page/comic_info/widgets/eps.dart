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
    final episodeIndex = doc.order > 0 ? doc.order : 1;
    final title = doc.name.trim().isEmpty ? '第$episodeIndex话' : doc.name.trim();
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
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: context.theme.colorScheme.outlineVariant.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          children: [
            Text(
              '第$episodeIndex话',
              style: context.theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.textColor.withValues(alpha: 0.68),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: context.textColor.withValues(alpha: 0.48),
            ),
          ],
        ),
      ),
    );
  }
}
