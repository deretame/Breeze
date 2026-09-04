import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/network/http/plugin/unified_plugin_envelope.dart';

Future<UnifiedPluginEnvelope> getPluginSettingsBundle(String pluginId) async {
  final source = pluginId.trim();
  final response = await callUnifiedComicPlugin(
    from: source,
    fnPath: 'getSettingsBundle',
    core: const <String, dynamic>{},
    extern: const <String, dynamic>{},
  );
  return UnifiedPluginEnvelope.fromMap(response);
}
