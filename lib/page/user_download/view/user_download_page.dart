import 'dart:io';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/page/user_download/user_download.dart';

import '../../../main.dart';
import '../../../widgets/comic_entry/comic_entry.dart';

@RoutePage()
class UserDownloadPage extends StatelessWidget {
  final SearchEnterConst searchEnterConst;

  const UserDownloadPage({
    super.key,
    required this.searchEnterConst,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          UserDownloadBloc()..add(UserDownloadEvent(searchEnterConst)),
      child: _UserDownloadPage(searchEnterConst: searchEnterConst),
    );
  }
}

class _UserDownloadPage extends StatefulWidget {
  final SearchEnterConst searchEnterConst;

  const _UserDownloadPage({
    required this.searchEnterConst,
  });

  @override
  State<_UserDownloadPage> createState() => _UserDownloadPageState();
}

class _UserDownloadPageState extends State<_UserDownloadPage>
    with SingleTickerProviderStateMixin {
  get searchEnterConst => widget.searchEnterConst;

  late SearchEnter _searchEnter;

  @override
  void initState() {
    super.initState();
    _searchEnter = SearchEnter.fromConst(searchEnterConst);
  }

  @override
  Widget build(BuildContext context) {
    return SearchEnterProvider(
      searchEnter: _searchEnter,
      child: Scaffold(
        appBar: BikaSearchBar(),
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Column(
                children: <Widget>[
                  SizedBox(height: 35), // 为顶部阴影容器预留空间
                  Expanded(
                    child: BlocBuilder<UserDownloadBloc, UserDownloadState>(
                      builder: (context, state) {
                        switch (state.status) {
                          case UserDownloadStatus.initial:
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          case UserDownloadStatus.failure:
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _showErrorDialog(
                                context,
                                "漫画加载失败:\n${state.result}",
                                state.searchEnterConst,
                              );
                            });
                            // 因为必须要返回一个 Widget，所以这里返回一个空白的 SizedBox
                            return SizedBox.shrink();
                          case UserDownloadStatus.success:
                            _update(state.searchEnterConst);
                            if (state.comics.isEmpty) {
                              return const Center(
                                child: Text(
                                  '啥都没有',
                                  style: TextStyle(fontSize: 20.0),
                                ),
                              );
                            }
                            return RefreshIndicator(
                              onRefresh: () async {
                                // 触发刷新操作
                                refresh(state.searchEnterConst);
                              },
                              child: ListView.builder(
                                itemBuilder: (BuildContext context, int index) {
                                  // 如果索引等于状态的 comics.length
                                  if (index == state.comics.length) {
                                    return _deletingDialog();
                                  }

                                  return index >= state.comics.length
                                      ? const BottomLoader()
                                      : ComicEntryWidget(
                                          comicEntryInfo:
                                              convertToComicEntryInfo(
                                            state.comics[index],
                                          ),
                                          type: ComicEntryType.download,
                                          refresh: () {
                                            refresh(
                                              SearchEnterConst.from(
                                                _searchEnter,
                                              ),
                                            );
                                          },
                                        );
                                },
                                itemCount: state.comics.length + 1,
                              ),
                            );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            // 这里是操作栏
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 35,
                decoration: BoxDecoration(
                  color: globalSetting.backgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: materialColorScheme.secondaryFixedDim,
                      spreadRadius: 0,
                      blurRadius: 2,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    SizedBox(width: 5),
                    SortWidget(),
                    SizedBox(width: 5),
                    CategoriesSelect(),
                    SizedBox(width: 5),
                    CategoriesShield(),
                    Expanded(child: Container()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(
    BuildContext context,
    String errorMessage,
    SearchEnterConst searchEnterConst,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('加载失败'),
          content: SingleChildScrollView(
            child: Text(errorMessage),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('重新加载'),
              onPressed: () {
                refresh(searchEnterConst);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void refresh(SearchEnterConst searchEnterConst) {
    // 使用原本输入参数进行重新搜索
    context.read<UserDownloadBloc>().add(
          UserDownloadEvent(
            SearchEnterConst(
              keyword: searchEnterConst.keyword,
              sort: searchEnterConst.sort,
              categories: searchEnterConst.categories,
              refresh: Uuid().v4(), //传入一个不一样的值，来强行刷新
            ),
          ),
        );
  }

  void _update(SearchEnterConst searchEnterConst) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _searchEnter = SearchEnter.fromConst(searchEnterConst);
      });
    });
  }

  Future<void> deleteDirectory(String path) async {
    final directory = Directory(path);

    // 检查目录是否存在
    if (await directory.exists()) {
      try {
        // 删除目录及其内容
        await directory.delete(recursive: true);
        debugPrint('目录已成功删除: $path');
      } catch (e) {
        debugPrint('删除目录时发生错误: $e');
      }
    } else {
      debugPrint('目录不存在: $path');
    }
  }

  Widget _deletingDialog() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: ElevatedButton(
          onPressed: () {
            // 弹出确认对话框
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('确认删除'),
                  content: Text('确定要删除所有下载记录及其文件吗？此操作不可恢复！'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        // 关闭对话框
                        Navigator.of(context).pop();
                      },
                      child: Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        // 执行删除操作
                        objectbox.bikaDownloadBox.removeAll();
                        deleteDirectory(
                          '/data/data/com.zephyr.breeze/files/downloads',
                        );
                        refresh(searchEnterConst);
                        EasyLoading.showSuccess('已清空');

                        // 关闭对话框
                        Navigator.of(context).pop();
                      },
                      child: Text('确认'),
                    ),
                  ],
                );
              },
            );
          },
          child: const Text("删除所有下载记录及其文件"),
        ),
      ),
    );
  }
}
