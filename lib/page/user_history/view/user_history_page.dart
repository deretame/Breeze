import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/page/user_history/user_history.dart';

import '../../../main.dart';
import '../../../widgets/comic_entry/comic_entry.dart';

@RoutePage()
class UserHistoryPage extends StatelessWidget {
  final SearchEnterConst searchEnterConst;

  const UserHistoryPage({
    super.key,
    required this.searchEnterConst,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserHistoryBloc()..add(UserHistoryEvent(searchEnterConst)),
      child: _UserHistoryPage(searchEnterConst: searchEnterConst),
    );
  }
}

class _UserHistoryPage extends StatefulWidget {
  final SearchEnterConst searchEnterConst;

  const _UserHistoryPage({
    required this.searchEnterConst,
  });

  @override
  State<_UserHistoryPage> createState() => _UserHistoryPageState();
}

class _UserHistoryPageState extends State<_UserHistoryPage>
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
                    child: BlocBuilder<UserHistoryBloc, UserHistoryState>(
                      builder: (context, state) {
                        switch (state.status) {
                          case UserHistoryStatus.initial:
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          case UserHistoryStatus.failure:
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _showErrorDialog(
                                context,
                                "漫画加载失败:\n${state.result}",
                                state.searchEnterConst,
                              );
                            });
                            // 因为必须要返回一个 Widget，所以这里返回一个空白的 SizedBox
                            return SizedBox.shrink();
                          case UserHistoryStatus.success:
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
                                          comicEntryInfo:
                                              convertToComicEntryInfo(
                                            state.comics[index],
                                          ),
                                          type: ComicEntryType.history,
                                          historySearchEnter:
                                              state.searchEnterConst,
                                          historyRefresh: refresh,
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
    context.read<UserHistoryBloc>().add(
          UserHistoryEvent(
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
