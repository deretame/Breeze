import 'package:flutter/material.dart';
import 'package:zephyr/page/ranking_list/models/plugin_ranking_filter_schema.dart';
import 'package:zephyr/util/context/context_extensions.dart';

class PluginRankingFilterDialog extends StatefulWidget {
  const PluginRankingFilterDialog({
    super.key,
    required this.scheme,
    required this.initialSelections,
  });

  final PluginRankingFilterSchema scheme;
  final Map<String, String> initialSelections;

  @override
  State<PluginRankingFilterDialog> createState() =>
      _PluginRankingFilterDialogState();
}

class _PluginRankingFilterDialogState extends State<PluginRankingFilterDialog> {
  late final Map<String, String> _selections;

  @override
  void initState() {
    super.initState();
    _selections = Map<String, String>.from(widget.initialSelections);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.scheme.title.isNotEmpty ? widget.scheme.title : '筛选'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.scheme.fields
              .map((field) => _buildField(context, field))
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, Map<String, String>.from(_selections)),
          child: const Text('确定'),
        ),
      ],
    );
  }

  Widget _buildField(BuildContext context, PluginChoiceField field) {
    final selectedPath =
        field.findPathByValue(_selections[field.key]) ?? const [];
    final visibleLevelOptionSets = field.buildVisibleLevels(
      _selections[field.key],
    );

    if (visibleLevelOptionSets.length == 1 &&
        visibleLevelOptionSets.first.options.length <= 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (field.label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                field.label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ...visibleLevelOptionSets.asMap().entries.map((entry) {
            final level = entry.key;
            final filterLevel = entry.value;
            final levelOptions = filterLevel.options;
            final selectedValue = selectedPath.length > filterLevel.pathIndex
                ? selectedPath[filterLevel.pathIndex].value
                : '';
            final levelLabel = level == 0
                ? null
                : level == 1
                ? '子分类'
                : '第${level + 1}级分类';

            return Padding(
              padding: EdgeInsets.only(
                bottom: level == visibleLevelOptionSets.length - 1 ? 0 : 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (levelLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        levelLabel,
                        style: TextStyle(
                          color: context.theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: levelOptions.map((option) {
                      final value = option.value;
                      final optionLabel = option.label.isNotEmpty
                          ? option.label
                          : value;
                      final selected = selectedValue == value;

                      return ChoiceChip(
                        label: Text(optionLabel),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (_) {
                          setState(() {
                            _selections[field.key] = value;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
