import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../util/router/router.gr.dart';

class DividerWidget extends StatelessWidget {
  const DividerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: context.screenWidth * (48 / 50), // 设置宽度
        child: Divider(
          color: context.theme.colorScheme.secondaryFixedDim,
          thickness: 1,
          height: 10,
        ),
      ),
    );
  }
}

Widget changeThemeColor(BuildContext context) {
  final router = AutoRouter.of(context);
  return GestureDetector(
    onTap: () async {
      router.push(ThemeColorRoute());
    },
    behavior: HitTestBehavior.opaque, // 使得所有透明区域也可以响应点击
    child: Row(
      children: [
        SizedBox(width: 10),
        Text("主题颜色", style: TextStyle(fontSize: 18)),
        Expanded(child: Container()),
        Icon(Icons.chevron_right),
        SizedBox(width: 10),
      ],
    ),
  );
}

Widget socks5ProxyEdit(BuildContext context) {
  final globalSettingCubit = context.read<GlobalSettingCubit>();
  final globalSettingState = context.watch<GlobalSettingCubit>().state;
  // 默认代理参数
  String defaultProxy = globalSettingCubit.state.socks5Proxy;
  String currentProxy = defaultProxy; // 当前使用的代理

  return GestureDetector(
    onTap: () async {
      // 弹出输入对话框
      final result = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          TextEditingController controller = TextEditingController(
            text: currentProxy,
          );

          return AlertDialog(
            title: Text('设置SOCKS5代理'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'ip:port',
                border: OutlineInputBorder(),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('取消'),
                onPressed: () {
                  context.pop();
                },
              ),
              TextButton(
                child: Text('确定'),
                onPressed: () {
                  Navigator.of(context).pop(controller.text);
                },
              ),
            ],
          );
        },
      );

      if (result != null) {
        currentProxy = result;
        globalSettingCubit.updateSocks5Proxy(currentProxy);
        showSuccessToast('设置成功，重启生效');
      }
    },
    behavior: HitTestBehavior.opaque,
    child: Row(
      children: [
        SizedBox(width: 10),
        Text("SOCKS5代理", style: TextStyle(fontSize: 18)),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: 10),
            child: Text(
              globalSettingState.socks5Proxy,
              textAlign: TextAlign.end,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
        Icon(Icons.chevron_right),
        SizedBox(width: 10),
      ],
    ),
  );
}

Widget webdavSync(BuildContext context) {
  final router = AutoRouter.of(context);
  return GestureDetector(
    onTap: () async {
      router.push(WebDavSyncRoute());
    },
    behavior: HitTestBehavior.opaque, // 使得所有透明区域也可以响应点击
    child: Row(
      children: [
        SizedBox(width: 10),
        Text("webdav 同步", style: TextStyle(fontSize: 18)),
        Expanded(child: Container()),
        Icon(Icons.chevron_right),
        SizedBox(width: 10),
      ],
    ),
  );
}

Widget editMaskedKeywords(
  BuildContext context,
  TextEditingController keywordController,
) {
  return GestureDetector(
    onTap: () async {
      showKeywordDialog(context, keywordController);
    },
    behavior: HitTestBehavior.opaque, // 使得所有透明区域也可以响应点击
    child: Row(
      children: [
        SizedBox(width: 10),
        Text("屏蔽关键词管理", style: TextStyle(fontSize: 18)),
        Expanded(child: Container()),
        Icon(Icons.chevron_right),
        SizedBox(width: 10),
      ],
    ),
  );
}

void showKeywordDialog(
  BuildContext context,
  TextEditingController keywordController,
) {
  final globalSettingCubit = context.read<GlobalSettingCubit>();

  showDialog(
    context: context,
    builder: (dialogContext) {
      return BlocBuilder<GlobalSettingCubit, GlobalSettingState>(
        builder: (builderContext, globalState) {
          return AlertDialog(
            title: const Text('屏蔽关键词管理'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildKeywordChips(globalState.maskedKeywords, (index) {
                    final newList = List<String>.from(
                      globalState.maskedKeywords,
                    );
                    newList.removeAt(index);
                    globalSettingCubit.updateMaskedKeywords(newList);
                  }),
                  const SizedBox(height: 16),
                  _buildAddKeywordRow(builderContext, keywordController, () {
                    if (keywordController.text.isNotEmpty) {
                      final newList = [
                        ...globalState.maskedKeywords,
                        keywordController.text,
                      ];
                      globalSettingCubit.updateMaskedKeywords(newList);
                      keywordController.clear();
                    }
                  }),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('关闭'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _buildKeywordChips(List<String> keywords, Function(int) onDelete) {
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: List.generate(
      keywords.length,
      (index) => Chip(
        label: Text(keywords[index]),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: () => onDelete(index),
      ),
    ),
  );
}

Widget _buildAddKeywordRow(
  BuildContext context,
  TextEditingController controller,
  VoidCallback onAdd,
) {
  return Row(
    children: [
      Expanded(
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入新关键词',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      const SizedBox(width: 20),
      GestureDetector(onTap: onAdd, child: Icon(Icons.add, size: 20)),
    ],
  );
}
