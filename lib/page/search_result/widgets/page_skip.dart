import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/search_result/models/models.dart';

import '../../../mobx/string_select.dart';
import '../bloc/search_bloc.dart';
import '../method/search_enter_provider.dart';

class PageSkip extends StatelessWidget {
  final StringSelectStore pageStore;

  final int pagesCount;

  const PageSkip({
    super.key,
    required this.pageStore,
    required this.pagesCount,
  });

  Future<int?> showNumberInputDialog(BuildContext context) async {
    final TextEditingController inputController = TextEditingController();
    final FocusNode focusNode = FocusNode(); // 创建 FocusNode 实例

    return showDialog<int?>(
      context: context,
      builder: (BuildContext innerContext) {
        // 在对话框构建时请求焦点
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(innerContext).requestFocus(focusNode);
        });

        return AlertDialog(
          title: Text('输入页数'),
          content: TextField(
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ],
            decoration: InputDecoration(hintText: '请输入页数（仅支持数字）'),
            controller: inputController,
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                Navigator.of(innerContext).pop(int.parse(value));
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(innerContext).pop(); // 返回 null
              },
            ),
            TextButton(
              child: Text('确定'),
              onPressed: () {
                String number = inputController.text;
                if (number.isNotEmpty) {
                  Navigator.of(innerContext).pop(int.parse(number)); // 返回输入的数字
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchEnter = SearchEnterProvider.of(context)!.searchEnter;
    return FloatingActionButton.extended(
      onPressed: () async {
        final pageSkip = await showNumberInputDialog(context);
        if (pageSkip != 0) {
          if (!context.mounted) return;

          context.read<SearchBloc>().add(
                FetchSearchResult(
                  SearchEnterConst(
                    url: searchEnter.url,
                    from: searchEnter.from,
                    keyword: searchEnter.keyword,
                    type: searchEnter.type,
                    state: '',
                    sort: searchEnter.sort,
                    categories: searchEnter.categories,
                    pageCount: pageSkip!,
                    refresh: searchEnter.refresh,
                  ),
                  SearchStatus.initial,
                ),
              );

          pageStore.setDate("$pageSkip/$pagesCount");
        }
      },
      label: Text('跳页'),
    );
  }
}
