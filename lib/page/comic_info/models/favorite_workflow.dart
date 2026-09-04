// 云端收藏工作流协议的宿主侧模型。
//
// 插件协议说明见 docs/plugin_favorite_workflow.md。

enum FavoriteWorkflowAction {
  add('add'),
  removeAll('removeAll'),
  removeFromTarget('removeFromTarget'),
  move('move');

  const FavoriteWorkflowAction(this.wireName);

  final String wireName;
}

enum FavoriteWorkflowStatus {
  completed,
  awaitingInput,
  partial,
  failed,
  cancelled;

  static FavoriteWorkflowStatus parse(String? value) {
    return switch (value) {
      'completed' => FavoriteWorkflowStatus.completed,
      'awaitingInput' => FavoriteWorkflowStatus.awaitingInput,
      'partial' => FavoriteWorkflowStatus.partial,
      'cancelled' => FavoriteWorkflowStatus.cancelled,
      _ => FavoriteWorkflowStatus.failed,
    };
  }
}

class FavoriteWorkflowOption {
  const FavoriteWorkflowOption({
    required this.id,
    required this.label,
    this.description,
    this.selected = false,
  });

  factory FavoriteWorkflowOption.fromJson(Map<String, dynamic> json) {
    return FavoriteWorkflowOption(
      id: json['id']?.toString() ?? json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      selected: json['selected'] == true,
    );
  }

  final String id;
  final String label;
  final String? description;
  final bool selected;
}

class FavoriteWorkflowField {
  const FavoriteWorkflowField({
    required this.key,
    required this.type,
    required this.label,
    this.description,
    this.placeholder,
    this.required = false,
    this.defaultValue,
    this.options = const <FavoriteWorkflowOption>[],
  });

  factory FavoriteWorkflowField.fromJson(Map<String, dynamic> json) {
    return FavoriteWorkflowField(
      key: json['key']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      label: json['label']?.toString() ?? json['key']?.toString() ?? '',
      description: json['description']?.toString(),
      placeholder: json['placeholder']?.toString(),
      required: json['required'] == true,
      defaultValue: json['defaultValue'],
      options: _readOptions(json['options']),
    );
  }

  final String key;
  final String type;
  final String label;
  final String? description;
  final String? placeholder;
  final bool required;
  final dynamic defaultValue;
  final List<FavoriteWorkflowOption> options;
}

class FavoriteWorkflowInput {
  const FavoriteWorkflowInput({
    required this.type,
    this.key,
    this.title,
    this.description,
    this.required = true,
    this.selection = 'single',
    this.options = const <FavoriteWorkflowOption>[],
    this.allowCreate = false,
    this.createField,
    this.fields = const <FavoriteWorkflowField>[],
  });

  factory FavoriteWorkflowInput.fromJson(Map<String, dynamic> json) {
    final createFieldJson = _readMap(json['createField']);
    return FavoriteWorkflowInput(
      type: json['type']?.toString() ?? 'select',
      key: json['key']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      required: json['required'] != false,
      selection: json['selection']?.toString() == 'multiple'
          ? 'multiple'
          : 'single',
      options: _readOptions(json['options']),
      allowCreate: json['allowCreate'] == true,
      createField: createFieldJson == null
          ? null
          : FavoriteWorkflowField.fromJson(createFieldJson),
      fields: _readMaps(
        json['fields'],
      ).map(FavoriteWorkflowField.fromJson).toList(growable: false),
    );
  }

  final String type;
  final String? key;
  final String? title;
  final String? description;
  final bool required;
  final String selection;
  final List<FavoriteWorkflowOption> options;
  final bool allowCreate;
  final FavoriteWorkflowField? createField;
  final List<FavoriteWorkflowField> fields;

  bool get isMultiple => selection == 'multiple';
}

class FavoriteWorkflowResult {
  const FavoriteWorkflowResult({
    required this.status,
    this.favorited,
    this.committed = false,
    this.message,
    this.errorCode,
    this.continuationToken,
    this.input,
  });

  factory FavoriteWorkflowResult.fromJson(Map<String, dynamic> json) {
    // 允许插件返回协议根对象，也兼容统一插件历史上常见的 data 包装。
    final data = _readMap(json['data']);
    final payload = data != null && data['status'] != null ? data : json;
    final inputJson = _readMap(payload['input']);

    return FavoriteWorkflowResult(
      status: FavoriteWorkflowStatus.parse(payload['status']?.toString()),
      favorited: payload['favorited'] is bool
          ? payload['favorited'] as bool
          : null,
      committed: payload['committed'] == true,
      message: payload['message']?.toString(),
      errorCode: payload['errorCode']?.toString(),
      continuationToken: payload['continuationToken']?.toString(),
      input: inputJson == null
          ? null
          : FavoriteWorkflowInput.fromJson(inputJson),
    );
  }

  final FavoriteWorkflowStatus status;
  final bool? favorited;
  final bool committed;
  final String? message;
  final String? errorCode;
  final String? continuationToken;
  final FavoriteWorkflowInput? input;
}

class FavoriteWorkflowExecutionResult {
  const FavoriteWorkflowExecutionResult({
    required this.status,
    this.favorited,
    this.committed = false,
    this.message,
  });

  final FavoriteWorkflowStatus status;
  final bool? favorited;
  final bool committed;
  final String? message;

  bool get isCompleted => status == FavoriteWorkflowStatus.completed;
}

class FavoriteWorkflowUnsupportedException implements Exception {
  const FavoriteWorkflowUnsupportedException();
}

class FavoriteWorkflowIncompleteException implements Exception {
  const FavoriteWorkflowIncompleteException(this.result);

  final FavoriteWorkflowExecutionResult result;
}

List<FavoriteWorkflowOption> _readOptions(dynamic value) {
  return _readMaps(value)
      .map(FavoriteWorkflowOption.fromJson)
      .where((option) => option.id.isNotEmpty && option.label.isNotEmpty)
      .toList(growable: false);
}

List<Map<String, dynamic>> _readMaps(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }

  return value
      .map(_readMap)
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}

Map<String, dynamic>? _readMap(dynamic value) {
  if (value is! Map) {
    return null;
  }

  return value.map((key, value) => MapEntry(key.toString(), value));
}
