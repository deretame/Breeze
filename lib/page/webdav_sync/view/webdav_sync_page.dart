import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:zephyr/page/webdav_sync/webdav_sync.dart';

import '../../../main.dart';
import '../../../util/dialog.dart';
import '../../main.dart';

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
    _webdavHost.text = globalSetting.webdavHost;
    _webdavUsername.text = globalSetting.webdavUsername;
    _webdavPassword.text = globalSetting.webdavPassword;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('webdav 同步'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 子组件在水平方向上靠左对齐
          children: <Widget>[
            TextField(
              controller: _webdavHost,
              decoration: const InputDecoration(
                labelText: 'webdav 地址',
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
                    globalSetting.deleteWebdavHost();
                    globalSetting.deleteWebdavUsername();
                    globalSetting.deleteWebdavPassword();
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
            )
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
        Navigator.of(context).pop();
      }

      debugPrint('webdav连接成功');
      globalSetting.setWebdavHost(_webdavHost.text);
      globalSetting.setWebdavUsername(_webdavUsername.text);
      globalSetting.setWebdavPassword(_webdavPassword.text);

      eventBus.fire(NoticeSync());

      if (!mounted) return;
      commonDialog(
        context,
        "成功",
        "webdav连接成功，已保存设置。",
      );
    } catch (e) {
      // 关闭加载框
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;
      commonDialog(
        context,
        "错误",
        "连接失败，请检查网络连接或webdav地址是否正确。\n$e",
      );
    }
  }

  void _showQA(BuildContext context) {
    final String disclaimerMarkdown = '''
### 什么是 webdav？怎么用？
- 请百度
### 哪里有 webdav 服务器？
- 国内可以使用坚果云，国外服务可以使用 InfiniCLOUD，或者自建服务器使用
### 可以同步那些东西？
- 仅可以同步历史记录
### 同步间隔时长是？
- 五分钟
### 如何手动触发一次同步？
- 手动开关一次自动同步即可触发一次同步
''';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('常见问题'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite, // 设置最大宽度
              child: MarkdownBody(
                data: disclaimerMarkdown,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('关闭'),
            ),
          ],
        );
      },
    );
  }
}
