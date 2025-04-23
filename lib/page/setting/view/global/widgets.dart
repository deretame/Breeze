import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../../config/global.dart';
import '../../../../main.dart';
import '../../../../util/router/router.gr.dart';

Widget divider() {
  return Align(
    alignment: Alignment.center,
    child: SizedBox(
      width: screenWidth * (48 / 50), // 设置宽度
      child: Divider(
        color: materialColorScheme.secondaryFixedDim,
        thickness: 1,
        height: 10,
      ),
    ),
  );
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
  // 默认代理参数
  String defaultProxy = globalSetting.socks5Proxy;
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
        globalSetting.setSocks5Proxy(currentProxy);
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
            child: Observer(
              builder: (context) {
                return Text(
                  globalSetting.socks5Proxy,
                  textAlign: TextAlign.end,
                  style: TextStyle(color: Colors.grey),
                );
              },
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
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('屏蔽关键词管理'),
        content: SingleChildScrollView(
          // 支持滚动
          child: Observer(
            builder: (context) {
              return Column(
                children: [
                  // 关键词列表（Wrap布局自动换行）
                  _buildKeywordChips(globalSetting.maskedKeywords, (index) {
                    globalSetting.setMaskedKeywords([
                      ...globalSetting.maskedKeywords..removeAt(index),
                    ]);
                  }),
                  const SizedBox(height: 16),
                  // 添加关键词的输入行
                  _buildAddKeywordRow(context, keywordController, () {
                    if (keywordController.text.isNotEmpty) {
                      globalSetting.setMaskedKeywords([
                        ...globalSetting.maskedKeywords,
                        keywordController.text,
                      ]);
                      keywordController.clear();
                    }
                  }),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

Widget _buildKeywordChips(List<String> keywords, Function(int) onDelete) {
  return Observer(
    builder: (context) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(
          globalSetting.maskedKeywords.length,
          (index) => Chip(
            label: Text(globalSetting.maskedKeywords[index]),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () => onDelete(index),
          ),
        ),
      );
    },
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
