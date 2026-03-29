import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/type/enum.dart';

Future<UnifiedPluginEnvelope> getPluginSettingsBundle(From from) async {
  final response = await callUnifiedComicPlugin(
    from: from,
    fnPath: 'getSettingsBundle',
    core: const <String, dynamic>{},
    extern: const <String, dynamic>{},
  );
  return UnifiedPluginEnvelope.fromMap(response);
}
