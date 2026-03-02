import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/page/more/more.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/json/json_dispose.dart';
import 'package:zephyr/widgets/toast.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  late final bool _showBikaSection;

  // 用于清理 EventBus 监听
  StreamSubscription? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    final settings = objectbox.userSettingBox.get(1)!.globalSetting;
    _showBikaSection = !settings.disableBika;

    _refreshSubscription = eventBus.on<RefreshEvent>().listen((event) async {
      await _onRefreshEvent();
    });
  }

  @override
  void dispose() {
    // 清理 EventBus 监听器
    _refreshSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('更多'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: () => eventBus.fire(RefreshEvent()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          eventBus.fire(RefreshEvent());
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            if (_showBikaSection)
              _SectionCard(
                title: '哔咔',
                icon: Icons.auto_stories_outlined,
                child: const BikaUserInfoWidget(),
              ),
            if (_showBikaSection) const SizedBox(height: 12),
            const _SectionCard(
              title: '禁漫',
              icon: Icons.person_outline,
              child: JMUserInfoWidget(),
            ),
            const SizedBox(height: 12),
            const _SectionCard(
              title: '应用设置',
              icon: Icons.tune,
              child: SettingsWidget(),
            ),
            const SizedBox(height: 8),
            Center(child: Text('下拉或点击右上角可刷新账号状态', style: textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefreshEvent() async {
    if (!mounted) return;

    final jmCubit = context.read<JmSettingCubit>();
    final jmState = jmCubit.state;

    if (jmState.account.isEmpty || jmState.password.isEmpty) {
      showErrorToast("禁漫账号或密码为空，无法重新登录");
      return;
    }

    jmCubit.updateLoginStatus(LoginStatus.loggingIn);

    try {
      final value = await login(jmState.account, jmState.password);

      if (!mounted) return;

      jmCubit.updateUserInfo(value.let(replaceNestedNull).let(jsonEncode));
      jmCubit.updateLoginStatus(LoginStatus.login);
      logger.d(jmCubit.state.userInfo);
    } catch (e, s) {
      if (!mounted) return;

      logger.e(e, stackTrace: s);
      jmCubit.updateLoginStatus(LoginStatus.logout);
      showErrorToast("重新登录禁漫失败: ${e.toString()}");
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            dense: true,
          ),
          Divider(color: theme.dividerColor, height: 1),
          child,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
