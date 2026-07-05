import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/plugin_store/models/cloud_plugin_item.dart';
import 'package:zephyr/plugin/plugin_install_service.dart';
import 'package:zephyr/plugin/utils/plugin_cloud_download_utils.dart';
import 'package:zephyr/util/json/json_value.dart';
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
  PluginStoreCubit() : super(const PluginStoreState());

  Future<void> loadCloudPlugins() async {
    emit(state.copyWith(cloudLoading: true, cloudError: ''));

    try {
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
      emit(state.copyWith(cloudLoading: false, cloudError: '云端组件列表加载失败: $e'));
    }
  }

  Future<void> installFromCloud(CloudPluginItem item) async {
    if (state.installing) {
      return;
    }
    final name = item.manifest.name.trim().isEmpty
        ? item.repo
        : item.manifest.name.trim();
    _beginInstall('正在下载并安装 $name...');

    try {
      final message = await PluginInstallService.I.installFromCloud(item);
      _reportInstallSuccess(message);
    } catch (e) {
      _reportInstallFailure('云端下载失败: $e');
    }
  }

  Future<void> installFromLocalBytes(
    List<int> bytes, {
    required String fileName,
  }) async {
    if (state.installing) {
      return;
    }
    _beginInstall('正在安装本地插件...');

    try {
      final message = await PluginInstallService.I.installFromLocalBytes(
        bytes,
        fileName: fileName,
      );
      _reportInstallSuccess(message);
    } catch (e) {
      _reportInstallFailure('读取本地插件失败: $e');
    }
  }

  Future<void> installFromNetworkUrl(String rawUrl) async {
    if (state.installing) {
      return;
    }
    _beginInstall('正在下载网络插件...');

    try {
      final message = await PluginInstallService.I.installFromNetworkUrl(
        rawUrl,
      );
      _reportInstallSuccess(message);
    } catch (e) {
      _reportInstallFailure('网络下载插件失败: $e');
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
}
