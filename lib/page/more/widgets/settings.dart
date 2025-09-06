import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../util/router/router.gr.dart';

class SettingsWidget extends StatelessWidget {
  const SettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          _buildSettingsItem(
            context: context,
            icon: Icons.settings,
            text: "全局设置",
            onTap: () => context.pushRoute(GlobalSettingRoute()),
          ),
          SizedBox(height: 8),
          _buildSettingsItem(
            context: context,
            icon: Icons.info,
            text: "关于",
            onTap: () => context.pushRoute(AboutRoute()),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            Icon(icon),
            SizedBox(width: 10),
            Text(text, style: TextStyle(fontSize: 22)),
            Spacer(),
          ],
        ),
      ),
    );
  }
}
