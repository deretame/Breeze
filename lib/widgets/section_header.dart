import 'package:flutter/material.dart';
import 'package:zephyr/util/context/context_extensions.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle = '',
    this.onTap,
    this.margin = const EdgeInsets.all(5),
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final canNavigate = onTap != null;

    return Padding(
      padding: margin,
      child: Container(
        decoration: BoxDecoration(
          color: context.theme.colorScheme.secondaryFixed.withValues(
            alpha: 0.1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: GestureDetector(
          onTap: canNavigate ? onTap : null,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (subtitle.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      color: context.theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (canNavigate)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: context.theme.colorScheme.onSurface.withValues(
                    alpha: 0.5,
                  ),
                ),

              if (canNavigate) const SizedBox(width: 5),
            ],
          ),
        ),
      ),
    );
  }
}
