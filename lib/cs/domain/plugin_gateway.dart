abstract interface class PluginGateway {
  Future<Map<String, dynamic>> invoke({
    required String pluginId,
    required String function,
    required List<dynamic> args,
  });
}

class ModeAwarePluginGateway implements PluginGateway {
  ModeAwarePluginGateway({
    required this.isCsMode,
    required this.local,
    required this.remote,
  });

  final Future<bool> Function() isCsMode;
  final PluginGateway local;
  final PluginGateway remote;

  @override
  Future<Map<String, dynamic>> invoke({
    required String pluginId,
    required String function,
    required List<dynamic> args,
  }) async {
    final gateway = await isCsMode() ? remote : local;
    return gateway.invoke(pluginId: pluginId, function: function, args: args);
  }
}
