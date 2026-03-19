import 'package:flutter/material.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/util/context/context_extensions.dart';

class PluginRankingFilterDialog extends StatefulWidget {
  const PluginRankingFilterDialog({
    super.key,
    required this.scheme,
    required this.initialSelections,
  });

  final Map<String, dynamic> scheme;
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
    final fields = asList(
      widget.scheme['fields'],
    ).map((item) => asMap(item)).where(_isChoiceField).toList();

    return AlertDialog(
      title: Text(widget.scheme['title']?.toString() ?? '筛选'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: fields.map((field) => _buildField(context, field)).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, Map<String, String>.from(_selections)),
          child: const Text('确定'),
        ),
      ],
    );
  }

  Widget _buildField(BuildContext context, Map<String, dynamic> field) {
    final label = field['label']?.toString() ?? '';
    final key = field['key']?.toString() ?? '';
    final options = asList(
      field['options'],
    ).map((item) => asMap(item)).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: options.map((option) {
              final value = option['value']?.toString() ?? '';
              final optionLabel = option['label']?.toString() ?? value;
              final selected = _selections[key] == value;

              return ChoiceChip(
                label: Text(optionLabel),
                selected: selected,
                showCheckmark: false,
                onSelected: (_) {
                  setState(() {
                    _selections[key] = value;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  bool _isChoiceField(Map<String, dynamic> field) {
    return field['kind']?.toString() == 'choice' &&
        (field['key']?.toString().trim().isNotEmpty ?? false);
  }
}
