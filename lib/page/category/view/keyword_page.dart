import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/category/category.dart';

import '../../../widgets/error_view.dart';

class KeywordPage extends StatelessWidget {
  const KeywordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchKeywordBloc()..add(SearchKeywordEvent()),
      child: _KeywordPage(),
    );
  }
}

class _KeywordPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<SearchKeywordBloc, SearchKeywordState>(
          builder: (context, state) {
            switch (state.status) {
              case SearchKeywordStatus.initial:
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              case SearchKeywordStatus.failure:
                return ErrorView(
                  errorMessage: '加载失败，请重试。',
                  onRetry: () {
                    context.read<SearchKeywordBloc>().add(SearchKeywordEvent());
                  },
                );
              case SearchKeywordStatus.success:
                return KeywordWidget(state.keywords);
            }
          },
        ),
      ],
    );
  }
}
