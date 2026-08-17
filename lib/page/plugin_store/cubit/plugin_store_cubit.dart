import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cs/application/cs_runtime_context.dart';
import 'package:zephyr/cs/data/cs_api_client.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/plugin_store/models/cloud_plugin_item.dart';
import 'package:zephyr/plugin/plugin_install_service.dart';
import 'package:zephyr/plugin/utils/plugin_cloud_download_utils.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/widgets/toast.dart';

class PluginStoreState {
  const PluginStoreState({
    this.installing = false,
    this.installMessage = '',
    this.cloudLoading = false,
    this.cloudError = '',
    this.cloudPlugins = const <CloudPluginItem>[],
    this.serverPlugins = const <String, CsPluginRecord>{},
  });

  final bool installing;
  final String installMessage;
  final bool cloudLoading;
  final String cloudError;
  final List<CloudPluginItem> cloudPlugins;
  final Map<String, CsPluginRecord> serverPlugins;

  PluginStoreState copyWith({
    bool? installing,
    String? installMessage,
    bool? cloudLoading,
    String? cloudError,
    List<CloudPluginItem>? cloudPlugins,
    Map<String, CsPluginRecord>? serverPlugins,
  }) {
    return PluginStoreState(
      installing: installing ?? this.installing,
      installMessage: installMessage ?? this.installMessage,
      cloudLoading: cloudLoading ?? this.cloudLoading,
      cloudError: cloudError ?? this.cloudError,
      cloudPlugins: cloudPlugins ?? this.cloudPlugins,
      serverPlugins: serverPlugins ?? this.serverPlugins,
    );
  }
}

class PluginStoreCubit extends Cubit<PluginStoreState> {
  PluginStoreCubit() : super(const PluginStoreState());

  Future<void> loadCloudPlugins() async {
    emit(state.copyWith(cloudLoading: true, cloudError: ''));

    try {
      if (CsRuntimeContext.I.isCsMode) {
        final client = CsRuntimeContext.I.client;
        if (client == null) {
          throw StateError('CS 服务端连接尚未建立');
        }
        final result = await Future.wait([
          client.pluginCatalog(),
          client.plugins(),
        ]);
        final cloudItems = (result[0] as List<CsCloudPluginItem>)
            .map(_toCloudPluginItem)
            .toList();
        final serverPlugins = {
          for (final plugin in result[1] as List<CsPluginRecord>)
            plugin.pluginId: plugin,
        };
        emit(
          state.copyWith(
            cloudPlugins: cloudItems,
            serverPlugins: serverPlugins,
            cloudLoading: false,
            cloudError: '',
          ),
        );
        return;
      }

      final payload = await fetchCloudPluginListWithCdnFallback();
      final decoded = jsonDecode(payload);
      final entries = asJsonList(decoded)
          .map((item) => CloudPluginItem.fromJson(asJsonMap(item)))
          .where((item) => item.manifest.uuid.trim().isNotEmpty)
          .toList();

      emit(
        state.copyWith(
          cloudPlugins: entries,
          cloudLoading: false,
          cloudError: '',
        ),
      );
    } catch (e, stackTrace) {
      logger.w('拉取云端插件列表失败', error: e, stackTrace: stackTrace);
      emit(
        state.copyWith(
          cloudLoading: false,
          cloudError: t.plugin.cloudPluginsLoadFailed(error: e),
        ),
      );
    }
  }

  Future<void> installFromCloud(CloudPluginItem item) async {
    if (state.installing) {
      return;
    }
    final name = item.manifest.name.trim().isEmpty
        ? item.repo
        : item.manifest.name.trim();
    _beginInstall(t.plugin.installingFromCloud(name: name));

    try {
      final String message;
      if (CsRuntimeContext.I.isCsMode) {
        final client = CsRuntimeContext.I.client;
        if (client == null) {
          throw StateError('CS 服务端连接尚未建立');
        }
        await client.installCatalogPlugin(item.manifest.uuid);
        final record = await client.pluginDetail(item.manifest.uuid);
        emit(
          state.copyWith(
            serverPlugins: {...state.serverPlugins, record.pluginId: record},
          ),
        );
        message = '服务端插件安装成功';
      } else {
        message = await PluginInstallService.I.installFromCloud(item);
      }
      _reportInstallSuccess(message);
    } catch (e) {
      _reportInstallFailure(t.plugin.cloudDownloadFailed(error: e));
    }
  }

  Future<void> installFromLocalBytes(
    List<int> bytes, {
    required String fileName,
  }) async {
    if (state.installing) {
      return;
    }
    _beginInstall(t.plugin.installingFromLocal);

    try {
      final String message;
      if (CsRuntimeContext.I.isCsMode) {
        final client = CsRuntimeContext.I.client;
        if (client == null) {
          throw StateError('CS 服务端连接尚未建立');
        }
        final installed = await client.installPluginBundle(
          Uint8List.fromList(bytes),
          fileName: fileName,
        );
        final record = await client.pluginDetail(installed.pluginId);
        emit(
          state.copyWith(
            serverPlugins: {...state.serverPlugins, record.pluginId: record},
          ),
        );
        message = '服务端插件安装成功';
      } else {
        message = await PluginInstallService.I.installFromLocalBytes(
          bytes,
          fileName: fileName,
        );
      }
      _reportInstallSuccess(message);
    } catch (e) {
      _reportInstallFailure(t.plugin.readLocalPluginFailed(error: e));
    }
  }

  Future<void> installFromNetworkUrl(String rawUrl) async {
    if (state.installing) {
      return;
    }
    _beginInstall(t.plugin.installingFromNetwork);

    try {
      final String message;
      if (CsRuntimeContext.I.isCsMode) {
        final client = CsRuntimeContext.I.client;
        if (client == null) {
          throw StateError('CS 服务端连接尚未建立');
        }
        final installed = await client.installPluginFromUrl(rawUrl);
        final record = await client.pluginDetail(installed.pluginId);
        emit(
          state.copyWith(
            serverPlugins: {...state.serverPlugins, record.pluginId: record},
          ),
        );
        message = '服务端插件安装成功';
      } else {
        message = await PluginInstallService.I.installFromNetworkUrl(rawUrl);
      }
      _reportInstallSuccess(message);
    } catch (e) {
      _reportInstallFailure(t.plugin.networkDownloadFailed(error: e));
    }
  }

  void _beginInstall(String message) {
    emit(state.copyWith(installing: true, installMessage: message));
  }

  void _reportInstallFailure(String message) {
    emit(state.copyWith(installing: false, installMessage: ''));
    showErrorToast(message);
  }

  void _reportInstallSuccess(String message) {
    emit(state.copyWith(installing: false, installMessage: ''));
    showSuccessToast(message);
  }

  static CloudPluginItem _toCloudPluginItem(CsCloudPluginItem item) {
    final manifest = item.manifest;
    return CloudPluginItem(
      repo: item.repo,
      manifest: CloudPluginManifest(
        name: manifest.name,
        uuid: manifest.uuid,
        iconUrl: manifest.iconUrl,
        creatorName: manifest.creatorName,
        creatorDescribe: manifest.creatorDescribe,
        describe: manifest.describe,
        version: manifest.version,
        home: manifest.home,
        updateUrl: manifest.updateUrl,
        npmName: manifest.npmName,
      ),
    );
  }
}
