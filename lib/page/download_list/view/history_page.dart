import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/page/download_list/download_list.dart';

import '../../../main.dart';
import '../../../widgets/comic_entry/comic_entry.dart';

@RoutePage()
class DownloadListPage extends StatelessWidget {
  final SearchEnterConst searchEnterConst;

  const DownloadListPage({
    super.key,
    required this.searchEnterConst,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DownloadListBloc()..add(DownloadListEvent(searchEnterConst)),
      child: _DownloadListPage(searchEnterConst: searchEnterConst),
    );
  }
}

class _DownloadListPage extends StatefulWidget {
  final SearchEnterConst searchEnterConst;

  const _DownloadListPage({
    required this.searchEnterConst,
  });

  @override
  State<_DownloadListPage> createState() => _DownloadListPageState();
}

class _DownloadListPageState extends State<_DownloadListPage>
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
                    child: BlocBuilder<DownloadListBloc, DownloadListState>(
                      builder: (context, state) {
                        switch (state.status) {
                          case DownloadListStatus.initial:
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          case DownloadListStatus.failure:
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _showErrorDialog(
                                context,
                                "漫画加载失败:\n${state.result}",
                                state.searchEnterConst,
                              );
                            });
                            // 因为必须要返回一个 Widget，所以这里返回一个空白的 SizedBox
                            return SizedBox.shrink();
                          case DownloadListStatus.success:
                            _update(state.searchEnterConst);
                            if (state.comics.isEmpty) {
                              return const Center(
                                child: Text(
                                  '啥都没有',
                                  style: TextStyle(fontSize: 20.0),
                                ),
                              );
                            }
                            return ListView.builder(
                              itemBuilder: (BuildContext context, int index) {
                                // 如果索引等于状态的 comics.length
                                if (index == state.comics.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(30.0),
                                      child: Text(
                                        '你来到了未知领域呢~',
                                        style: TextStyle(fontSize: 20.0),
                                      ),
                                    ),
                                  );
                                }

                                return index >= state.comics.length
                                    ? const BottomLoader()
                                    : ComicEntryWidget(
                                        comicEntryInfo: convertToComicEntryInfo(
                                          state.comics[index],
                                        ),
                                        type: ComicEntryType.download,
                                      );
                              },
                              itemCount: state.comics.length + 1,
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
                      color: globalSetting.themeType
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.3),
                      spreadRadius: 2,
                      blurRadius: 2,
                      offset: const Offset(0, 2),
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
              child: const Text('重新加载'),
              onPressed: () {
                _refresh(searchEnterConst);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _refresh(SearchEnterConst searchEnterConst) {
    // 使用原本输入参数进行重新搜索
    context.read<DownloadListBloc>().add(
          DownloadListEvent(
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
}
