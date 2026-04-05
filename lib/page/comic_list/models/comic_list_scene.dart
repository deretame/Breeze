import 'package:zephyr/util/json/json_value.dart';

class ComicListRequestConfig {
  const ComicListRequestConfig({
    required this.fnPath,
    this.core = const <String, dynamic>{},
    this.extern = const <String, dynamic>{},
  });

  final String fnPath;
  final Map<String, dynamic> core;
  final Map<String, dynamic> extern;

  factory ComicListRequestConfig.fromMap(Map<String, dynamic> map) {
    final nestedRequest = asJsonMap(map['request']);
    final fnPath = _resolveFnPath(map, nestedRequest);
    return ComicListRequestConfig(
      fnPath: fnPath,
      core: asJsonMap(map['core']),
      extern: asJsonMap(map['extern']),
    );
  }
}

String _resolveFnPath(
  Map<String, dynamic> map,
  Map<String, dynamic> nestedRequest,
) {
  final candidates = <dynamic>[
    map['fnPath'],
    map['fn_path'],
    map['fn'],
    map['function'],
    nestedRequest['fnPath'],
    nestedRequest['fn_path'],
    nestedRequest['fn'],
    nestedRequest['function'],
  ];
  for (final item in candidates) {
    final value = item?.toString().trim() ?? '';
    if (value.isNotEmpty) {
      return value;
    }
  }
  return '';
}

enum ComicListBodyType { pluginPagedComicList, pluginPagedCreatorList }

class ComicListBodyConfig {
  const ComicListBodyConfig({
    required this.type,
    this.request,
    this.params = const <String, dynamic>{},
  });

  final ComicListBodyType type;
  final ComicListRequestConfig? request;
  final Map<String, dynamic> params;

  factory ComicListBodyConfig.fromMap(Map<String, dynamic> map) {
    final type = switch (map['type']?.toString()) {
      'pluginPagedCreatorList' => ComicListBodyType.pluginPagedCreatorList,
      _ => ComicListBodyType.pluginPagedComicList,
    };
    return ComicListBodyConfig(
      type: type,
      request: map['request'] == null
          ? null
          : ComicListRequestConfig.fromMap(asJsonMap(map['request'])),
      params: asJsonMap(map['params']),
    );
  }
}

class ComicListScene {
  const ComicListScene({
    required this.title,
    required this.from,
    required this.body,
    this.filter,
  });

  final String title;
  final String from;
  final ComicListBodyConfig body;
  final ComicListRequestConfig? filter;

  factory ComicListScene.fromMap(Map<String, dynamic> map) {
    final source = map['source']?.toString().trim() ?? '';
    final bodyMap = asJsonMap(map['body']);
    final listMap = asJsonMap(map['list']);

    return ComicListScene(
      title: map['title']?.toString() ?? '',
      from: source.trim(),
      body: bodyMap.isNotEmpty
          ? ComicListBodyConfig.fromMap(bodyMap)
          : ComicListBodyConfig(
              type: ComicListBodyType.pluginPagedComicList,
              request: ComicListRequestConfig.fromMap(listMap),
            ),
      filter: map['filter'] == null
          ? null
          : ComicListRequestConfig.fromMap(asJsonMap(map['filter'])),
    );
  }
}
