import 'package:auto_route/auto_route.dart';
import 'package:zephyr/util/ui/fluent_compat.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../util/router/router.gr.dart';

Widget changeThemeColor(BuildContext context) {
  return ListTile(
    leading: const Icon(Icons.palette_outlined),
    title: const Text('主题颜色'),
    subtitle: const Text('选择主色，统一应用视觉'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      AutoRouter.of(context).push(const ThemeColorRoute());
    },
  );
}

Widget socks5ProxyEdit(BuildContext context, String currentProxy) {
  return ListTile(
    leading: const Icon(Icons.router_outlined),
    title: const Text('SOCKS5 代理'),
    subtitle: Text(
      currentProxy.isEmpty ? '点击设置代理地址（ip:port）' : '当前代理：$currentProxy',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: const Icon(Icons.chevron_right),
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
        globalSettingCubit.updateState(
          (current) => current.copyWith(socks5Proxy: result),
        );
        showSuccessToast('设置成功，重启生效');
      }
    },
  );
}

Widget webdavSync(BuildContext context, SyncServiceType syncServiceType) {
  final title = switch (syncServiceType) {
    SyncServiceType.none => '同步配置',
    _ => '${syncServiceType.label} 同步配置',
  };

  return ListTile(
    leading: const Icon(Icons.cloud_outlined),
    title: Text(title),
    subtitle: const Text('进入页面，配置地址与鉴权信息'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      AutoRouter.of(context).push(const WebDavSyncRoute());
    },
  );
}

Widget editMaskedKeywords(BuildContext context) {
  return ListTile(
    leading: const Icon(Icons.shield_outlined),
    title: const Text('屏蔽关键词管理'),
    subtitle: const Text('添加关键词，过滤不想看到的内容'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      showDialog(
        context: context,
        builder: (context) => const _KeywordManagementDialog(),
      );
    },
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
                          avatar: const Icon(
                            Icons.label_important_outline,
                            size: 18,
                          ),
                          onDeleted: () {
                            final newList = List<String>.from(
                              state.maskedKeywords,
                            );
                            newList.removeAt(index);
                            logger.d(newList);
                            globalSettingCubit.updateState(
                              (current) =>
                                  current.copyWith(maskedKeywords: newList),
                            );
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
                            prefixIcon: Icon(Icons.search_outlined),
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
                      FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('添加'),
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
      cubit.updateState((current) => current.copyWith(maskedKeywords: newList));
      _controller.clear();
    }
  }
}


