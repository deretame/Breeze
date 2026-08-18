import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/cs/data/cs_api_client.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';

void main() {
  const record = CsPluginRecord(
    pluginId: 'plugin-1',
    name: 'Plugin 1',
    info: {'name': 'Plugin 1'},
    version: '1.2.3',
    bundleHash: 'hash-1',
    enabled: true,
    debug: false,
    debugUrl: null,
    updatedAt: '2026-08-17T00:00:00Z',
  );

  test(
    'CS plugin install result updates the global registry immediately',
    () async {
      final registry = PluginRegistryCubit();
      addTearDown(registry.close);

      registry.applyRemoteRecord(record);

      expect(registry.state['plugin-1']?.version, '1.2.3');
      expect(registry.state['plugin-1']?.isActive, isTrue);
    },
  );

  test('CS plugin uninstall removes the plugin from the global registry', () {
    final registry = PluginRegistryCubit();
    addTearDown(registry.close);

    registry.applyRemoteRecord(record);
    registry.removeRemoteRecord(record.pluginId);

    expect(registry.state.containsKey(record.pluginId), isFalse);
  });
}
