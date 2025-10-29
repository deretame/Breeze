import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/search_result/models/models.dart';

import '../../../cubit/string_select.dart';
import '../bloc/search_bloc.dart';

class PageSkip extends StatelessWidget {
  final int pagesCount;
  final SearchEnter searchEnter;
  final ValueChanged<SearchEnter> onChanged;

  const PageSkip({
    super.key,
    required this.pagesCount,
    required this.searchEnter,
    required this.onChanged,
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
              FilteringTextInputFormatter.digitsOnly,
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
    final pageCubit = context.read<StringSelectCubit>();
    return FloatingActionButton.extended(
      onPressed: () async {
        final pageSkip = await showNumberInputDialog(context);
        if (pageSkip != null) {
          if (!context.mounted) return;

          final newSearchEnter = searchEnter.copyWith(
            pageCount: pageSkip,
            refresh: searchEnter.refresh,
          );
          context.read<SearchBloc>().add(
            FetchSearchResult(newSearchEnter, SearchStatus.initial),
          );

          onChanged(newSearchEnter);
          pageCubit.updateDate("$pageSkip/$pagesCount");
        }
      },
      label: Text('跳页'),
    );
  }
}
