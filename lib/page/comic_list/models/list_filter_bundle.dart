import 'package:zephyr/page/comic_list/scene_filter/plugin_list_filter_schema.dart';

class ListFilterBundle {
  const ListFilterBundle({
    required this.scheme,
    required this.defaultSelections,
  });

  final PluginListFilterSchema scheme;
  final Map<String, String> defaultSelections;
}
