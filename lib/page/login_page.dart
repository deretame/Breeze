import 'package:zephyr/plugin/plugin_constants.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/widgets/toast.dart';

import '../util/router/router.gr.dart';

@RoutePage()
class LoginPage extends StatefulWidget {
  final String? from;
  final Map<String, dynamic>? loginScheme;
  final Map<String, dynamic>? loginData;

  const LoginPage({super.key, this.from, this.loginScheme, this.loginData});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _account = TextEditingController();
  final TextEditingController _password = TextEditingController();

  String title = '';
  late String from;
  String accountLabel = '';
  String passwordLabel = '';
  bool _loadingScheme = true;
  String? _schemeError;

  @override
  void initState() {
    super.initState();
    from = sanitizePluginId(widget.from ?? '');
    _loadLoginScheme();
  }

  Future<void> _loadLoginScheme() async {
    if (from.isEmpty) {
      if (mounted) {
        setState(() {
          _schemeError = '缺少插件标识，无法打开登录页';
          _loadingScheme = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _schemeError = null;
        _loadingScheme = true;
      });
    }

    if (widget.loginScheme != null) {
      _applyLoginBundle(widget.loginScheme!, widget.loginData);
      return;
    }

    try {
      final response = await callUnifiedComicPlugin(
        from: from,
        fnPath: 'getLoginBundle',
        core: const <String, dynamic>{},
        extern: const <String, dynamic>{},
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      _applyLoginBundle(envelope.scheme, envelope.data);
    } catch (e) {
      if (mounted) {
        setState(() {
          _schemeError = '登录配置加载失败: $e';
          _loadingScheme = false;
        });
      }
    }
  }

  void _applyLoginBundle(
    Map<String, dynamic> scheme,
    Map<String, dynamic>? data,
  ) {
    final fields = asList(scheme['fields']).map((item) => asMap(item)).toList();
    if (fields.length < 2) {
      if (mounted) {
        setState(() {
          _schemeError = '插件返回的登录字段不足';
          _loadingScheme = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        title = scheme['title']?.toString().trim() ?? '';
        accountLabel = fields.first['label']?.toString().trim() ?? '';
        passwordLabel = fields[1]['label']?.toString().trim() ?? '';
        _schemeError = null;
        _loadingScheme = false;
      });
    }

    final payload = data ?? const <String, dynamic>{};
    _account.text = payload['account']?.toString() ?? _account.text;
    _password.text = payload['password']?.toString() ?? _password.text;
  }

  @override
  void dispose() {
    _account.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _showDialog(String title, String message) async {
    if (message.contains("invalid email or password")) {
      message = "用户名或密码错误，请重新输入";
    }

    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(children: <Widget>[Text(message)]),
          ),
          actions: <Widget>[
            TextButton(child: const Text('确定'), onPressed: () => context.pop()),
          ],
        );
      },
    );
  }

  void _submitForm() async {
    if (!mounted) return;
    if (_loadingScheme || _schemeError != null) {
      showErrorToast('登录配置未就绪，请稍后重试');
      return;
    }
    showInfoToast("正在登录，请耐心等待...");

    try {
      final result = await callUnifiedComicPlugin(
        from: from,
        fnPath: 'loginWithPassword',
        core: {'account': _account.text, 'password': _password.text},
        extern: const <String, dynamic>{},
      );

      final _ = asMap(result['raw']);
      showSuccessToast("登录成功");

      if (!mounted) return;
      context.maybePop();
    } catch (e) {
      logger.e(e);
      _showDialog("登录失败", e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingScheme) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_schemeError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('登录')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_schemeError!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loadLoginScheme,
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => context.pushRoute(GlobalSettingRoute()),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 子组件在水平方向上靠左对齐
          children: <Widget>[
            // 账号输入框
            TextField(
              controller: _account,
              decoration: InputDecoration(
                labelText: accountLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20), // 用于添加空间
            // 密码输入框
            TextField(
              controller: _password,
              decoration: InputDecoration(
                labelText: passwordLabel,
                border: OutlineInputBorder(),
              ),
              obscureText: true, // 隐藏输入内容
            ),
            const SizedBox(height: 10), // 用于添加空间
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // 设置Row中的内容水平居中
              children: [
                TextButton(onPressed: _submitForm, child: const Text('登录')),
              ],
            ),
            const SizedBox(height: 10), // 用于添加空间
            Expanded(
              child: Container(), // 占据剩余空间
            ),
            const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
