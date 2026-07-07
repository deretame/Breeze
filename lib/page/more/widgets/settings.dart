import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:zephyr/config/router/router.gr.dart';

class SettingsWidget extends StatelessWidget {
  const SettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, '常用', Icons.widgets_outlined),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('下载任务'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushRoute(DownloadTaskRoute()),
        ),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('全局设置'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushRoute(GlobalSettingRoute()),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, thickness: 0.3),
        _buildSectionTitle(context, '其他', Icons.more_horiz),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('更新日志'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushRoute(ChangelogRoute()),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('关于'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushRoute(AboutRoute()),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
