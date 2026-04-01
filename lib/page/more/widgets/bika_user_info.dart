import 'package:auto_route/auto_route.dart';
import 'package:zephyr/plugin/plugin_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/setting/common/plugin_user_info_card.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/page/more/widgets/refresh_event.dart';

class BikaUserInfoWidget extends StatefulWidget {
  const BikaUserInfoWidget({super.key});

  @override
  State<BikaUserInfoWidget> createState() => _BikaUserInfoWidgetState();
}

class _BikaUserInfoWidgetState extends State<BikaUserInfoWidget> {
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
        from: kBikaPluginUuid,
        fnPath: 'getUserInfoBundle',
        core: const <String, dynamic>{},
        extern: const <String, dynamic>{},
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      final userInfo = asJsonMap(envelope.data);
      if (!mounted) {
        return;
      }
      context.read<BikaSettingCubit>().updateSignIn(
        asJsonMap(userInfo['extern'])['isPunched'] == true,
      );
      setState(() {
        _userInfo = userInfo;
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
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: Text('加载失败: $_error')),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
      );
    }

    return Column(
      children: [
        PluginUserInfoCard(
          from: kBikaPluginUuid,
          avatarUrl: asJsonMap(_userInfo['avatar'])['url']?.toString() ?? '',
          avatarPath:
              asJsonMap(
                asJsonMap(_userInfo['avatar'])['extern'],
              )['path']?.toString() ??
              '',
          lines: asJsonList(
            _userInfo['lines'],
          ).map((item) => item?.toString() ?? '').toList(),
        ),
        ListTile(
          leading: const Icon(Icons.manage_accounts_outlined),
          title: const Text('哔咔设置'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushRoute(GlobalSettingRoute()),
        ),
      ],
    );
  }
}
