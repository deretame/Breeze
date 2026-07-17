import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/router/router.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_follow/cubit/comic_follow_cubit.dart';
import 'package:zephyr/page/comic_info/comic_info.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/error_filter.dart';
import 'package:open_file/open_file.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/util/permission.dart';
import 'package:zephyr/util/text/chinese_convert.dart';
import 'package:zephyr/widgets/comic_entry/models/models.dart';

import 'package:zephyr/widgets/error_view.dart';
import 'package:zephyr/widgets/fluent_dropdown.dart';
import 'package:zephyr/widgets/toast.dart';

enum MenuOption { export, cloudCollect, follow }

@RoutePage()
class ComicInfoPage extends StatelessWidget {
  final String comicId;
  final String from;
  final String pluginId;
  final ComicEntryType type;

  const ComicInfoPage({
    super.key,
    required this.comicId,
    required this.from,
    this.pluginId = '',
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPluginId =
        (pluginId.trim().isNotEmpty ? pluginId : from.trim()).trim();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => GetComicInfoBloc()
            ..add(
              GetComicInfoEvent(
                comicId: comicId,
                from: from,
                pluginId: resolvedPluginId,
                type: type,
              ),
            ),
        ),
        BlocProvider(create: (_) => StringSelectCubit()),
      ],
      child: _ComicInfo(
        comicId: comicId,
        type: type,
        from: from,
        pluginId: resolvedPluginId,
      ),
    );
  }
}

class _ComicInfo extends StatefulWidget {
  final String comicId;
  final ComicEntryType type;
  final String from;
  final String pluginId;

  const _ComicInfo({
    required this.comicId,
    required this.type,
    required this.from,
    required this.pluginId,
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
  bool _isReversed = false;
  String _title = "";
  NormalComicAllInfo? _currentInfo;
  bool _isCloudCollected = false;
  bool _followSyncedForCurrentInfo = false;

  @override
  void initState() {
    super.initState();
    _type = type;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          BlocSelector<ComicFollowCubit, ComicFollowState, bool>(
            selector: (state) =>
                state.isFollowing(widget.pluginId, widget.comicId),
            builder: (context, isFollowing) {
              return IconButton(
                icon: Icon(
                  isFollowing
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                ),
                tooltip: isFollowing
                    ? t.comicInfo.unfollow
                    : t.comicInfo.follow,
                onPressed: () => _toggleFollow(isFollowing),
              );
            },
          ),
          FluentPopupMenuButton<MenuOption>(
            icon: const Icon(Icons.more_vert),
            onSelected: (MenuOption item) {
              switch (item) {
                case MenuOption.export:
                  _handleExport();
                  break;
                case MenuOption.cloudCollect:
                  _toggleCloudCollectFromMenu();
                  break;
                case MenuOption.follow:
                  _toggleFollowFromMenu();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              final isFollowing = context.read<ComicFollowCubit>().isFollowing(
                widget.pluginId,
                widget.comicId,
              );
              final menuItems = <FluentPopupMenuItem<MenuOption>>[
                FluentPopupMenuItem<MenuOption>(
                  value: MenuOption.follow,
                  leading: Icon(
                    isFollowing
                        ? Icons.notifications_off
                        : Icons.notifications_active,
                  ),
                  title: Text(
                    isFollowing ? t.comicInfo.unfollow : t.comicInfo.follow,
                  ),
                ),
              ];

              if (_type == ComicEntryType.download) {
                menuItems.add(
                  FluentPopupMenuItem<MenuOption>(
                    value: MenuOption.export,
                    leading: const Icon(Icons.save_alt),
                    title: Text(t.comicInfo.exportComic),
                  ),
                );
              }

              menuItems.add(
                FluentPopupMenuItem<MenuOption>(
                  value: MenuOption.cloudCollect,
                  leading: Icon(
                    _isCloudCollected ? Icons.star : Icons.star_border,
                  ),
                  title: Text(
                    (_currentInfo?.allowCollected ?? false)
                        ? (_isCloudCollected
                              ? t.comicInfo.removeCloudCollection
                              : t.comicInfo.collectToCloud)
                        : t.comicInfo.cloudCollectDisabled,
                  ),
                ),
              );

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
                      Text(
                        t.comicInfo.discontinued,
                        style: const TextStyle(fontSize: 20),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        child: Text(t.comicInfo.back),
                      ),
                    ],
                  ),
                );
              }
              return ErrorView(
                errorMessage: t.comicInfo.loadFailedWithError(
                  error: state.result.toString(),
                ),
                onRetry: () {
                  context.read<GetComicInfoBloc>().add(
                    GetComicInfoEvent(
                      comicId: widget.comicId,
                      from: widget.from,
                      pluginId: widget.pluginId,
                      type: _type,
                    ),
                  );
                },
              );
            case GetComicInfoStatus.success:
              comicInfoDyn = state.comicInfo;
              _currentInfo = state.allInfo;
              _isCloudCollected = state.allInfo?.isFavourite ?? false;
              initHistory(
                context,
                widget.comicId,
                widget.from,
                widget.pluginId,
                chapters: state.allInfo!.eps,
              );
              return _infoView(state.allInfo!);
          }
        },
      ),
      floatingActionButton: _loadingComplete
          ? BlocBuilder<StringSelectCubit, String>(
              builder: (context, stringSelectDate) {
                return _ReadActionButton(
                  hasHistory: stringSelectDate.isNotEmpty,
                  onPressed: () => goToComicRead(
                    context,
                    widget.comicId,
                    widget.type,
                    comicInfoDyn,
                    widget.from,
                  ),
                );
              },
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

    var displayEps = List<dynamic>.from(normalComicAllInfo.eps);
    if (_isReversed) {
      displayEps = displayEps.reversed.toList();
    }

    _syncFollowIfNeeded(normalComicAllInfo);

    return BlocSelector<StringSelectCubit, String, bool>(
      selector: (state) => state.isNotEmpty,
      builder: (context, hasHistory) {
        return RefreshIndicator(
          onRefresh: () async {
            _type = ComicEntryType.normal;
            _followSyncedForCurrentInfo = false;
            _isReversed = false;

            context.read<GetComicInfoBloc>().add(
              GetComicInfoEvent(
                comicId: widget.comicId,
                from: widget.from,
                pluginId: widget.pluginId,
                type: _type,
              ),
            );
            setState(() {
              _loadingComplete = false;
            });
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 180),
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
                      type: _type,
                      onContinueRead: hasHistory
                          ? () => goToComicRead(
                              context,
                              widget.comicId,
                              _type,
                              comicInfoDyn,
                              widget.from,
                            )
                          : null,
                    ),
                    _buildDivider(context),
                    ComicOperationWidget(
                      normalInfo: normalComicAllInfo,
                      from: widget.from,
                      comicInfo: comicInfoDyn,
                    ),
                    if (comicInfo.metadata.isNotEmpty ||
                        comicInfo.description.trim().isNotEmpty) ...[
                      _buildDivider(context),
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
                              _DescriptionCard(
                                description: comicInfo.description.let(
                                  convertChineseForDisplay,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (comicInfo.creator.name.trim().isNotEmpty ||
                        comicInfo.creator.avatar.url.trim().isNotEmpty) ...[
                      _buildDivider(context),
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
                    _buildDivider(context),
                    _SectionCard(
                      title: t.comicInfo.chapterList,
                      trailing: _EpisodeHeaderBadge(
                        label: t.comicInfo.episodeCount(
                          count: normalComicAllInfo.eps.length,
                        ),
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
                      _buildDivider(context),
                      if (_resolveRecommendItems(
                        normalComicAllInfo.recommend,
                      ).isNotEmpty)
                        _SectionCard(
                          title: t.comicInfo.related,
                          child: RecommendWidget(
                            comicList: _resolveRecommendItems(
                              normalComicAllInfo.recommend,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: context.theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
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
          title: Text(t.comicInfo.exportTitle),
          content: Text(t.comicInfo.exportSubtitle),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(t.common.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ExportType.folder),
              child: Text(t.comicInfo.folder),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ExportType.zip),
              child: Text(t.comicInfo.zip),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _pickExportDirectory() async => getDirectoryPath();

  Future<String?> _resolveExportDirectory() async {
    // iOS 无目录选择器，导出到缓存后通过系统分享面板保存
    if (Platform.isIOS) {
      return getCachePath();
    }
    final customPath = globalSetting.customExportPath.trim();
    if (customPath.isNotEmpty) {
      return customPath;
    }
    if (Platform.isAndroid) {
      final granted = await requestExportPermission();
      if (!granted) {
        throw StateError(t.comicInfo.exportPermissionDenied);
      }
      return createDownloadDir();
    }
    return _pickExportDirectory();
  }

  void _logExportPath(String path) {
    if (!(Platform.isAndroid ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux)) {
      return;
    }

    final displayPath = Platform.isAndroid
        ? _simplifyAndroidPathForLog(path)
        : path;
    logger.d('Exported comic path: $displayPath');
  }

  String _simplifyAndroidPathForLog(String path) {
    final normalized = path.replaceAll('\\', '/');
    final downloadIndex = normalized.indexOf('/Download/');
    if (downloadIndex >= 0) {
      return normalized.substring(downloadIndex + 1);
    }
    return normalized;
  }

  void _showExportDirectory(String exportedPath, ExportType exportType) {
    if (!(Platform.isAndroid ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux)) {
      return;
    }

    final exportDirectory = exportType == ExportType.zip
        ? p.dirname(exportedPath)
        : exportedPath;
    final displayPath = Platform.isAndroid
        ? _simplifyAndroidPathForLog(exportDirectory)
        : exportDirectory;
    showInfoToast(
      t.comicInfo.exportDirectory(displayPath: displayPath),
      duration: const Duration(seconds: 5),
    );
  }

  // 导出逻辑
  Future<void> _handleExport() async {
    String? cacheZipPath;

    try {
      if (!mounted) return;

      final exportType = await _pickExportType();
      if (exportType == null) return;

      final exportDir = await _resolveExportDirectory();
      if (exportDir == null) return;

      final zipFileName = _buildZipFileName();
      final targetZipPath = p.join(exportDir, zipFileName);

      if (Platform.isIOS) {
        // 不写入 cacheZipPath：open_file 在分享面板弹出后即返回，
        // finally 里删除会导致用户还没保存文件就被删掉。
        final iosZipPath = targetZipPath;
        final iosZipFile = File(iosZipPath);
        if (await iosZipFile.exists()) {
          await iosZipFile.delete();
        }

        await exportComic(
          widget.comicId,
          ExportType.zip,
          widget.from,
          path: iosZipPath,
        );

        // 弹出系统分享面板，用户可「存储到文件」
        await OpenFile.open(iosZipPath);
        showSuccessToast(t.comicInfo.exportSuccess);
        _logExportPath(iosZipPath);
        return;
      }

      final exportPath = exportType == ExportType.zip
          ? targetZipPath
          : exportDir;

      final exportedPath = await exportComic(
        widget.comicId,
        exportType,
        widget.from,
        path: exportPath,
      );
      _showExportDirectory(exportedPath, exportType);
      _logExportPath(exportedPath);
    } catch (e) {
      final errorMessage = e is StateError
          ? e.message.toString()
          : t.comicInfo.exportFailedWithError(
              error: normalizeSearchErrorMessage(e),
            );
      showErrorToast(errorMessage, duration: const Duration(seconds: 5));
    } finally {
      if (cacheZipPath != null) {
        final cacheZipFile = File(cacheZipPath);
        if (await cacheZipFile.exists()) {
          await cacheZipFile.delete();
        }
      }
    }
  }

  // 切换章节列表的倒序/正序显示
  void _toggleOrder() => setState(() => _isReversed = !_isReversed);

  void _syncFollowIfNeeded(NormalComicAllInfo info) {
    if (_type == ComicEntryType.download) {
      return;
    }
    final cubit = context.read<ComicFollowCubit>();
    if (!cubit.isFollowing(widget.pluginId, widget.comicId)) {
      return;
    }
    if (_followSyncedForCurrentInfo) {
      return;
    }
    _followSyncedForCurrentInfo = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cubit.markAsRead(widget.pluginId, widget.comicId, info.eps.length);
    });
  }

  Future<void> _toggleFollow(bool isFollowing) async {
    final info = _currentInfo;
    if (info == null) {
      showErrorToast(t.comicInfo.detailsNotLoaded);
      return;
    }

    if (isFollowing) {
      await _confirmAndRemoveFollow(info.comicInfo.title);
      return;
    }

    await context.read<ComicFollowCubit>().addOrUpdateFollow(
      source: widget.pluginId,
      comicId: widget.comicId,
      info: info,
      lastChapterCount: info.eps.length,
    );
    _followSyncedForCurrentInfo = true;
    if (mounted) {
      showSuccessToast(t.comicInfo.followed);
    }
  }

  Future<void> _toggleFollowFromMenu() async {
    final info = _currentInfo;
    if (info == null) {
      showErrorToast(t.comicInfo.detailsNotLoaded);
      return;
    }
    final isFollowing = context.read<ComicFollowCubit>().isFollowing(
      widget.pluginId,
      widget.comicId,
    );
    await _toggleFollow(isFollowing);
  }

  Future<void> _confirmAndRemoveFollow(String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.comicInfo.confirmUnfollowTitle),
        content: Text(t.comicInfo.confirmUnfollowContent(title: title)),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => dialogContext.pop(true),
            child: Text(t.common.ok),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    if (!mounted) {
      return;
    }
    await context.read<ComicFollowCubit>().removeFollow(
      widget.pluginId,
      widget.comicId,
    );
    _followSyncedForCurrentInfo = false;
    if (mounted) {
      showSuccessToast(t.comicInfo.unfollowed);
    }
  }

  List<UnifiedComicListItem> _resolveRecommendItems(List<Recommend> recommend) {
    return recommend
        .map((item) {
          // 优先使用 extern 中的 unifiedItem
          final unifiedJson = asJsonMap(item.extern)['unifiedItem'];
          if (unifiedJson != null) return asJsonMap(unifiedJson);

          // 否则从 Recommend 对象构造 JSON
          return item.toJson();
        })
        .where((json) => json.isNotEmpty)
        .map(UnifiedComicListItem.fromJson)
        .toList();
  }

  Future<void> _toggleCloudCollectFromMenu() async {
    final info = _currentInfo;
    if (info == null) {
      showErrorToast(t.comicInfo.detailsNotLoaded);
      return;
    }
    if (!info.allowCollected) {
      showInfoToast(t.comicInfo.cloudCollectDisabled);
      return;
    }
    try {
      showInfoToast(
        _isCloudCollected
            ? t.comicInfo.removingCloudCollection
            : t.comicInfo.collectingToCloud,
      );
      final next = await toggleCloudComicFavorite(
        context: context,
        from: widget.from,
        comicId: info.comicInfo.id,
        currentStatus: _isCloudCollected,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isCloudCollected = next;
      });
      showSuccessToast(
        next
            ? t.comicInfo.cloudCollectSuccess
            : t.comicInfo.cloudUncollectSuccess,
      );
    } catch (e) {
      showErrorToast(t.error.operationFailed);
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.title, this.trailing});

  final String? title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
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
                if (trailing != null) ...[const SizedBox(width: 10), trailing!],
              ],
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
              color: context.theme.colorScheme.outlineVariant.withValues(
                alpha: 0.3,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: context.textColor.withValues(alpha: 0.75),
              ),
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
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.comicInfo.description,
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
              label: Text(
                _expanded ? t.comicInfo.collapse : t.comicInfo.expandFullText,
              ),
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
  final String from;

  @override
  Widget build(BuildContext context) {
    if (episodes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Text(
          t.comicInfo.noChapters,
          style: context.theme.textTheme.bodyMedium,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              for (var i = 0; i < episodes.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: EpButtonWidget(
                    index: i,
                    doc: episodes[i] as Ep,
                    allInfo: allInfo,
                    epsLength: epsLength,
                    type: type,
                    comicId: comicId,
                    from: from,
                  ),
                ),
            ],
          );
        }

        final isDesktop = constraints.maxWidth >= 960;
        if (isDesktop) {
          return Center(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < episodes.length; i++)
                  SizedBox(
                    width: 280,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: EpButtonWidget(
                        index: i,
                        doc: episodes[i] as Ep,
                        allInfo: allInfo,
                        epsLength: epsLength,
                        type: type,
                        comicId: comicId,
                        from: from,
                      ),
                    ),
                  ),
              ],
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
            mainAxisExtent: EpButtonWidget.fixedHeight,
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
              index: index,
            );
          },
        );
      },
    );
  }
}

class _ReadActionButton extends StatelessWidget {
  const _ReadActionButton({required this.hasHistory, required this.onPressed});

  final bool hasHistory;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      icon: Icon(
        hasHistory ? Icons.history_rounded : Icons.menu_book_rounded,
        size: 18,
      ),
      label: Text(
        hasHistory ? t.comicInfo.continueRead : t.comicInfo.startRead,
      ),
    );
  }
}
