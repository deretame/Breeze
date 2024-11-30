import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/search/search_page.dart';
import 'package:zephyr/page/search_result/models/search_enter.dart';

import '../../../util/router/router.gr.dart';
import '../../../widgets/error_view.dart';

@RoutePage()
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchKeywordBloc()..add(SearchKeywordEvent()),
      child: _SearchPage(),
    );
  }
}

class _SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('搜索本子'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: BlocBuilder<SearchKeywordBloc, SearchKeywordState>(
                  builder: (context, state) {
                    switch (state.status) {
                      case SearchKeywordStatus.initial:
                        return Center(child: CircularProgressIndicator());
                      case SearchKeywordStatus.failure:
                        return ErrorView(
                          errorMessage: '加载失败，请重试。',
                          onRetry: () {
                            context
                                .read<SearchKeywordBloc>()
                                .add(SearchKeywordEvent());
                          },
                        );
                      case SearchKeywordStatus.success:
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 15.0),
                              // 左边距 10 像素
                              child: Align(
                                alignment: Alignment.centerLeft, // 左对齐
                                child: Text(
                                  "搜索热词",
                                  style: TextStyle(fontSize: 15),
                                ),
                              ),
                            ),
                            KeywordWidget(state.keywords),
                          ],
                        );
                    }
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 80, // 调整这个值以设置 FloatingActionButton 距离底部的距离
            right: 16,
            child: FloatingActionButton(
              child: const Icon(Icons.search),
              onPressed: () {
                AutoRouter.of(context).push(
                  SearchResultRoute(
                    searchEnterConst: SearchEnterConst(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
