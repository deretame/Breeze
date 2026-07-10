import 'package:flutter/material.dart';
import 'package:zephyr/i18n/strings.g.dart';

class BookshelfEmptyView extends StatelessWidget {
  const BookshelfEmptyView({
    super.key,
    this.title = '',
    this.icon = Icons.folder_open_outlined,
    this.onRefresh,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async => onRefresh?.call(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 72, color: theme.colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      title.isEmpty ? t.comicList.nothingHere : title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    if (onRefresh != null) ...[
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: onRefresh,
                        icon: const Icon(Icons.refresh),
                        label: Text(t.common.refresh),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
