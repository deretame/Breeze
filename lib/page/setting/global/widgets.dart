import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '屏蔽关键词',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '添加过滤不喜欢的内容标签',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(
                    minHeight: 120,
                    maxHeight: 240,
                  ),
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: state.maskedKeywords.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 36),
                              child: Text(
                                "暂无屏蔽词",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(
                              state.maskedKeywords.length,
                              (index) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        state.maskedKeywords[index],
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () {
                                            final newList = List<String>.from(
                                              state.maskedKeywords,
                                            );
                                            newList.removeAt(index);
                                            globalSettingCubit.updateState(
                                              (current) => current.copyWith(
                                                maskedKeywords: newList,
                                              ),
                                            );
                                          },
                                          child: Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '输入新关键词...',
                          hintStyle: const TextStyle(fontSize: 14),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) =>
                            _addKeyword(globalSettingCubit, state),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () => _addKeyword(globalSettingCubit, state),
                      icon: const Icon(Icons.add, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('完成'),
                  ),
                ),
              ],
            ),
          ),
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
