import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/plugin_store/models/cloud_plugin_item.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/util/direct_dio.dart';
import 'package:zephyr/util/github_proxy.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/widgets/toast.dart';

const _cloudPluginListUrl =
    'https://raw.githubusercontent.com/deretame/Breeze-plugin-list/main/plugins_data.json';

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
      final payload = await _fetchCloudPluginListPayload(_cloudPluginListUrl);
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
    final updateUrl = item.manifest.updateUrl.trim();
    if (updateUrl.isEmpty) {
      _reportInstallFailure('该插件未提供 updateUrl，无法下载');
      return;
    }

    _beginInstall(
      '正在下载并安装 ${item.manifest.name.trim().isEmpty ? item.repo : item.manifest.name.trim()}...',
    );

    try {
      final release = await fetchReleaseData(updateUrl);
      final asset = _pickPreferredPluginAsset(asJsonList(release['assets']));
      if (asset == null) {
        throw StateError('未找到可安装资源（仅支持 .cjs.br 或 .cjs）');
      }
      final assetName = asset['name']?.toString().trim() ?? '';
      final downloadUrl =
          asset['browser_download_url']?.toString().trim() ?? '';
      if (downloadUrl.isEmpty) {
        throw StateError('release 资产缺少 browser_download_url');
      }

      final response = await _downloadPluginAssetWithFallback(downloadUrl);
      final script = await _decodeDownloadedPluginScript(
        response: response,
        resolvedUrl: downloadUrl,
      );
      await _savePluginByScript(
        script,
        sourceLabel:
            '云端组件: ${item.repo}${assetName.isNotEmpty ? '/$assetName' : ''}',
        allowReplaceExisting: true,
      );
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
      final script = await _decodePluginScriptFromBytes(
        bytes: bytes,
        shouldUseBrotli: fileName.toLowerCase().endsWith('.br'),
      );
      await _savePluginByScript(script, sourceLabel: '本地文件: $fileName');
    } catch (e) {
      _reportInstallFailure('读取本地插件失败: $e');
    }
  }

  Future<void> installFromNetworkUrl(String rawUrl) async {
    if (state.installing) {
      return;
    }
    final resolvedUrl = rawUrl.trim();
    if (resolvedUrl.isEmpty) {
      _reportInstallFailure('URL 不能为空');
      return;
    }

    _beginInstall('正在下载网络插件...');

    try {
      final response = await directDio.get<List<int>>(
        resolvedUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final script = await _decodeDownloadedPluginScript(
        response: response,
        resolvedUrl: resolvedUrl,
      );
      await _savePluginByScript(script, sourceLabel: '网络地址: $resolvedUrl');
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

  Future<String> _fetchCloudPluginListPayload(String sourceUrl) async {
    final requestUrls = _buildCloudRequestCandidates(sourceUrl);
    final client = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    Object? lastError;
    for (final requestUrl in requestUrls) {
      try {
        final response = await client.get<String>(
          requestUrl,
          options: Options(
            responseType: ResponseType.plain,
            headers: {'Accept': 'application/json, text/plain, */*'},
          ),
        );
        final body = response.data?.trim() ?? '';
        if ((response.statusCode ?? 0) == 200 && body.isNotEmpty) {
          return body;
        }
      } catch (e, stackTrace) {
        lastError = e;
        logger.w('云端插件列表通道失败: $requestUrl', error: e, stackTrace: stackTrace);
      }
    }

    throw StateError('所有云端插件列表通道都不可用: $lastError');
  }

  List<String> _buildCloudRequestCandidates(String sourceUrl) {
    final uri = Uri.tryParse(sourceUrl);
    final result = <String>[];
    if (uri != null) {
      final isGithubHost =
          uri.host == 'raw.githubusercontent.com' ||
          uri.host == 'github.com' ||
          uri.host == 'www.github.com';
      if (isGithubHost) {
        result.add('https://gh-proxy.org/$sourceUrl');
      }
    }
    result.add(sourceUrl);
    return result.toSet().toList();
  }

  Map<String, dynamic>? _pickPreferredPluginAsset(List<dynamic> rawAssets) {
    final assets = rawAssets
        .map((item) => asJsonMap(item))
        .where(
          (item) =>
              (item['browser_download_url']?.toString().trim().isNotEmpty ??
                  false) &&
              (item['name']?.toString().trim().isNotEmpty ?? false),
        )
        .toList();
    if (assets.isEmpty) {
      return null;
    }

    Map<String, dynamic>? findByExt(String ext) {
      for (final asset in assets) {
        final name = asset['name']?.toString().toLowerCase().trim() ?? '';
        if (name.endsWith(ext)) {
          return asset;
        }
      }
      return null;
    }

    return findByExt('.cjs.br') ?? findByExt('.cjs');
  }

  Future<Response<List<int>>> _downloadPluginAssetWithFallback(
    String sourceUrl,
  ) async {
    final requestUrls = _buildCloudRequestCandidates(sourceUrl);
    final client = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 30),
        followRedirects: true,
      ),
    );

    Object? lastError;
    for (final requestUrl in requestUrls) {
      try {
        final response = await client.get<List<int>>(
          requestUrl,
          options: Options(
            responseType: ResponseType.bytes,
            headers: {'Accept': '*/*'},
          ),
        );
        final body = response.data ?? const <int>[];
        if (body.isNotEmpty) {
          return response;
        }
        lastError = StateError('空响应: $requestUrl');
      } catch (e, stackTrace) {
        lastError = e;
        logger.w('插件资源下载通道失败: $requestUrl', error: e, stackTrace: stackTrace);
      }
    }

    throw StateError('插件资源下载失败: $lastError');
  }

  Future<String> _decodeDownloadedPluginScript({
    required Response<List<int>> response,
    required String resolvedUrl,
  }) async {
    final body = response.data ?? const <int>[];
    if (body.isEmpty) {
      return '';
    }

    final lowerUrl = resolvedUrl.toLowerCase();
    final contentEncoding = (response.headers.value('content-encoding') ?? '')
        .toLowerCase();
    final shouldUseBrotli =
        lowerUrl.endsWith('.br') || contentEncoding.contains('br');
    return _decodePluginScriptFromBytes(
      bytes: body,
      shouldUseBrotli: shouldUseBrotli,
    );
  }

  Future<String> _decodePluginScriptFromBytes({
    required List<int> bytes,
    required bool shouldUseBrotli,
  }) async {
    if (bytes.isEmpty) {
      return '';
    }
    final decodedBytes = shouldUseBrotli
        ? await decompressExtreme(data: bytes)
        : bytes;
    return utf8.decode(decodedBytes, allowMalformed: true);
  }

  Future<void> _savePluginByScript(
    String script, {
    required String sourceLabel,
    bool allowReplaceExisting = false,
  }) async {
    final normalizedScript = script.trim();
    if (normalizedScript.isEmpty) {
      _reportInstallFailure('插件脚本内容为空，无法安装（$sourceLabel）');
      return;
    }

    try {
      final info = await _callGetInfoByGlobalQjs(normalizedScript);
      final resolvedUuid = _readUuidFromInfo(info);
      if (resolvedUuid.isEmpty) {
        throw StateError('getInfo 返回缺少 uuid');
      }
      final version = _readVersionFromInfo(info);

      final existing = PluginRegistryService.I.getByUuid(resolvedUuid);
      if (!allowReplaceExisting) {
        _validateUuidNotDuplicated(resolvedUuid);
      }

      final now = DateTime.now().toUtc();
      final existingInfo = _findExistingPluginInfoByUuid(resolvedUuid);
      final infoToSave = PluginInfo(
        id: existingInfo?.id ?? 0,
        uuid: resolvedUuid,
        version: version,
        originScript: normalizedScript,
        insertedAt: existingInfo?.insertedAt ?? existing?.insertedAt ?? now,
        updatedAt: now,
        isEnabled: true,
        isDeleted: false,
        deletedAt: null,
        lastLoadSuccess: false,
        lastLoadError: null,
        debug: existing?.debug ?? false,
        debugUrl: existing?.debugUrl,
      );

      await PluginRegistryService.I.upsert(infoToSave);
      await PluginRegistryService.I.setEnabled(resolvedUuid, true);

      final action = existing == null ? '安装成功' : '更新成功';
      _reportInstallSuccess(
        '$action: uuid=$resolvedUuid, version=$version（$sourceLabel）',
      );
    } catch (e) {
      _reportInstallFailure('安装失败（$sourceLabel）: $e');
    }
  }

  Future<Map<String, dynamic>> _callGetInfoByGlobalQjs(String bundleJs) async {
    await PluginRegistryService.I.initializeGlobalRuntime();
    final raw = await qjsCallOnce(
      runtimeName: 'global',
      bundleJs: bundleJs,
      fnPath: 'getInfo',
      argsJson: '{}',
    );
    return requireJsonMap(jsonDecode(raw), message: 'getInfo 返回格式错误');
  }

  String _readUuidFromInfo(Map<String, dynamic> info) {
    final uuid = info['uuid']?.toString().trim() ?? '';
    if (uuid.isNotEmpty) {
      return uuid;
    }
    final dataUuid = asJsonMap(info['data'])['uuid']?.toString().trim() ?? '';
    if (dataUuid.isNotEmpty) {
      return dataUuid;
    }
    return '';
  }

  String _readVersionFromInfo(Map<String, dynamic> info) {
    final version = info['version']?.toString().trim() ?? '';
    if (version.isNotEmpty) {
      return version;
    }
    final dataVersion =
        asJsonMap(info['data'])['version']?.toString().trim() ?? '';
    if (dataVersion.isNotEmpty) {
      return dataVersion;
    }
    return '0.0.0';
  }

  void _validateUuidNotDuplicated(String uuid) {
    final existing = PluginRegistryService.I.getByUuid(uuid);
    if (existing != null && !existing.isDeleted) {
      throw StateError('插件已存在，禁止重复安装: uuid=$uuid');
    }
  }

  PluginInfo? _findExistingPluginInfoByUuid(String uuid) {
    return objectbox.pluginInfoBox
        .query(PluginInfo_.uuid.equals(uuid))
        .build()
        .findFirst();
  }
}
