import 'package:flutter/material.dart';

class PluginStoreStatusBanner extends StatelessWidget {
  const PluginStoreStatusBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = colorScheme.primaryContainer;
    final foregroundColor = colorScheme.onPrimaryContainer;
    final leading = SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        color: foregroundColor,
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              trimmedMessage,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: foregroundColor),
            ),
          ),
        ],
      ),
    );
  }
}
