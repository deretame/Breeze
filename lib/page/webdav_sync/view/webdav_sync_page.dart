import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:markdown_widget/widget/markdown_block.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/webdav_sync/webdav_sync.dart';

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
  static const WidgetStateProperty<Icon> _thumbIcon =
      WidgetStateProperty<Icon>.fromMap(<WidgetStatesConstraint, Icon>{
        WidgetState.selected: Icon(Icons.check),
        WidgetState.any: Icon(Icons.close),
      });

  final TextEditingController _webdavHost = TextEditingController();
  final TextEditingController _webdavUsername = TextEditingController();
  final TextEditingController _webdavPassword = TextEditingController();
  final TextEditingController _s3Endpoint = TextEditingController();
  final TextEditingController _s3AccessKey = TextEditingController();
  final TextEditingController _s3SecretKey = TextEditingController();
  final TextEditingController _s3Bucket = TextEditingController();
  final TextEditingController _s3Region = TextEditingController();
  final TextEditingController _s3Port = TextEditingController();
  bool _s3UseSSL = true;

  @override
  void initState() {
    super.initState();
    final settings = objectbox.userSettingBox.get(1)!.globalSetting;
    _webdavHost.text = settings.syncSetting.webdavSetting.host;
    _webdavUsername.text = settings.syncSetting.webdavSetting.username;
    _webdavPassword.text = settings.syncSetting.webdavSetting.password;
    _s3Endpoint.text = settings.syncSetting.s3Setting.endpoint;
    _s3AccessKey.text = settings.syncSetting.s3Setting.accessKey;
    _s3SecretKey.text = settings.syncSetting.s3Setting.secretKey;
    _s3Bucket.text = settings.syncSetting.s3Setting.bucket;
    _s3Region.text = settings.syncSetting.s3Setting.region;
    _s3Port.text = settings.syncSetting.s3Setting.port > 0
        ? settings.syncSetting.s3Setting.port.toString()
        : '';
    _s3UseSSL = settings.syncSetting.s3Setting.useSSL;
  }

  @override
  void dispose() {
    _webdavHost.dispose();
    _webdavUsername.dispose();
    _webdavPassword.dispose();
    _s3Endpoint.dispose();
    _s3AccessKey.dispose();
    _s3SecretKey.dispose();
    _s3Bucket.dispose();
    _s3Region.dispose();
    _s3Port.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final globalSettingCubit = context.watch<GlobalSettingCubit>();
    final syncServiceType =
        globalSettingCubit.state.syncSetting.syncServiceType;
    final title = syncServiceType == SyncServiceType.none
        ? '云同步配置'
        : '${syncServiceType.label} 同步配置';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            if (syncServiceType == SyncServiceType.none) ...[
              _buildNoneTip(),
            ] else if (syncServiceType == SyncServiceType.webdav) ...[
              _buildWebDavForm(),
            ] else ...[
              _buildS3Form(),
            ],
            const SizedBox(height: 12),
            if (syncServiceType != SyncServiceType.none)
              Row(
                children: [
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => _clearConfig(syncServiceType),
                    child: const Text('删除配置'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => _testAndSave(syncServiceType),
                    child: const Text('测试连接并保存'),
                  ),
                  const Spacer(),
                ],
              ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => _showQA(context),
                child: const Text('常见问题'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoneTip() {
    return const Padding(
      padding: EdgeInsets.only(top: 24),
      child: Text('请先在全局设置里选择同步服务，再回到这里填写配置。', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildWebDavForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _webdavHost,
          decoration: const InputDecoration(
            labelText: 'WebDAV 地址',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _webdavUsername,
          decoration: const InputDecoration(
            labelText: '账号',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _webdavPassword,
          decoration: const InputDecoration(
            labelText: '密码',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
      ],
    );
  }

  Widget _buildS3Form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _s3Endpoint,
          decoration: const InputDecoration(
            labelText: '服务地址(Endpoint)',
            hintText: '如: s3.amazonaws.com',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _s3AccessKey,
          decoration: const InputDecoration(
            labelText: 'Access Key',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _s3SecretKey,
          decoration: const InputDecoration(
            labelText: 'Secret Key',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _s3Bucket,
          decoration: const InputDecoration(
            labelText: '存储桶(Bucket)的名字',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _s3Region,
          decoration: const InputDecoration(
            labelText: '区域(Region)（可选）',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _s3Port,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '端口（可选）',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          title: const Text('使用 HTTPS/SSL'),
          thumbIcon: _thumbIcon,
          value: _s3UseSSL,
          onChanged: (value) {
            setState(() {
              _s3UseSSL = value;
            });
          },
        ),
      ],
    );
  }

  void _testAndSave(SyncServiceType syncServiceType) async {
    if (syncServiceType == SyncServiceType.webdav) {
      await _testWebDavServer();
      return;
    }

    if (syncServiceType == SyncServiceType.s3) {
      await _testS3Server();
    }
  }

  void _clearConfig(SyncServiceType syncServiceType) {
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    globalSettingCubit.resetState((current, defaults) {
      if (syncServiceType == SyncServiceType.webdav) {
        return current.copyWith(
          syncSetting: current.syncSetting.copyWith(
            webdavSetting: defaults.syncSetting.webdavSetting,
            syncSettings: false,
          ),
        );
      }

      if (syncServiceType == SyncServiceType.s3) {
        return current.copyWith(
          syncSetting: current.syncSetting.copyWith(
            s3Setting: defaults.syncSetting.s3Setting,
            syncSettings: false,
          ),
        );
      }

      return current;
    });

    if (syncServiceType == SyncServiceType.webdav) {
      _webdavHost.clear();
      _webdavUsername.clear();
      _webdavPassword.clear();
    } else if (syncServiceType == SyncServiceType.s3) {
      _s3Endpoint.clear();
      _s3AccessKey.clear();
      _s3SecretKey.clear();
      _s3Bucket.clear();
      _s3Region.clear();
      _s3Port.clear();
      setState(() {
        _s3UseSSL = true;
      });
    }
  }

  Future<void> _testWebDavServer() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在连接 WebDAV 服务器...'),
            ],
          ),
        );
      },
    );

    try {
      await testWebDavServer(
        _webdavHost.text.trim(),
        _webdavUsername.text.trim(),
        _webdavPassword.text,
      );

      if (mounted) {
        context.pop();
      }

      logger.d('WebDAV连接成功');

      if (!mounted) return;

      final globalSettingCubit = context.read<GlobalSettingCubit>();

      globalSettingCubit.updateWebDavSetting(
        (current) => current.copyWith(
          host: _webdavHost.text.trim(),
          username: _webdavUsername.text.trim(),
          password: _webdavPassword.text,
        ),
      );

      eventBus.fire(const NoticeSync(force: true));

      if (!mounted) return;
      commonDialog(context, '成功', 'WebDAV连接成功，已保存设置。');
    } catch (e) {
      logger.e(e);
      if (mounted) {
        context.pop();
      }

      if (!mounted) return;
      commonDialog(context, '错误', '连接失败，请检查网络连接或WebDAV地址是否正确。\n$e');
    }
  }

  Future<void> _testS3Server() async {
    final portText = _s3Port.text.trim();
    final port = portText.isEmpty ? 0 : int.tryParse(portText);
    if (port == null || port < 0 || port > 65535) {
      commonDialog(context, '错误', '端口格式不正确，请输入 0-65535 的数字。');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在连接 S3 服务...'),
            ],
          ),
        );
      },
    );

    try {
      await testS3Server(
        endpoint: _s3Endpoint.text.trim(),
        accessKey: _s3AccessKey.text.trim(),
        secretKey: _s3SecretKey.text,
        bucket: _s3Bucket.text.trim(),
        useSSL: _s3UseSSL,
        port: port,
        region: _s3Region.text.trim(),
      );

      if (mounted) {
        context.pop();
      }

      if (!mounted) return;

      final globalSettingCubit = context.read<GlobalSettingCubit>();
      globalSettingCubit.updateSyncSetting(
        (current) => current.copyWith(
          s3Setting: current.s3Setting.copyWith(
            endpoint: _s3Endpoint.text.trim(),
            accessKey: _s3AccessKey.text.trim(),
            secretKey: _s3SecretKey.text,
            bucket: _s3Bucket.text.trim(),
            region: _s3Region.text.trim(),
            useSSL: _s3UseSSL,
            port: port,
          ),
        ),
      );

      eventBus.fire(const NoticeSync(force: true));

      if (!mounted) return;
      commonDialog(context, '成功', 'S3 连接成功，已保存设置。');
    } catch (e) {
      logger.e(e);
      if (mounted) {
        context.pop();
      }

      if (!mounted) return;
      commonDialog(context, '错误', '连接失败，请检查 S3 配置是否正确。\n$e');
    }
  }

  void _showQA(BuildContext context) {
    final String disclaimerMarkdown = '''
### 可以同步哪些内容？
- 目前同步哔咔历史记录、禁漫收藏和禁漫历史。

### WebDAV 如何配置？
- 填写 WebDAV 地址、账号、密码，点击测试连接并保存即可。

### S3 如何配置？
- Endpoint 示例：`s3.amazonaws.com`、`s3.filebase.com`、`play.min.io`。
- 如果是自建 MinIO，可填写自定义端口，必要时关闭 SSL。

### 自动同步间隔是多久？
- 每 5 分钟自动同步一次。

### 如何手动触发一次同步？
- 在同步配置页测试连接并保存后会触发一次同步。
- 或在全局设置里切换一次自动同步开关。
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
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }
}
