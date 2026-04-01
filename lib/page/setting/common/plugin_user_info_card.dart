import 'package:flutter/material.dart';
import 'package:zephyr/widgets/comic_simplify_entry/cover.dart';
import 'package:zephyr/type/enum.dart';

class PluginUserInfoCard extends StatelessWidget {
  const PluginUserInfoCard({
    super.key,
    required this.from,
    required this.avatarUrl,
    required this.avatarPath,
    required this.lines,
  });

  final String from;
  final String avatarUrl;
  final String avatarPath;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final displayLines = lines
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(3)
        .toList();

    if (displayLines.isEmpty &&
        avatarUrl.trim().isEmpty &&
        avatarPath.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in displayLines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(line),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (avatarUrl.trim().isEmpty && avatarPath.trim().isEmpty) {
      return const CircleAvatar(radius: 34, child: Icon(Icons.person));
    }
    return ClipOval(
      child: CoverWidget(
        fileServer: avatarUrl,
        path: avatarPath,
        id: 'plugin_user_avatar',
        pictureType: PictureType.user,
        from: from,
        width: 68,
        height: 68,
      ),
    );
  }
}
