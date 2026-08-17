import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cs/application/cs_runtime_context.dart';
import 'package:zephyr/cs/data/cs_api_client.dart';
import 'package:zephyr/cs/data/cs_plugin_bridge_channel.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';

class PluginRegistryCubit extends Cubit<Map<String, PluginRuntimeState>> {
  PluginRegistryCubit({PluginRegistryService? service})
    : _service = service ?? PluginRegistryService.I,
      super((service ?? PluginRegistryService.I).snapshot) {
    _subscription = _service.stream.listen(emit);
    _csEventSubscription = CsRuntimeContext.I.events.listen(_handleCsEvent);
  }

  final PluginRegistryService _service;
  late final StreamSubscription<Map<String, PluginRuntimeState>> _subscription;
  late final StreamSubscription<CsRealtimeEvent> _csEventSubscription;

  void _handleCsEvent(CsRealtimeEvent event) {
    if (event.topic != 'plugins.updated' ||
        !CsRuntimeContext.I.isCsMode ||
        isClosed) {
      return;
    }
    unawaited(
      refreshFromServer().catchError((error) {
        // The next normal refresh can recover from a transient event-channel
        // or HTTP failure; plugin updates must not break the registry Cubit.
        return;
      }),
    );
  }

  Future<void> refresh() {
    if (CsRuntimeContext.I.isCsMode) {
      return refreshFromServer();
    }
    return _service.refreshFromDb();
  }

  Future<void> refreshFromServer() async {
    final client = CsRuntimeContext.I.client;
    if (client == null) {
      throw StateError('CS 服务端连接尚未建立');
    }
    final records = await client.plugins();
    final now = DateTime.now().toUtc();
    for (final record in records) {
      _service.setExternalPluginInfo(record.pluginId, record.info);
    }
    emit({
      for (final record in records)
        record.pluginId: _toRuntimeState(record, now),
    });
  }

  static PluginRuntimeState _toRuntimeState(
    CsPluginRecord record,
    DateTime fallbackTime,
  ) {
    final updatedAt = DateTime.tryParse(record.updatedAt) ?? fallbackTime;
    return PluginRuntimeState(
      uuid: record.pluginId,
      version: record.version,
      originScript: '',
      isEnabled: record.enabled,
      isDeleted: false,
      debug: record.debug,
      debugUrl: record.debugUrl,
      lastLoadSuccess: true,
      lastLoadError: null,
      insertedAt: updatedAt,
      updatedAt: updatedAt,
      deletedAt: null,
    );
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await _csEventSubscription.cancel();
    return super.close();
  }
}
