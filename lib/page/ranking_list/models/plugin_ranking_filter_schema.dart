import 'package:zephyr/util/json/json_value.dart';

class PluginRankingFilterSchema {
  const PluginRankingFilterSchema({required this.title, required this.fields});

  final String title;
  final List<PluginChoiceField> fields;

  factory PluginRankingFilterSchema.fromMap(Map<String, dynamic> map) {
    return PluginRankingFilterSchema(
      title: map['title']?.toString() ?? '',
      fields: asJsonList(map['fields'])
          .map((item) => PluginChoiceField.fromMap(asJsonMap(item)))
          .where((field) => field.isChoiceField)
          .toList(),
    );
  }

  PluginResolvedRankingFilter resolve({
    required Map<String, String> requestedSelections,
    required Map<String, String> defaultSelections,
  }) {
    final selections = <String, String>{};
    final params = <String, dynamic>{};

    for (final field in fields) {
      final selected = field.resolveOption(
        requestedValue: requestedSelections[field.key],
        fallbackValue: defaultSelections[field.key],
      );
      if (selected == null) {
        continue;
      }

      selections[field.key] = selected.value;
      params.addAll(selected.result);
    }

    return PluginResolvedRankingFilter(selections: selections, params: params);
  }
}

class PluginChoiceField {
  const PluginChoiceField({
    required this.key,
    required this.label,
    required this.kind,
    required this.options,
  });

  final String key;
  final String label;
  final String kind;
  final List<PluginChoiceOption> options;

  factory PluginChoiceField.fromMap(Map<String, dynamic> map) {
    return PluginChoiceField(
      key: map['key']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      kind: map['kind']?.toString() ?? '',
      options: asJsonList(
        map['options'],
      ).map((item) => PluginChoiceOption.fromMap(asJsonMap(item))).toList(),
    );
  }

  bool get isChoiceField => kind == 'choice' && key.trim().isNotEmpty;

  PluginChoiceOption? resolveOption({
    String? requestedValue,
    String? fallbackValue,
  }) {
    if (options.isEmpty) {
      return null;
    }

    final targetValue = (requestedValue?.trim().isNotEmpty ?? false)
        ? requestedValue!.trim()
        : (fallbackValue?.trim() ?? '');

    return findOptionByValue(targetValue) ?? options.first;
  }

  PluginChoiceOption? findOptionByValue(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    for (final option in options) {
      final found = option.findByValue(trimmed);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  List<PluginChoiceOption>? findPathByValue(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    for (final option in options) {
      final path = option.findPathByValue(trimmed);
      if (path != null) {
        return path;
      }
    }
    return null;
  }

  List<PluginChoiceLevel> buildVisibleLevels(String? selectedValue) {
    final selectedPath = findPathByValue(selectedValue) ?? const [];
    final levels = <PluginChoiceLevel>[];
    var currentOptions = options;
    var pathIndex = 0;

    while (true) {
      if (!(currentOptions.length == 1 &&
          currentOptions.first.children.isNotEmpty)) {
        levels.add(
          PluginChoiceLevel(pathIndex: pathIndex, options: currentOptions),
        );
      }

      final selected = selectedPath.length > pathIndex
          ? selectedPath[pathIndex]
          : null;
      if (selected == null) {
        break;
      }

      PluginChoiceOption? selectedOption;
      for (final option in currentOptions) {
        if (option.value == selected.value) {
          selectedOption = option;
          break;
        }
      }
      if (selectedOption == null || selectedOption.children.isEmpty) {
        break;
      }

      currentOptions = selectedOption.children;
      pathIndex += 1;
    }

    return levels.where((level) => level.options.isNotEmpty).toList();
  }
}

class PluginChoiceOption {
  const PluginChoiceOption({
    required this.label,
    required this.value,
    required this.result,
    required this.children,
  });

  final String label;
  final String value;
  final Map<String, dynamic> result;
  final List<PluginChoiceOption> children;

  factory PluginChoiceOption.fromMap(Map<String, dynamic> map) {
    return PluginChoiceOption(
      label: map['label']?.toString() ?? map['value']?.toString() ?? '',
      value: map['value']?.toString() ?? '',
      result: asJsonMap(map['result']),
      children: asJsonList(
        map['children'],
      ).map((item) => PluginChoiceOption.fromMap(asJsonMap(item))).toList(),
    );
  }

  PluginChoiceOption? findByValue(String targetValue) {
    if (value == targetValue) {
      return this;
    }

    for (final child in children) {
      final found = child.findByValue(targetValue);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  List<PluginChoiceOption>? findPathByValue(String targetValue) {
    if (value == targetValue) {
      return [this];
    }

    for (final child in children) {
      final path = child.findPathByValue(targetValue);
      if (path != null) {
        return [this, ...path];
      }
    }
    return null;
  }
}

class PluginChoiceLevel {
  const PluginChoiceLevel({required this.pathIndex, required this.options});

  final int pathIndex;
  final List<PluginChoiceOption> options;
}

class PluginResolvedRankingFilter {
  const PluginResolvedRankingFilter({
    required this.selections,
    required this.params,
  });

  final Map<String, String> selections;
  final Map<String, dynamic> params;
}
