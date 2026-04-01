import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/plugin/plugin_constants.dart';

Future<UnifiedPluginEnvelope> getPluginSettingsBundle(String pluginId) async {
  final source = sanitizePluginId(sanitizePluginId(pluginId));
  final response = await callUnifiedComicPlugin(
    from: source,
    fnPath: 'getSettingsBundle',
    core: const <String, dynamic>{},
    extern: const <String, dynamic>{},
  );
  return UnifiedPluginEnvelope.fromMap(response);
}
