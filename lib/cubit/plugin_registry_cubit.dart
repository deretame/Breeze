import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';

class PluginRegistryCubit extends Cubit<Map<String, PluginRuntimeState>> {
  PluginRegistryCubit({PluginRegistryService? service})
    : _service = service ?? PluginRegistryService.I,
      super((service ?? PluginRegistryService.I).snapshot) {
    _subscription = _service.stream.listen(emit);
  }

  final PluginRegistryService _service;
  late final StreamSubscription<Map<String, PluginRuntimeState>> _subscription;

  Future<void> refresh() => _service.refreshFromDb();

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
