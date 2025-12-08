import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:markdown_widget/widget/markdown_block.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/webdav_sync/webdav_sync.dart';
import 'package:zephyr/util/settings_hive_utils.dart';

import '../../../main.dart';
import '../../../util/dialog.dart';
import '../../../util/event/event.dart';

@RoutePage()
class WebDavSyncPage extends StatefulWidget {
  const WebDavSyncPage({super.key});

  @override
  State<WebDavSyncPage> createState() => _WebDavSyncPageState();
}

class _WebDavSyncPageState extends State<WebDavSyncPage> {
  final TextEditingController _webdavHost = TextEditingController();
  final TextEditingController _webdavUsername = TextEditingController();
  final TextEditingController _webdavPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    _webdavHost.text = SettingsHiveUtils.webdavHost;
    _webdavUsername.text = SettingsHiveUtils.webdavUsername;
    _webdavPassword.text = SettingsHiveUtils.webdavPassword;
  }

  @override
  void dispose() {
    _webdavHost.dispose();
    _webdavUsername.dispose();
    _webdavPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final globalSettingCubit = context.watch<GlobalSettingCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('WebDAV 同步')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 子组件在水平方向上靠左对齐
          children: <Widget>[
            TextField(
              controller: _webdavHost,
              decoration: const InputDecoration(
                labelText: 'WebDAV 地址',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            // 账号输入框
            TextField(
              controller: _webdavUsername,
              decoration: const InputDecoration(
                labelText: '账号',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            // 密码输入框
            TextField(
              controller: _webdavPassword,
              decoration: const InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    globalSettingCubit.resetWebdavHost();
                    globalSettingCubit.resetWebdavUsername();
                    globalSettingCubit.resetWebdavPassword();
                    _webdavHost.clear();
                    _webdavUsername.clear();
                    _webdavPassword.clear();
                  },
                  child: const Text('删除配置'),
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    _testWebDavServer();
                  },
                  child: const Text('测试连接'),
                ),
                Spacer(),
              ],
            ),
            Spacer(),
            Center(
              child: TextButton(
                onPressed: () {
                  _showQA(context);
                },
                child: const Text('常见问题'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testWebDavServer() async {
    // 显示加载框
    showDialog(
      context: context,
      barrierDismissible: false, // 用户不能通过点击外部关闭加载框
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(), // 加载指示器
              SizedBox(height: 16),
              Text('正在连接 WebDAV 服务器...'),
            ],
          ),
        );
      },
    );

    try {
      // 测试 WebDAV 连接
      await testWebDavServer(
        _webdavHost.text,
        _webdavUsername.text,
        _webdavPassword.text,
      );

      // 关闭加载框
      if (mounted) {
        context.pop();
      }

      logger.d('WebDAV连接成功');

      if (!mounted) return;

      final globalSettingCubit = context.read<GlobalSettingCubit>();

      globalSettingCubit.updateWebdavHost(_webdavHost.text);
      globalSettingCubit.updateWebdavUsername(_webdavUsername.text);
      globalSettingCubit.updateWebdavPassword(_webdavPassword.text);

      eventBus.fire(NoticeSync());

      if (!mounted) return;
      commonDialog(context, "成功", "WebDAV连接成功，已保存设置。");
    } catch (e) {
      logger.e(e);
      // 关闭加载框
      if (mounted) {
        context.pop();
      }

      if (!mounted) return;
      commonDialog(context, "错误", "连接失败，请检查网络连接或WebDAV地址是否正确。\n$e");
    }
  }

  void _showQA(BuildContext context) {
    final String disclaimerMarkdown = '''
### 什么是 WebDAV？怎么用？
- WebDAV 是基于 HTTP 的文件管理协议，支持远程创建、编辑、移动文件。可通过支持 WebDAV 的客户端（如 Windows 资源管理器、rclone、Breeze）连接服务器使用。
- 更详细的信息请查询百度等搜索引擎。
### 哪里有 WebDAV 服务器？
- 国内可以使用坚果云，国外服务可以使用 InfiniCLOUD，或者自建服务器使用
### 可以同步那些东西？
- 仅可以同步哔咔的历史记录，禁漫的收藏及历史
### 同步间隔时长是？
- 五分钟
### 如何手动触发一次同步？
- 手动开关一次自动同步即可触发一次同步
''';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: MarkdownBlock(data: disclaimerMarkdown),
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: Text('关闭'),
            ),
          ],
        );
      },
    );
  }
}
