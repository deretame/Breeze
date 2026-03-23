import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/page/comic_info/comic_info.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/sundry.dart';

import '../../../type/enum.dart';
import '../../../util/router/router.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/toast.dart';

enum MenuOption { export, collect, reverseOrder }

@RoutePage()
class ComicInfoPage extends StatelessWidget {
  final String comicId;
  final From from;
  final ComicEntryType type;

  const ComicInfoPage({
    super.key,
    required this.comicId,
    required this.from,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => GetComicInfoBloc()
            ..add(GetComicInfoEvent(comicId: comicId, from: from, type: type)),
        ),
        BlocProvider(create: (_) => StringSelectCubit()),
      ],
      child: _ComicInfo(comicId: comicId, type: type, from: from),
    );
  }
}

class _ComicInfo extends StatefulWidget {
  final String comicId;
  final ComicEntryType type;
  final From from;

  const _ComicInfo({
    required this.comicId,
    required this.type,
    required this.from,
  });

  @override
  _ComicInfoState createState() => _ComicInfoState();
}

class _ComicInfoState extends State<_ComicInfo>
    with AutomaticKeepAliveClientMixin {
  ComicEntryType get type => widget.type;

  @override
  bool get wantKeepAlive => true;

  dynamic comicInfoDyn;
  late ComicEntryType _type;
  bool _loadingComplete = false;
  // 添加一个状态变量记录是否倒序，用于更新菜单文字
  bool _isReversed = false;
  String _title = "";

  @override
  void initState() {
    super.initState();
    _type = type;
    initHistory(context, widget.comicId, widget.from);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stringSelectDate = context.watch<StringSelectCubit>().state;
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          const SizedBox(width: 50),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => popToRoot(context),
          ),
          Expanded(child: Container()),
          PopupMenuButton<MenuOption>(
            onSelected: (MenuOption item) {
              switch (item) {
                case MenuOption.export:
                  _handleExport();
                  break;
                case MenuOption.collect:
                  collectJmComicToLocal(comicInfoDyn);
                  break;
                case MenuOption.reverseOrder:
                  _toggleOrder();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              List<PopupMenuEntry<MenuOption>> menuItems = [];

              menuItems.add(
                PopupMenuItem<MenuOption>(
                  value: MenuOption.reverseOrder,
                  child: Row(
                    children: [
                      Icon(Icons.sort, color: Colors.black54),
                      SizedBox(width: 10),
                      Text(_isReversed ? '章节正序' : '章节倒序'),
                    ],
                  ),
                ),
              );

              if (_type == ComicEntryType.download) {
                menuItems.add(
                  const PopupMenuItem<MenuOption>(
                    value: MenuOption.export,
                    child: Row(
                      children: [
                        Icon(Icons.save_alt, color: Colors.black54),
                        SizedBox(width: 10),
                        Text('导出漫画'),
                      ],
                    ),
                  ),
                );
              }

              if (widget.from == From.jm) {
                menuItems.add(
                  const PopupMenuItem<MenuOption>(
                    value: MenuOption.collect,
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.black54),
                        SizedBox(width: 10),
                        Text('收藏到本地'),
                      ],
                    ),
                  ),
                );
              }

              return menuItems;
            },
          ),
        ],
      ),
      body: BlocBuilder<GetComicInfoBloc, GetComicInfoState>(
        builder: (context, state) {
          switch (state.status) {
            case GetComicInfoStatus.initial:
              return Center(child: CircularProgressIndicator());
            case GetComicInfoStatus.failure:
              if (state.result.contains("under review") &&
                  state.result.contains("1014")) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('此漫画已下架', style: TextStyle(fontSize: 20)),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        child: Text('返回'),
                      ),
                    ],
                  ),
                );
              }
              return ErrorView(
                errorMessage: '${state.result.toString()}\n加载失败，请重试。',
                onRetry: () {
                  context.read<GetComicInfoBloc>().add(
                    GetComicInfoEvent(
                      comicId: widget.comicId,
                      from: widget.from,
                      type: _type,
                    ),
                  );
                },
              );
            case GetComicInfoStatus.success:
              comicInfoDyn = state.comicInfo;
              return _infoView(state.allInfo!);
          }
        },
      ),
      floatingActionButton: _loadingComplete
          ? _ReadActionButton(
              hasHistory: stringSelectDate.isNotEmpty,
              onPressed: () => goToComicRead(
                context,
                widget.comicId,
                widget.type,
                comicInfoDyn,
                widget.from,
              ),
            )
          : null,
    );
  }

  Widget _infoView(NormalComicAllInfo normalComicAllInfo) {
    final comicInfo = normalComicAllInfo.comicInfo;
    _title = comicInfo.title;

    if (!_loadingComplete) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => setState(() => _loadingComplete = true),
      );
    }

    var displayEps = List.from(normalComicAllInfo.eps);
    if (_isReversed) {
      displayEps = displayEps.reversed.toList();
    }

    return RefreshIndicator(
      onRefresh: () async {
        _type = ComicEntryType.normal;
        _isReversed = false;

        context.read<GetComicInfoBloc>().add(
          GetComicInfoEvent(
            comicId: widget.comicId,
            from: widget.from,
            type: _type,
          ),
        );
        setState(() {
          initHistory(context, widget.comicId, widget.from);
          _loadingComplete = false;
        });
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 180),
        itemCount: 1,
        itemBuilder: (context, index) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ComicParticularsWidget(
                  comicInfo: comicInfo,
                  from: widget.from,
                  onContinueRead: context.watch<StringSelectCubit>().state.isNotEmpty
                      ? () => goToComicRead(
                          context,
                          widget.comicId,
                          _type,
                          comicInfoDyn,
                          widget.from,
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  child: ComicOperationWidget(
                    normalInfo: normalComicAllInfo,
                    from: widget.from,
                    comicInfo: comicInfoDyn,
                  ),
                ),
                if (comicInfo.metadata.isNotEmpty || comicInfo.description.trim().isNotEmpty)
                  ...[
                    const SizedBox(height: 12),
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final meta in comicInfo.metadata) ...[
                            AllChipWidget(
                              comicId: comicInfo.id,
                              metadata: meta,
                              from: widget.from,
                            ),
                            const SizedBox(height: 6),
                          ],
                          if (comicInfo.description.trim().isNotEmpty)
                            _DescriptionCard(description: comicInfo.description.let(t2s)),
                        ],
                      ),
                    ),
                  ],
                if (comicInfo.creator.name.trim().isNotEmpty ||
                    comicInfo.creator.avatar.url.trim().isNotEmpty)
                  ...[
                    const SizedBox(height: 12),
                    _SectionCard(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: CreatorInfoWidget(
                            creator: comicInfo.creator,
                            from: widget.from,
                            imageKey: comicInfo.id,
                          ),
                        ),
                      ),
                    ),
                  ],
                const SizedBox(height: 12),
                _SectionCard(
                  title: '章节目录',
                  trailing: _EpisodeHeaderBadge(
                    label: '${normalComicAllInfo.eps.length} 话',
                    icon: _isReversed ? Icons.south : Icons.north,
                    onTap: _toggleOrder,
                  ),
                  child: _EpisodeListSection(
                    episodes: displayEps,
                    allInfo: comicInfoDyn,
                    epsLength: normalComicAllInfo.eps.length,
                    type: _type,
                    comicId: widget.comicId,
                    from: widget.from,
                  ),
                ),
                if (normalComicAllInfo.recommend.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: '相关推荐',
                    child: RecommendWidget(comicList: normalComicAllInfo.recommend),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildZipFileName() {
    final rawName = _title.trim().isEmpty ? widget.comicId : _title.trim();
    final safeName = rawName.replaceAll(RegExp(r'[<>:"/\\|?* ]'), '_');
    return '$safeName.zip';
  }

  Future<ExportType?> _pickExportType() async {
    if (Platform.isIOS) return ExportType.zip;

    return showDialog<ExportType>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择导出方式'),
          content: const Text('请选择将漫画导出为压缩包还是文件夹：'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ExportType.folder),
              child: const Text('文件夹'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ExportType.zip),
              child: const Text('压缩包'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _pickExportDirectory() async => getDirectoryPath();

  // 导出逻辑
  Future<void> _handleExport() async {
    String? cacheZipPath;

    try {
      if (!mounted) return;

      final exportType = await _pickExportType();
      if (exportType == null) return;

      final exportDir = await _pickExportDirectory();
      if (exportDir == null) return;

      final zipFileName = _buildZipFileName();
      final targetZipPath = p.join(exportDir, zipFileName);

      if (Platform.isIOS) {
        final cachePath = await getCachePath();
        cacheZipPath = p.join(cachePath, zipFileName);

        final cacheZipFile = File(cacheZipPath);
        if (await cacheZipFile.exists()) {
          await cacheZipFile.delete();
        }

        await exportComic(
          widget.comicId,
          ExportType.zip,
          widget.from,
          path: cacheZipPath,
        );

        final saveFile = File(targetZipPath);
        if (await saveFile.exists()) {
          await saveFile.delete();
        }
        await cacheZipFile.copy(targetZipPath);
        showSuccessToast('导出成功');
        return;
      }

      final exportPath = exportType == ExportType.zip
          ? targetZipPath
          : exportDir;

      await exportComic(
        widget.comicId,
        exportType,
        widget.from,
        path: exportPath,
      );
    } catch (e) {
      showErrorToast(
        "导出失败，请重试。\n${e.toString()}",
        duration: const Duration(seconds: 5),
      );
    } finally {
      if (cacheZipPath != null) {
        final cacheZipFile = File(cacheZipPath);
        if (await cacheZipFile.exists()) {
          await cacheZipFile.delete();
        }
      }
    }
  }

  // 实现章节倒序逻辑
  void _toggleOrder() => setState(() => _isReversed = !_isReversed);
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.title,
    this.trailing,
  });

  final String? title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          if (title != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: context.theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 10),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 1,
              color: context.theme.colorScheme.outlineVariant.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _EpisodeHeaderBadge extends StatelessWidget {
  const _EpisodeHeaderBadge({
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: context.theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: context.textColor.withValues(alpha: 0.75)),
              const SizedBox(width: 6),
              Text(
                label,
                style: context.theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.textColor.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DescriptionCard extends StatefulWidget {
  const _DescriptionCard({required this.description});

  final String description;

  @override
  State<_DescriptionCard> createState() => _DescriptionCardState();
}

class _DescriptionCardState extends State<_DescriptionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final descriptionStyle = context.theme.textTheme.bodyMedium?.copyWith(
      height: 1.65,
      color: context.textColor.withValues(alpha: 0.9),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.theme.colorScheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '简介',
            style: context.theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            widget.description,
            style: descriptionStyle,
            maxLines: _expanded ? null : 5,
          ),
          if (widget.description.length > 90) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              label: Text(_expanded ? '收起' : '展开全文'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EpisodeListSection extends StatelessWidget {
  const _EpisodeListSection({
    required this.episodes,
    required this.allInfo,
    required this.epsLength,
    required this.type,
    required this.comicId,
    required this.from,
  });

  final List<dynamic> episodes;
  final dynamic allInfo;
  final int epsLength;
  final ComicEntryType type;
  final String comicId;
  final From from;

  @override
  Widget build(BuildContext context) {
    if (episodes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.theme.colorScheme.outlineVariant.withValues(alpha: 0.28),
          ),
        ),
        child: Text(
          '暂无章节信息',
          style: context.theme.textTheme.bodyMedium,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: episodes.map((item) {
              final e = item as Ep;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: EpButtonWidget(
                  doc: e,
                  allInfo: allInfo,
                  epsLength: epsLength,
                  type: type,
                  comicId: comicId,
                  from: from,
                ),
              );
            }).toList(),
          );
        }

        final isDesktop = constraints.maxWidth >= 960;
        if (isDesktop) {
          return Center(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: episodes.map((item) {
                final e = item as Ep;
                return SizedBox(
                  width: 280,
                  child: EpButtonWidget(
                    doc: e,
                    allInfo: allInfo,
                    epsLength: epsLength,
                    type: type,
                    comicId: comicId,
                    from: from,
                  ),
                );
              }).toList(),
            ),
          );
        }

        final isWide = constraints.maxWidth >= 720;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: episodes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 2 : 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isWide ? 4.8 : 3.8,
          ),
          itemBuilder: (context, index) {
            final e = episodes[index] as Ep;
            return EpButtonWidget(
              doc: e,
              allInfo: allInfo,
              epsLength: epsLength,
              type: type,
              comicId: comicId,
              from: from,
            );
          },
        );
      },
    );
  }
}

class _ReadActionButton extends StatelessWidget {
  const _ReadActionButton({
    required this.hasHistory,
    required this.onPressed,
  });

  final bool hasHistory;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = context.theme.colorScheme.primary;
    final background = hasHistory
        ? primary.withValues(alpha: 0.14)
        : primary.withValues(alpha: 0.22);

    return SizedBox(
      width: hasHistory ? 132 : 112,
      height: 56,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: background,
        foregroundColor: hasHistory ? primary : context.textColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasHistory ? Icons.history_rounded : Icons.menu_book_rounded,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                hasHistory ? '继续阅读' : '开始阅读',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: context.theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: hasHistory ? primary : context.textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
