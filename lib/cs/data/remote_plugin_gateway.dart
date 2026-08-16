import 'package:zephyr/cs/data/cs_api_client.dart';
import 'package:zephyr/cs/domain/plugin_gateway.dart';

class RemotePluginGateway implements PluginGateway {
  const RemotePluginGateway(this.client);

  final CsApiClient client;

  @override
  Future<Map<String, dynamic>> invoke({
    required String pluginId,
    required String function,
    required List<dynamic> args,
  }) {
    return client.invokePlugin(
      pluginId: pluginId,
      function: function,
      args: args,
    );
  }
}
