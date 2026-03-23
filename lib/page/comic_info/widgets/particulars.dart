import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/page/comic_info/comic_info.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    show ComicInfo;
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../widgets/picture_bloc/models/picture_info.dart';

class ComicParticularsWidget extends StatelessWidget {
  final ComicInfo comicInfo;
  final From from;
  final VoidCallback? onContinueRead;

  const ComicParticularsWidget({
    super.key,
    required this.comicInfo,
    required this.from,
    this.onContinueRead,
  });

  @override
  Widget build(BuildContext context) {
    final stringSelectDate = context.watch<StringSelectCubit>().state;
    final coverExtension = comicInfo.cover.extension;
    final pictureInfo = PictureInfo(
      from: from,
      url: comicInfo.cover.url,
      path:
          coverExtension['path']?.toString() ??
          (comicInfo.cover.name.isNotEmpty ? comicInfo.cover.name : comicInfo.id),
      chapterId: comicInfo.id,
      pictureType: PictureType.cover,
      cartoonId: comicInfo.id,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final info = _InfoColumn(
            comicInfo: comicInfo,
            from: from,
            stringSelectDate: stringSelectDate,
            onContinueRead: onContinueRead,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  child: Cover(
                    pictureInfo: pictureInfo,
                    height: 220,
                    borderRadius: 14,
                  ),
                ),
                const SizedBox(height: 16),
                info,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Cover(
                pictureInfo: pictureInfo,
                height: 230,
                borderRadius: 14,
              ),
              const SizedBox(width: 16),
              Expanded(child: info),
            ],
          );
        },
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({
    required this.comicInfo,
    required this.from,
    required this.stringSelectDate,
    required this.onContinueRead,
  });

  final ComicInfo comicInfo;
  final From from;
  final String stringSelectDate;
  final VoidCallback? onContinueRead;

  @override
  Widget build(BuildContext context) {
    final titleStyle = context.theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      height: 1.15,
      color: context.textColor,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: context.theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: context.theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            from == From.jm ? 'JM Comic' : 'Bika Comic',
            style: context.theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SelectableText(comicInfo.title, style: titleStyle),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: comicInfo.titleMeta
              .map(
                (item) => _MetaPill(
                  label: item.name,
                  onTap: item.onTap.isEmpty
                      ? null
                      : () => handleComicInfoAction(
                          context,
                          item.onTap,
                          fallbackFrom: from,
                        ),
                ),
              )
              .toList(),
        ),
        if (stringSelectDate.isNotEmpty) ...[
          const SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onContinueRead,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: context.theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.theme.colorScheme.primary.withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.theme.colorScheme.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: context.theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '阅读记录',
                            style: context.theme.textTheme.labelMedium?.copyWith(
                              color: context.theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stringSelectDate,
                            style: context.theme.textTheme.bodyMedium?.copyWith(
                              color: context.textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onContinueRead != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '继续阅读',
                        style: context.theme.textTheme.labelLarge?.copyWith(
                          color: context.theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 20,
                        color: context.theme.colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.theme.colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Text(
        label,
        style: context.theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.15,
        ),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: label));
        showSuccessToast('已复制：$label');
      },
      child: pill,
    );
  }
}
