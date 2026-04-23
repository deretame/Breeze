import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/context/context_extensions.dart';

import '../../../util/router/router.gr.dart';

class EpButtonWidget extends StatelessWidget {
  static const double fixedHeight = 56;

  final Ep doc;
  final dynamic allInfo;
  final int epsLength;
  final ComicEntryType type;
  final String comicId;
  final String from;
  final int index;

  const EpButtonWidget({
    super.key,
    required this.doc,
    required this.allInfo,
    required this.epsLength,
    required this.type,
    required this.comicId,
    required this.from,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final episodeIndex = doc.order > 0 ? doc.order : 1;
    final title = doc.name.trim().isEmpty ? '第$episodeIndex话' : doc.name.trim();
    return InkWell(
      onTap: () {
        final resolvedType = type == ComicEntryType.history
            ? ComicEntryType.normal
            : type;
        context.pushRoute(
          ComicReadRoute(
            comicInfo: allInfo,
            comicId: comicId,
            type: resolvedType,
            order: doc.order,
            epsNumber: epsLength,
            from: from,
            stringSelectCubit: context.read<StringSelectCubit>(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: fixedHeight,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              '第${index + 1}话',
              style: context.theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.theme.colorScheme.primary,
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
                  color: context.textColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: context.textColor.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
