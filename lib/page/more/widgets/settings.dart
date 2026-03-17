import 'package:auto_route/auto_route.dart';
import 'package:zephyr/util/ui/fluent_compat.dart';

import '../../../util/router/router.gr.dart';

class SettingsWidget extends StatelessWidget {
  const SettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSettingsItem(
          context: context,
          icon: Icons.settings_outlined,
          text: '全局设置',
          onTap: () => context.pushRoute(GlobalSettingRoute()),
        ),
        _buildSettingsItem(
          context: context,
          icon: Icons.history,
          text: '更新日志',
          onTap: () => context.pushRoute(ChangelogRoute()),
        ),
        _buildSettingsItem(
          context: context,
          icon: Icons.info_outline,
          text: '关于',
          onTap: () => context.pushRoute(AboutRoute()),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}


