import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/page/comic_info/comic_info.dart';
import 'package:zephyr/page/comic_info/json/jm/jm_comic_info_json.dart'
    show JmComicInfoJson;
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/permission.dart';
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
                  collectJmComicToLocal(comicInfoDyn as JmComicInfoJson);
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
          ? SizedBox(
              width: 100,
              height: 56,
              child: FloatingActionButton(
                onPressed: () => goToComicRead(
                  context,
                  widget.comicId,
                  widget.type,
                  comicInfoDyn,
                  widget.from,
                ),
                child: Text(
                  stringSelectDate.isNotEmpty ? '继续阅读' : '开始阅读',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
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

    var widgets = [
      const SizedBox(height: 10),
      ComicParticularsWidget(comicInfo: comicInfo, from: widget.from),
      const SizedBox(height: 10),
    ];

    if (comicInfo.author.isNotEmpty) {
      widgets.add(
        AllChipWidget(
          comicId: comicInfo.id,
          type: 'author',
          chips: comicInfo.author,
          from: widget.from,
        ),
      );
    }

    if (comicInfo.chineseTeam.isNotEmpty) {
      widgets.add(
        AllChipWidget(
          comicId: comicInfo.id,
          type: 'chineseTeam',
          chips: comicInfo.chineseTeam,
          from: widget.from,
        ),
      );
    }

    if (comicInfo.categories.isNotEmpty) {
      widgets.add(
        AllChipWidget(
          comicId: comicInfo.id,
          type: 'categories',
          chips: comicInfo.categories,
          from: widget.from,
        ),
      );
    }

    if (comicInfo.tags.isNotEmpty) {
      widgets.add(
        AllChipWidget(
          comicId: comicInfo.id,
          type: 'tags',
          chips: comicInfo.tags,
          from: widget.from,
        ),
      );
    }

    if (comicInfo.actors.isNotEmpty) {
      widgets.add(
        AllChipWidget(
          comicId: comicInfo.id,
          type: 'actors',
          chips: comicInfo.actors,
          from: widget.from,
        ),
      );
    }

    if (comicInfo.works.isNotEmpty) {
      widgets.add(
        AllChipWidget(
          comicId: comicInfo.id,
          type: 'works',
          chips: comicInfo.works,
          from: widget.from,
        ),
      );
    }

    if (comicInfo.description != '') {
      widgets.add(const SizedBox(height: 3));
      widgets.add(
        SelectableText(
          comicInfo.description.let(t2s),
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
      );
    }

    if (widget.from == From.bika) {
      widgets.add(const SizedBox(height: 10));
      widgets.add(CreatorInfoWidget(comicInfo: comicInfo));
    }

    widgets.add(const SizedBox(height: 10));
    widgets.add(
      ComicOperationWidget(
        normalComicInfo: comicInfo,
        from: widget.from,
        comicInfo: comicInfoDyn,
      ),
    );

    for (var e in displayEps) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: EpButtonWidget(
            doc: e,
            allInfo: comicInfoDyn,
            epsLength: normalComicAllInfo.eps.length,
            type: _type,
            comicId: widget.comicId,
            from: widget.from,
          ),
        ),
      );
    }

    widgets.addAll([
      const SizedBox(height: 10),
      RecommendWidget(
        comicList: normalComicAllInfo.recommend,
        from: widget.from,
      ),
      const SizedBox(height: 180),
    ]);

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
        padding: EdgeInsets.symmetric(horizontal: context.screenWidth / 50),
        itemCount: widgets.length,
        itemBuilder: (context, index) => widgets[index],
      ),
    );
  }

  // 弹出选择对话框，让用户选择导出为压缩包还是文件夹
  Future<ExportType?> showExportTypeDialog() async {
    return await showDialog<ExportType>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('选择导出方式'),
          content: Text('请选择将漫画导出为压缩包还是文件夹：'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(ExportType.folder); // 返回文件夹选项
              },
              child: Text('文件夹'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(ExportType.zip); // 返回压缩包选项
              },
              child: Text('压缩包'),
            ),
          ],
        );
      },
    );
  }

  // 导出逻辑
  Future<void> _handleExport() async {
    try {
      if (!await requestExportPermission()) {
        showErrorToast("请授予存储权限！");
        return;
      }
      if (mounted) {
        var choice = await showExportTypeDialog();
        if (choice == null) return;

        String? path;

        if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
          if (choice == ExportType.folder) {
            path = await getDirectoryPath();
          } else {
            final result = await getSaveLocation(
              suggestedName: "$_title.zip",
              acceptedTypeGroups: [
                XTypeGroup(label: 'ZIP', extensions: ['zip']),
              ],
            );
            path = result?.path;
          }

          if (path == null) return;
        }

        if (mounted) {
          exportComic(widget.comicId, choice, widget.from, path: path);
        }
      }
    } catch (e) {
      showErrorToast(
        "导出失败，请重试。\n${e.toString()}",
        duration: const Duration(seconds: 5),
      );
    }
  }

  // 实现章节倒序逻辑
  void _toggleOrder() => setState(() => _isReversed = !_isReversed);
}
