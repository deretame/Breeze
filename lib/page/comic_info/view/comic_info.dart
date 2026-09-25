import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/router/router.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_follow/cubit/comic_follow_cubit.dart';
import 'package:zephyr/page/comic_info/comic_info.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/page/download/models/download_chapter.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/error_filter.dart';
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
  final ComicEntryType type;
  final Map<String, dynamic>? extern;
  final String? collectionTargetId;
  final String? collectionTargetName;

  const ComicInfoPage({
    super.key,
    required this.comicId,
    required this.from,
    required this.type,
    this.extern,
    this.collectionTargetId,
    this.collectionTargetName,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedFrom = from.trim();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => GetComicInfoBloc()
            ..add(
              GetComicInfoEvent(
                comicId: comicId,
                from: resolvedFrom,
                type: type,
                extern: extern,
              ),
            ),
        ),
        BlocProvider(create: (_) => StringSelectCubit()),
      ],
      child: _ComicInfo(
        comicId: comicId,
        type: type,
        from: resolvedFrom,
        extern: extern,
        collectionTargetId: collectionTargetId,
        collectionTargetName: collectionTargetName,
      ),
    );
  }
}

class _ComicInfo extends StatefulWidget {
  final String comicId;
  final ComicEntryType type;
  final String from;
  final Map<String, dynamic>? extern;
  final String? collectionTargetId;
  final String? collectionTargetName;

  const _ComicInfo({
    required this.comicId,
    required this.type,
    required this.from,
    this.extern,
    this.collectionTargetId,
    this.collectionTargetName,
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
  late String _comicId;
  bool _loadingComplete = false;
  bool _isReversed = false;
  String _title = "";
  late final EpisodeDownloadController _dlController =
      EpisodeDownloadController();
  NormalComicAllInfo? _currentInfo;
  bool _isCloudCollected = false;
  bool _cloudFavoriteStateOverridden = false;
  bool _isLocalCollected = false;
  String _localCollectSyncedFor = '';

  // 章节显示顺序缓存：raw 列表实例不变且倒序开关不变时直接复用，
  // 避免每次 build 都 sort + reversed.toList()。
  // 非倒序时 display 与 sorted 同引用，零拷贝。
  List<dynamic>? _epsRawRef;
  List<dynamic> _sortedEps = const [];
  List<dynamic> _displayEps = const [];
  bool _displayEpsReversed = false;
  bool _displayEpsValid = false;

  List<dynamic> _resolveDisplayEps(List<dynamic> rawEps) {
    if (!identical(rawEps, _epsRawRef)) {
      _epsRawRef = rawEps;
      _sortedEps = sortChaptersByOrder(
        List<dynamic>.from(rawEps),
        (e) => (e as Ep).order,
      );
      _displayEpsValid = false;
    }
    if (!_displayEpsValid || _displayEpsReversed != _isReversed) {
      _displayEps = _isReversed ? _sortedEps.reversed.toList() : _sortedEps;
      _displayEpsReversed = _isReversed;
      _displayEpsValid = true;
    }
    return _displayEps;
  }

  @override
  void initState() {
    super.initState();
    _type = type;
    _comicId = widget.comicId;
  }

  @override
  void dispose() {
    _dlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // 开启「优先云端收藏」后，页面收藏按钮与菜单项的本地/云端收藏行为互换
    final cloudFavoritePreferred = context
        .watch<GlobalSettingCubit>()
        .state
        .cloudFavoritePreferred;
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
            selector: (state) => state.isFollowing(widget.from, _comicId),
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
                  if (cloudFavoritePreferred) {
                    _toggleLocalCollectFromMenu();
                  } else {
                    _toggleCloudCollectFromMenu();
                  }
                  break;
                case MenuOption.follow:
                  _toggleFollowFromMenu();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              final isFollowing = context.read<ComicFollowCubit>().isFollowing(
                widget.from,
                _comicId,
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
                    cloudFavoritePreferred
                        ? (_isLocalCollected ? Icons.star : Icons.star_border)
                        : (_isCloudCollected ? Icons.star : Icons.star_border),
                  ),
                  title: Text(
                    cloudFavoritePreferred
                        ? (_isLocalCollected
                              ? t.comicInfo.removeLocalCollection
                              : t.comicInfo.collectToLocal)
                        : (_isCloudCollected
                              ? t.comicInfo.removeCloudCollection
                              : t.comicInfo.collectToCloud),
                  ),
                ),
              );

              return menuItems;
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          BlocBuilder<GetComicInfoBloc, GetComicInfoState>(
            builder: (context, state) {
              switch (state.status) {
                case GetComicInfoStatus.initial:
                  _cloudFavoriteStateOverridden = false;
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
                          comicId: _comicId,
                          from: widget.from,
                          type: _type,
                          extern: widget.extern,
                        ),
                      );
                    },
                  );
                case GetComicInfoStatus.success:
                  comicInfoDyn = state.comicInfo;
                  _currentInfo = state.allInfo;
                  _comicId = state.comicId ?? _comicId;
                  if (!_cloudFavoriteStateOverridden) {
                    _isCloudCollected = state.allInfo?.isFavourite ?? false;
                  }
                  _syncLocalCollectStatus(state.allInfo!);
                  initHistory(
                    context,
                    _comicId,
                    widget.from,
                    chapters: state.allInfo!.eps,
                  );
                  return _infoView(state.allInfo!);
              }
            },
          ),
          ListenableBuilder(
            listenable: _dlController,
            builder: (context, _) => _SelectionActionBar(
              controller: _dlController,
              isDownloadType: _type == ComicEntryType.download,
            ),
          ),
        ],
      ),
      floatingActionButtonLocation:
          context.watch<GlobalSettingCubit>().state.leftHandModeEnabled
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
      floatingActionButton: ListenableBuilder(
        listenable: _dlController,
        builder: (context, _) {
          if (_dlController.selectionMode) {
            return const SizedBox.shrink();
          }
          return _loadingComplete
              ? BlocBuilder<StringSelectCubit, String>(
                  builder: (context, stringSelectDate) {
                    return _ReadActionButton(
                      hasHistory: stringSelectDate.isNotEmpty,
                      onPressed: () => goToComicRead(
                        context,
                        _comicId,
                        widget.type,
                        comicInfoDyn,
                        widget.from,
                      ),
                    );
                  },
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _infoView(NormalComicAllInfo normalComicAllInfo) {
    final comicInfo = normalComicAllInfo.comicInfo;
    _title = comicInfo.title;
    final clickCoverToStartReading = context
        .watch<GlobalSettingCubit>()
        .state
        .clickCoverToStartReading;

    if (!_loadingComplete) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => setState(() => _loadingComplete = true),
      );
    }

    // 带缓存：bloc 同实例 + 倒序开关不变时零计算，直接复用上次结果。
    final displayEps = _resolveDisplayEps(normalComicAllInfo.eps);
    // 下载类型进来的一定是本地记录（只含已下载章节）；在线页插件允许下载时
    // 才显示章节下载按钮。
    final showDownloadUi =
        normalComicAllInfo.allowDownload || _type == ComicEntryType.download;

    final previewCapability = ComicPreviewCapability.fromInfo(
      normalComicAllInfo,
    );
    final showPreview =
        _type != ComicEntryType.download && previewCapability.enabled;

    return BlocSelector<StringSelectCubit, String, bool>(
      selector: (state) => state.isNotEmpty,
      builder: (context, hasHistory) {
        final refreshable = RefreshIndicator(
          onRefresh: () async {
            _type = ComicEntryType.normal;
            _isReversed = false;

            context.read<GetComicInfoBloc>().add(
              GetComicInfoEvent(
                comicId: _comicId,
                from: widget.from,
                type: _type,
                extern: widget.extern,
              ),
            );
            setState(() {
              _loadingComplete = false;
            });
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(top: 8),
                sliver: _constrainedSliver(
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ComicParticularsWidget(
                          comicInfo: comicInfo,
                          from: widget.from,
                          type: _type,
                          onCoverTap: clickCoverToStartReading
                              ? () => goToComicRead(
                                  context,
                                  _comicId,
                                  _type,
                                  comicInfoDyn,
                                  widget.from,
                                )
                              : null,
                          onContinueRead: hasHistory
                              ? () => goToComicRead(
                                  context,
                                  _comicId,
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
                          collectionTargetId: widget.collectionTargetId,
                          collectionTargetName: widget.collectionTargetName,
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
                                constraints: const BoxConstraints(
                                  maxWidth: 460,
                                ),
                                child: CreatorInfoWidget(
                                  creator: comicInfo.creator,
                                  from: widget.from,
                                  imageKey: comicInfo.id,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // 章节头：标题 + 计数/倒序 badge（虚拟化列表的 header sliver）。
              _constrainedSliver(
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildDivider(context),
                      _EpisodeHeader(
                        title: t.comicInfo.chapterList,
                        trailing: _EpisodeHeaderBadge(
                          label: t.comicInfo.episodeCount(
                            count: normalComicAllInfo.eps.length,
                          ),
                          icon: _isReversed ? Icons.south : Icons.north,
                          onTap: _toggleOrder,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 章节列表：Sliver 虚拟化，只建可视行。attach 在 _EpisodeBoard
              // 的 initState/didUpdateWidget 里做，不在 build 里调。
              _EpisodeBoard(
                controller: _dlController,
                from: widget.from,
                comicId: _comicId,
                comicTitle: comicInfo.title,
                allowDownload: showDownloadUi,
                displayEps: displayEps,
                downloadAllowed: showDownloadUi,
                downloadDisabledReason: normalComicAllInfo.allowDownloadReason,
                allInfo: comicInfoDyn,
                epsLength: normalComicAllInfo.eps.length,
                type: _type,
                isReversed: _isReversed,
              ),
              if (normalComicAllInfo.recommend.isNotEmpty &&
                  _resolveRecommendItems(
                    normalComicAllInfo.recommend,
                  ).isNotEmpty)
                _constrainedSliver(
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildDivider(context),
                        _SectionCard(
                          title: t.comicInfo.related,
                          child: RecommendWidget(
                            comicList: _resolveRecommendItems(
                              normalComicAllInfo.recommend,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (showPreview) ...[
                _constrainedSliver(const ComicPreviewSliver()),
              ],
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 180),
                sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
            ],
          ),
        );

        if (!showPreview) return refreshable;

        return BlocProvider(
          key: ValueKey('preview:${widget.from}:$_comicId'),
          create: (_) => ComicPreviewBloc(
            comicId: _comicId,
            from: widget.from,
            capability: previewCapability,
            extern: widget.extern ?? const <String, dynamic>{},
          )..add(const LoadComicPreview()),
          child: Builder(
            builder: (context) => NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent * 0.9) {
                  context.read<ComicPreviewBloc>().add(
                    const LoadComicPreview(loadMore: true),
                  );
                }
                return false;
              },
              child: refreshable,
            ),
          ),
        );
      },
    );
  }

  Widget _constrainedSliver(Widget sliver) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _constrainedHorizontalPadding(
          constraints.crossAxisExtent,
        );
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: sliver,
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
    final rawName = _title.trim().isEmpty ? _comicId : _title.trim();
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
          _comicId,
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
        _comicId,
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
    }
  }

  // 切换章节列表的倒序/正序显示
  void _toggleOrder() => setState(() => _isReversed = !_isReversed);

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
      source: widget.from,
      comicId: _comicId,
      info: info,
      lastChapterCount: info.eps.length,
    );
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
      widget.from,
      _comicId,
    );
    await _toggleFollow(isFollowing);
  }

  Future<void> _autoFollowIfEnabled() async {
    if (!context.read<GlobalSettingCubit>().state.autoFollowOnCollect) {
      return;
    }
    final info = _currentInfo;
    if (info == null) {
      return;
    }
    final followCubit = context.read<ComicFollowCubit>();
    if (followCubit.isFollowing(widget.from, _comicId)) {
      return;
    }
    await followCubit.addOrUpdateFollow(
      source: widget.from,
      comicId: _comicId,
      info: info,
      lastChapterCount: info.eps.length,
    );
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
    await context.read<ComicFollowCubit>().removeFollow(widget.from, _comicId);
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

  Future<void> _syncLocalCollectStatus(NormalComicAllInfo info) async {
    // 同一部漫画只同步一次本地收藏状态，避免每次重建都查询数据库
    final comicId = info.comicInfo.id;
    if (_localCollectSyncedFor == comicId) {
      return;
    }
    _localCollectSyncedFor = comicId;
    final collected = await isLocalComicCollected(
      from: widget.from,
      comicId: comicId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isLocalCollected = collected;
    });
  }

  Future<void> _toggleLocalCollectFromMenu() async {
    final info = _currentInfo;
    if (info == null) {
      showErrorToast(t.comicInfo.detailsNotLoaded);
      return;
    }
    try {
      // 取消收藏需要确认，因为会删除所有文件夹中的记录
      if (_isLocalCollected) {
        final confirmed = await _showLocalUncollectConfirmDialog();
        if (!confirmed) {
          return;
        }
      }

      final next = await toggleLocalComicFavorite(
        from: widget.from,
        normalInfo: info,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isLocalCollected = next;
      });
      if (next) {
        await _autoFollowIfEnabled();
      }
      showSuccessToast(
        next
            ? t.comicInfo.addedToCollection
            : t.comicInfo.removedFromCollection,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      showErrorToast(
        t.comicInfo.localCollectFailed(error: normalizeSearchErrorMessage(e)),
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<bool> _showLocalUncollectConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t.comicInfo.confirmUncollectTitle),
          content: Text(t.comicInfo.confirmUncollectContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.common.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(t.common.confirm),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<void> _toggleCloudCollectFromMenu() async {
    final info = _currentInfo;
    if (info == null) {
      showErrorToast(t.comicInfo.detailsNotLoaded);
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
        legacyAllowCollected: info.allowCollected,
        legacyAllowCollectedReason: info.allowCollectedReason,
        collectionTargetId: widget.collectionTargetId,
        collectionTargetName: widget.collectionTargetName,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isCloudCollected = next;
        _cloudFavoriteStateOverridden = true;
      });
      if (next) {
        await _autoFollowIfEnabled();
      }
      showSuccessToast(
        next
            ? t.comicInfo.cloudCollectSuccess
            : t.comicInfo.cloudUncollectSuccess,
      );
    } on FavoriteWorkflowUnsupportedException catch (error) {
      if (mounted) {
        final reason = error.reason.trim();
        showInfoToast(
          reason.isNotEmpty ? reason : t.comicInfo.cloudCollectDisabled,
        );
      }
    } on FavoriteWorkflowIncompleteException catch (error) {
      if (mounted) {
        showInfoToast(error.result.message ?? '云端收藏操作未完成');
      }
    } catch (e) {
      showErrorToast(t.error.operationFailed);
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.title});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: context.theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
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

/// 内容区水平边距：与 _ComicInfoState._constrainedSliver 同一份算法，
/// 章节 sliver 自带 SliverLayoutBuilder，用它算出内容宽度后再选单列/网格。
double _constrainedHorizontalPadding(double crossAxisExtent) =>
    ((crossAxisExtent - 1120) / 2).clamp(20.0, double.infinity).toDouble();

/// 章节列表头（标题 + 计数/倒序 badge），与 _SectionCard 的标题区同样式，
/// 虚拟化后作为独立 sliver，列表本体是下面的 _EpisodeBoard。
class _EpisodeHeader extends StatelessWidget {
  const _EpisodeHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: context.theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

/// 章节列表的 sliver 宿主。
///
/// attach 放在 initState/didUpdateWidget（不在 build 里调），build 只做
/// 带缓存的 adapt + 返回 SliverList/SliverGrid，只建可视行。
/// 断点与原来一致（按内容宽度算）：<560 单列，<720 一列、<960 两列，
/// ≥960 按 320 maxExtent 网格（代替原来全量 build 的 Wrap）。
class _EpisodeBoard extends StatefulWidget {
  const _EpisodeBoard({
    required this.controller,
    required this.from,
    required this.comicId,
    required this.comicTitle,
    required this.allowDownload,
    required this.displayEps,
    required this.downloadAllowed,
    required this.downloadDisabledReason,
    required this.allInfo,
    required this.epsLength,
    required this.type,
    required this.isReversed,
  });

  final EpisodeDownloadController controller;
  final String from;
  final String comicId;
  final String comicTitle;
  final bool allowDownload;
  final List<dynamic> displayEps;
  final bool downloadAllowed;
  final String downloadDisabledReason;
  final dynamic allInfo;
  final int epsLength;
  final ComicEntryType type;
  final bool isReversed;

  @override
  State<_EpisodeBoard> createState() => _EpisodeBoardState();
}

class _EpisodeBoardState extends State<_EpisodeBoard> {
  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateWidget(covariant _EpisodeBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _attach();
  }

  void _attach() {
    widget.controller.attach(
      from: widget.from,
      comicId: widget.comicId,
      comicTitle: widget.comicTitle,
      allowDownload: widget.allowDownload,
    );
  }

  Future<void> _onChapterAction(
    BuildContext context,
    DownloadChapter chapter,
  ) async {
    if (!widget.downloadAllowed) {
      _showDownloadDisabledToast();
      return;
    }
    final status = widget.controller.statusOf(chapter);
    switch (status) {
      case ChapterDownloadStatus.notDownloaded:
      case ChapterDownloadStatus.failed:
        await widget.controller.downloadSingle(context, chapter);
        break;
      case ChapterDownloadStatus.queued:
      case ChapterDownloadStatus.downloading:
        await widget.controller.cancelChapter(context, chapter);
        break;
      case ChapterDownloadStatus.downloaded:
        final wholeDeleted = await widget.controller.deleteSingle(
          context,
          chapter,
        );
        if (wholeDeleted && widget.type == ComicEntryType.download) {
          if (context.mounted) context.pop();
        }
        break;
    }
  }

  // 注意：选中态/下载态不在这里读取，行内部分别监听 selectionCubit /
  // controller 自更新。外层进度 tick 不再全列表重建。
  Widget _buildRow(
    BuildContext context,
    List<DownloadChapter> chapters,
    int i,
  ) {
    final chapter = chapters[i];
    return EpButtonWidget(
      key: ValueKey(chapter.id),
      doc: widget.displayEps[i] as Ep,
      chapter: chapter,
      controller: widget.controller,
      allInfo: widget.allInfo,
      epsLength: widget.epsLength,
      type: widget.type,
      comicId: widget.comicId,
      from: widget.from,
      index: i,
      isReversed: widget.isReversed,
      downloadAllowed: widget.downloadAllowed,
      downloadDisabledReason: widget.downloadDisabledReason,
      onAction: () => _onChapterAction(context, chapter),
      onToggleSelect: () => widget.controller.toggleSelect(chapter.id),
      onEnterSelect: () {
        if (!widget.downloadAllowed) {
          _showDownloadDisabledToast();
          return;
        }
        widget.controller.enterSelection(chapter.id);
      },
    );
  }

  void _showDownloadDisabledToast() {
    final reason = widget.downloadDisabledReason.trim();
    showInfoToast(reason.isNotEmpty ? reason : t.comicInfo.downloadForbidden);
  }

  @override
  Widget build(BuildContext context) {
    // adapt 带元素级缓存：displayEps 引用不变时直接复用，不重建 DownloadChapter。
    final chapters = widget.controller.adaptEps(widget.displayEps);

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _constrainedHorizontalPadding(
          constraints.crossAxisExtent,
        );
        final contentWidth =
            constraints.crossAxisExtent - horizontalPadding * 2;
        final padding = EdgeInsets.only(
          left: horizontalPadding,
          right: horizontalPadding,
          top: 12,
          bottom: 12,
        );

        if (chapters.isEmpty) {
          return SliverPadding(
            padding: padding,
            sliver: SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  t.comicInfo.noChapters,
                  style: context.theme.textTheme.bodyMedium,
                ),
              ),
            ),
          );
        }

        // 窄屏单列，其余按内容宽度切 1/2 列或 maxExtent 网格，全部懒加载。
        if (contentWidth < 560) {
          return SliverPadding(
            padding: padding,
            sliver: SliverList.builder(
              itemCount: chapters.length,
              itemBuilder: (context, i) {
                final chapter = chapters[i];
                return Padding(
                  key: ValueKey('pad:${chapter.id}'),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildRow(context, chapters, i),
                );
              },
            ),
          );
        }

        final SliverGridDelegate gridDelegate;
        if (contentWidth >= 960) {
          gridDelegate = const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 320,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: EpButtonWidget.fixedHeight,
          );
        } else {
          gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: contentWidth >= 720 ? 2 : 1,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: EpButtonWidget.fixedHeight,
          );
        }
        return SliverPadding(
          padding: padding,
          sliver: SliverGrid.builder(
            itemCount: chapters.length,
            gridDelegate: gridDelegate,
            itemBuilder: (context, i) => _buildRow(context, chapters, i),
          ),
        );
      },
    );
  }
}

/// 长按多选时的底部悬浮操作栏：下载 / 删除只对各自适用的子集生效。
class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({
    required this.controller,
    required this.isDownloadType,
  });

  final EpisodeDownloadController controller;
  final bool isDownloadType;

  @override
  Widget build(BuildContext context) {
    final chapters = controller.lastChapters;
    final selected = chapters
        .where((c) => controller.selectedIds.contains(c.id))
        .toList();
    final downloadable = controller.downloadableOf(selected);
    final deletable = controller.downloadedOf(selected);
    final allSelected =
        chapters.isNotEmpty && selected.length >= chapters.length;

    final inSelection = controller.selectionMode;
    return Positioned(
      bottom: 8,
      left: 8,
      right: 8,
      child: IgnorePointer(
        ignoring: !inSelection,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          offset: inSelection ? Offset.zero : const Offset(0, 1.0),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: inSelection ? 1 : 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: t.common.cancel,
                            onPressed: controller.exitSelection,
                            icon: const Icon(Icons.close),
                          ),
                          Text(
                            t.bookshelf.selectedCount(
                              count: controller.selectedIds.length,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: allSelected
                                ? t.bookshelf.deselectAll
                                : t.common.selectAll,
                            onPressed: chapters.isEmpty
                                ? null
                                : () {
                                    if (allSelected) {
                                      controller.clearSelection();
                                    } else {
                                      controller.selectAll(
                                        chapters.map((c) => c.id),
                                      );
                                    }
                                  },
                            icon: Icon(
                              allSelected ? Icons.deselect : Icons.select_all,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: t.comicInfo.download,
                            onPressed: downloadable.isEmpty
                                ? null
                                : () async {
                                    await controller.downloadChapters(
                                      context,
                                      selected,
                                    );
                                  },
                            icon: const Icon(Icons.download_outlined),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: t.common.delete,
                            onPressed: deletable.isEmpty
                                ? null
                                : () async {
                                    final wholeDeleted = await controller
                                        .deleteChapters(context, selected);
                                    if (wholeDeleted) {
                                      controller.exitSelection();
                                      if (isDownloadType && context.mounted) {
                                        context.pop();
                                      }
                                    }
                                  },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
