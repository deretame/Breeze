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
        width: context.screenWidth * (48 / 50),
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
  return GestureDetector(
    onTap: () {
      AutoRouter.of(context).push(const ThemeColorRoute());
    },
    behavior: HitTestBehavior.opaque,
    child: Row(
      children: [
        const SizedBox(width: 10),
        const Text("主题颜色", style: TextStyle(fontSize: 18)),
        Expanded(child: Container()),
        const Icon(Icons.chevron_right),
        const SizedBox(width: 10),
      ],
    ),
  );
}

Widget socks5ProxyEdit(BuildContext context, String currentProxy) {
  return GestureDetector(
    onTap: () async {
      final globalSettingCubit = context.read<GlobalSettingCubit>();
      final controller = TextEditingController(text: currentProxy);

      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('设置SOCKS5代理'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'ip:port',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(context, controller.text.trim()),
            ),
          ],
        ),
      );

      controller.dispose();

      if (result != null && result != currentProxy) {
        globalSettingCubit.updateSocks5Proxy(result);
        showSuccessToast('设置成功，重启生效');
      }
    },
    behavior: HitTestBehavior.opaque,
    child: Row(
      children: [
        const SizedBox(width: 10),
        const Text("SOCKS5代理", style: TextStyle(fontSize: 18)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(
              currentProxy,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
        const Icon(Icons.chevron_right),
        const SizedBox(width: 10),
      ],
    ),
  );
}

Widget webdavSync(BuildContext context) {
  return GestureDetector(
    onTap: () {
      AutoRouter.of(context).push(const WebDavSyncRoute());
    },
    behavior: HitTestBehavior.opaque,
    child: Row(
      children: [
        const SizedBox(width: 10),
        const Text("WebDAV 同步", style: TextStyle(fontSize: 18)),
        Expanded(child: Container()),
        const Icon(Icons.chevron_right),
        const SizedBox(width: 10),
      ],
    ),
  );
}

Widget editMaskedKeywords(BuildContext context) {
  return GestureDetector(
    onTap: () {
      showDialog(
        context: context,
        builder: (context) => const _KeywordManagementDialog(),
      );
    },
    behavior: HitTestBehavior.opaque,
    child: Row(
      children: [
        const SizedBox(width: 10),
        const Text("屏蔽关键词管理", style: TextStyle(fontSize: 18)),
        Expanded(child: Container()),
        const Icon(Icons.chevron_right),
        const SizedBox(width: 10),
      ],
    ),
  );
}

class _KeywordManagementDialog extends StatefulWidget {
  const _KeywordManagementDialog();

  @override
  State<_KeywordManagementDialog> createState() =>
      _KeywordManagementDialogState();
}

class _KeywordManagementDialogState extends State<_KeywordManagementDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 只需要在这里获取 Cubit
    final globalSettingCubit = context.read<GlobalSettingCubit>();

    return BlocBuilder<GlobalSettingCubit, GlobalSettingState>(
      builder: (context, state) {
        return AlertDialog(
          title: const Text('屏蔽关键词管理'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.maskedKeywords.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          "暂无屏蔽词",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(state.maskedKeywords.length, (
                        index,
                      ) {
                        return Chip(
                          label: Text(state.maskedKeywords[index]),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            final newList = List<String>.from(
                              state.maskedKeywords,
                            );
                            newList.removeAt(index);
                            globalSettingCubit.updateMaskedKeywords(newList);
                          },
                        );
                      }),
                    ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: '输入新关键词',
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (_) =>
                              _addKeyword(globalSettingCubit, state),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        color: Theme.of(context).primaryColor,
                        iconSize: 32,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _addKeyword(globalSettingCubit, state),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('关闭'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _addKeyword(GlobalSettingCubit cubit, GlobalSettingState state) {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !state.maskedKeywords.contains(text)) {
      final newList = [...state.maskedKeywords, text];
      cubit.updateMaskedKeywords(newList);
      _controller.clear();
    }
  }
}
