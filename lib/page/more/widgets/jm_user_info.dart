import 'package:auto_route/auto_route.dart';
import 'package:zephyr/plugin/plugin_constants.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/more/widgets/refresh_event.dart';
import 'package:zephyr/page/setting/common/plugin_user_info_card.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/util/router/router.gr.dart';

class JMUserInfoWidget extends StatefulWidget {
  const JMUserInfoWidget({super.key});

  @override
  State<JMUserInfoWidget> createState() => _JMUserInfoWidgetState();
}

class _JMUserInfoWidgetState extends State<JMUserInfoWidget> {
  bool _loading = true;
  String _error = '';
  Map<String, dynamic> _userInfo = const <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    eventBus.on<RefreshEvent>().listen((_) => _load());
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = '';
      });
    }
    try {
      final response = await callUnifiedComicPlugin(
        from: kJmPluginUuid,
        fnPath: 'getUserInfoBundle',
        core: const <String, dynamic>{},
        extern: const <String, dynamic>{},
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      if (!mounted) {
        return;
      }
      setState(() {
        _userInfo = asJsonMap(envelope.data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading) {
      content = const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_error.isNotEmpty) {
      content = Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: Text('加载失败: $_error')),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
      );
    } else {
      content = PluginUserInfoCard(
        from: kJmPluginUuid,
        avatarUrl: asJsonMap(_userInfo['avatar'])['url']?.toString() ?? '',
        avatarPath:
            asJsonMap(
              asJsonMap(_userInfo['avatar'])['extern'],
            )['path']?.toString() ??
            '',
        lines: asJsonList(
          _userInfo['lines'],
        ).map((item) => item?.toString() ?? '').toList(),
      );
    }

    return Column(
      children: [
        content,
        ListTile(
          leading: const Icon(Icons.manage_accounts_outlined),
          title: const Text('禁漫设置'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushRoute(JMSettingRoute()),
        ),
      ],
    );
  }
}
