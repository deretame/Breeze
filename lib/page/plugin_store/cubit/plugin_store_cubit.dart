import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cs/application/cs_runtime_context.dart';
import 'package:zephyr/cs/data/cs_api_client.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
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
  });

  final bool installing;
  final String installMessage;
  final bool cloudLoading;
  final String cloudError;
  final List<CloudPluginItem> cloudPlugins;

  PluginStoreState copyWith({
    bool? installing,
    String? installMessage,
    bool? cloudLoading,
    String? cloudError,
    List<CloudPluginItem>? cloudPlugins,
  }) {
    return PluginStoreState(
      installing: installing ?? this.installing,
      installMessage: installMessage ?? this.installMessage,
      cloudLoading: cloudLoading ?? this.cloudLoading,
      cloudError: cloudError ?? this.cloudError,
      cloudPlugins: cloudPlugins ?? this.cloudPlugins,
    );
  }
}

class PluginStoreCubit extends Cubit<PluginStoreState> {
  PluginStoreCubit({required PluginRegistryCubit registry})
    : _registry = registry,
      super(const PluginStoreState());

  final PluginRegistryCubit _registry;
  int _loadGeneration = 0;

  Future<void> loadCloudPlugins() async {
    if (isClosed) return;
    final requestGeneration = ++_loadGeneration;
    emit(state.copyWith(cloudLoading: true, cloudError: ''));

    try {
      if (CsRuntimeContext.I.isCsMode) {
        final client = CsRuntimeContext.I.client;
        if (client == null) {
          throw StateError('CS 服务端连接尚未建立');
        }
        final cloudItems = (await client.pluginCatalog())
            .map(_toCloudPluginItem)
            .toList();
        if (isClosed || requestGeneration != _loadGeneration) return;
        emit(
          state.copyWith(
            cloudPlugins: cloudItems,
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

      if (isClosed || requestGeneration != _loadGeneration) return;
      emit(
        state.copyWith(
          cloudPlugins: entries,
          cloudLoading: false,
          cloudError: '',
        ),
      );
    } catch (e, stackTrace) {
      if (isClosed || requestGeneration != _loadGeneration) return;
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
        final installed = await client.installCatalogPlugin(item.manifest.uuid);
        await _applyInstalledPlugin(installed);
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
        await _applyInstalledPlugin(installed);
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
        await _applyInstalledPlugin(installed);
        message = '服务端插件安装成功';
      } else {
        message = await PluginInstallService.I.installFromNetworkUrl(rawUrl);
      }
      _reportInstallSuccess(message);
    } catch (e) {
      _reportInstallFailure(t.plugin.networkDownloadFailed(error: e));
    }
  }

  Future<void> _applyInstalledPlugin(CsPluginRecord installed) async {
    // 先使用安装接口返回值更新全局状态，保证当前页面立即变化；详情只
    // 用于补齐名称和 getInfo，详情请求失败不应否定已经成功的安装。
    _registry.applyRemoteRecord(installed);
    final client = CsRuntimeContext.I.client;
    if (client == null) return;
    try {
      final detail = await client.pluginDetail(installed.pluginId);
      _registry.applyRemoteRecord(detail);
    } catch (error, stackTrace) {
      logger.w(
        '安装插件后读取详情失败，保留安装状态: ${installed.pluginId}',
        error: error,
        stackTrace: stackTrace,
      );
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
