import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/comic_info/bloc/comic_preview_bloc.dart';
import 'package:zephyr/page/search_result/widgets/bottom_loader.dart';
import 'package:zephyr/page/comic_info/models/unified_plugin_preview.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/widgets/picture_bloc/bloc/picture_bloc.dart';
import 'package:zephyr/widgets/picture_bloc/models/picture_info.dart';

class ComicPreviewSliver extends StatelessWidget {
  const ComicPreviewSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ComicPreviewBloc, ComicPreviewState>(
      builder: (context, state) {
        if (state.status == ComicPreviewStatus.failure && state.items.isEmpty) {
          return SliverMainAxisGroup(
            slivers: [
              _header(context),
              SliverToBoxAdapter(child: _initialFailure(context)),
            ],
          );
        }

        if (state.status == ComicPreviewStatus.success &&
            state.items.isEmpty &&
            state.hasReachedMax) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverMainAxisGroup(
          slivers: [
            _header(context),
            if (state.status == ComicPreviewStatus.initial &&
                state.items.isEmpty)
              const SliverToBoxAdapter(child: BottomLoader())
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ComicPreviewTile(
                      key: ValueKey(_itemKey(state.items[index], index)),
                      item: state.items[index],
                      comicId: context.read<ComicPreviewBloc>().comicId,
                      from: context.read<ComicPreviewBloc>().from,
                    ),
                    childCount: state.items.length,
                  ),
                ),
              ),
              if (state.status == ComicPreviewStatus.loadingMore)
                const SliverToBoxAdapter(child: BottomLoader()),
              _footer(context, state),
            ],
          ],
        );
      },
    );
  }

  SliverToBoxAdapter _header(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: Text(
          t.comicInfo.preview,
          style: context.theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _initialFailure(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () =>
            context.read<ComicPreviewBloc>().add(const LoadComicPreview()),
        child: Text(t.searchResult.retry),
      ),
    );
  }

  Widget _footer(BuildContext context, ComicPreviewState state) {
    if (state.hasReachedMax) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    if (state.status == ComicPreviewStatus.getMoreFailure) {
      return SliverToBoxAdapter(
        child: Center(
          child: TextButton(
            onPressed: () => context.read<ComicPreviewBloc>().add(
              const LoadComicPreview(loadMore: true),
            ),
            child: Text(t.oldHome.loadMoreFailed),
          ),
        ),
      );
    }
    if (state.status == ComicPreviewStatus.loadingMore) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 14),
          child: TextButton.icon(
            onPressed: () => context.read<ComicPreviewBloc>().add(
              const LoadComicPreview(loadMore: true),
            ),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            label: Text(t.oldHome.loadMore),
          ),
        ),
      ),
    );
  }

  String _itemKey(UnifiedPluginPreviewItem item, int index) {
    if (item.id.trim().isNotEmpty) return item.id;
    return '${item.path}|${item.url}|$index';
  }
}

class _ComicPreviewTile extends StatelessWidget {
  const _ComicPreviewTile({
    super.key,
    required this.item,
    required this.comicId,
    required this.from,
  });

  final UnifiedPluginPreviewItem item;
  final String comicId;
  final String from;

  @override
  Widget build(BuildContext context) {
    final pictureInfo = PictureInfo(
      from: from,
      url: item.url,
      path: item.path,
      cartoonId: comicId,
      chapterId: 'preview',
      pictureType: PictureType.comic,
      extern: item.extern,
    );
    return BlocProvider(
      create: (_) => PictureBloc()..add(GetPicture(pictureInfo)),
      child: BlocBuilder<PictureBloc, PictureLoadState>(
        builder: (context, state) {
          switch (state.status) {
            case PictureLoadStatus.initial:
              return _tileBackground(
                context,
                const CircularProgressIndicator(),
              );
            case PictureLoadStatus.success:
              return InkWell(
                onTap: () => context.pushRoute(
                  FullRouteImageRoute(imagePath: state.imagePath!),
                ),
                child: _tileBackground(
                  context,
                  Image.file(
                    File(state.imagePath!),
                    fit: BoxFit.contain,
                    cacheWidth: 360,
                  ),
                ),
              );
            case PictureLoadStatus.failure:
              return InkWell(
                onTap: () =>
                    context.read<PictureBloc>().add(GetPicture(pictureInfo)),
                child: _tileBackground(context, const Icon(Icons.refresh)),
              );
          }
        },
      ),
    );
  }

  Widget _tileBackground(BuildContext context, Widget child) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: child),
    );
  }
}
