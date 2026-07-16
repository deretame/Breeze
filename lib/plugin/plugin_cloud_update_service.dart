import 'dart:async';
import 'dart:convert';

import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/plugin/models/cloud_plugin_manifest_internal.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/plugin/utils/plugin_cloud_download_utils.dart';
import 'package:zephyr/plugin/utils/plugin_update_channel_utils.dart';
import 'package:zephyr/plugin/utils/plugin_version_utils.dart';
import 'package:zephyr/util/json/json_value.dart';

class PluginCloudUpdateService {
  PluginCloudUpdateService._();
  static final PluginCloudUpdateService I = PluginCloudUpdateService._();

  bool _silentCloudUpdateScheduled = false;
  Timer? _silentCloudUpdateTimer;
  bool _silentCloudUpdateRunning = false;

  void scheduleSilentCloudUpdate({
    Duration delay = const Duration(minutes: 5),
  }) {
    if (_silentCloudUpdateScheduled) {
      return;
    }
    _silentCloudUpdateScheduled = true;
    _silentCloudUpdateTimer?.cancel();
    _silentCloudUpdateTimer = Timer(delay, () {
      unawaited(runSilentCloudUpdateOnce());
    });
  }

  Future<void> runSilentCloudUpdateOnce() async {
    if (_silentCloudUpdateRunning) {
      return;
    }
    _silentCloudUpdateRunning = true;
    try {
      await silentUpdateFromCloud();
    } catch (e, st) {
      logger.w('静默更新插件失败', error: e, stackTrace: st);
    } finally {
      _silentCloudUpdateRunning = false;
    }
  }

  /// 静默自动更新：
  /// - 在云端列表中的插件：只走列表 version / 下载坐标
  /// - 不在列表中的插件：只走自身 npmName / updateUrl
  /// 两条路径互不回退。
  Future<void> silentUpdateFromCloud() async {
    final localPlugins = PluginRegistryService.I.snapshot.values
        .where((item) => !item.isDeleted)
        .toList();
    if (localPlugins.isEmpty) {
      return;
    }

    var cloudByUuid = <String, CloudPluginCatalogItem>{};
    try {
      final cloudItems = await _fetchCloudPluginCatalog();
      cloudByUuid = {
        for (final item in cloudItems)
          if (item.manifest.uuid.trim().isNotEmpty)
            item.manifest.uuid.trim(): item,
      };
    } catch (e, st) {
      logger.w('静默更新拉取云端列表失败，将全部尝试自身更新通道', error: e, stackTrace: st);
    }

    final inList = <PluginRuntimeState>[];
    final outList = <PluginRuntimeState>[];
    for (final local in localPlugins) {
      if (cloudByUuid.containsKey(local.uuid)) {
        inList.add(local);
      } else {
        outList.add(local);
      }
    }

    var updatedCount = 0;

    for (final local in inList) {
      final cloud = cloudByUuid[local.uuid];
      if (cloud == null) {
        continue;
      }
      try {
        final updated = await _tryUpdateFromCloudCatalog(
          local: local,
          cloud: cloud,
        );
        if (updated) {
          updatedCount++;
        }
      } catch (e, st) {
        logger.w('插件静默更新失败(列表): ${local.uuid}', error: e, stackTrace: st);
      }
    }

    if (outList.isNotEmpty) {
      final results = await Future.wait(
        outList.map((local) async {
          try {
            return await _tryUpdateFromSelfChannel(
              local: local,
              sourceLabel: '静默更新(自身通道)',
            );
          } catch (e, st) {
            logger.w('插件静默更新失败(自身通道): ${local.uuid}', error: e, stackTrace: st);
            return false;
          }
        }),
        eagerError: false,
      );
      updatedCount += results.where((ok) => ok).length;
    }

    if (updatedCount > 0) {
      logger.i('静默更新完成，共更新 $updatedCount 个插件');
    }
  }

  /// 插件设置「同步」：固定走 npm / updateUrl 自身通道。
  ///
  /// 返回是否实际下载并应用了新版本。
  Future<bool> syncPluginFromSelfChannel(String uuid) async {
    final local = PluginRegistryService.I.getByUuid(uuid);
    if (local == null || local.isDeleted) {
      throw StateError('插件不存在或已删除');
    }

    return _tryUpdateFromSelfChannel(
      local: local,
      sourceLabel: '手动同步',
      forceWhenSameVersion: false,
    );
  }

  Future<bool> _tryUpdateFromCloudCatalog({
    required PluginRuntimeState local,
    required CloudPluginCatalogItem cloud,
  }) async {
    final updateUrl = cloud.manifest.updateUrl.trim();
    final npmName = cloud.manifest.npmName.trim();
    if (updateUrl.isEmpty && npmName.isEmpty) {
      return false;
    }
    if (!_shouldUpdateVersion(
      localVersion: local.version,
      remoteVersion: cloud.manifest.version,
    )) {
      return false;
    }

    final payload = await _downloadCloudPluginUpdateWithRetry(
      repo: cloud.repo,
      updateUrl: updateUrl,
      expectedUuid: local.uuid,
      cloudVersion: cloud.manifest.version,
      npmName: npmName,
      sourceLabel: '静默更新: ${cloud.repo}',
    );
    await _applyPluginUpdate(local: local, payload: payload);
    return true;
  }

  Future<bool> _tryUpdateFromSelfChannel({
    required PluginRuntimeState local,
    required String sourceLabel,
    bool forceWhenSameVersion = false,
  }) async {
    final channel = await _resolveSelfUpdateChannel(local.uuid);
    final npmName = channel.npmName;
    final updateUrl = channel.updateUrl;
    if (npmName.isEmpty && updateUrl.isEmpty) {
      logger.d('插件无更新通道，跳过: ${local.uuid}');
      return false;
    }

    final remoteVersion = await fetchSelfChannelLatestVersion(
      npmName: npmName,
      updateUrl: updateUrl,
    );
    if (!forceWhenSameVersion &&
        !_shouldUpdateVersion(
          localVersion: local.version,
          remoteVersion: remoteVersion,
        )) {
      return false;
    }

    final payload = await _downloadSelfChannelUpdateWithRetry(
      expectedUuid: local.uuid,
      npmName: npmName,
      updateUrl: updateUrl,
      remoteVersion: remoteVersion,
      sourceLabel: sourceLabel,
    );
    await _applyPluginUpdate(local: local, payload: payload);
    return true;
  }

  Future<_SelfUpdateChannel> _resolveSelfUpdateChannel(String uuid) async {
    final found = objectbox.pluginInfoBox
        .query(PluginInfo_.uuid.equals(uuid))
        .build()
        .findFirst();
    Map<String, dynamic>? info = parseGetInfoJson(found?.getInfoJson ?? '');

    if (info == null) {
      final local = PluginRegistryService.I.getByUuid(uuid);
      final script = local?.originScript.trim() ?? '';
      if (script.isNotEmpty) {
        try {
          info = await callGetInfoByGlobalQjs(script);
          await PluginRegistryService.I.persistGetInfoJson(
            uuid,
            encodeGetInfoJson(info),
          );
        } catch (e, st) {
          logger.w('刷新 getInfo 缓存失败: $uuid', error: e, stackTrace: st);
        }
      }
    }

    if (info == null) {
      return const _SelfUpdateChannel(npmName: '', updateUrl: '');
    }
    return _SelfUpdateChannel(
      npmName: readNpmNameFromInfo(info),
      updateUrl: readUpdateUrlFromInfo(info),
    );
  }

  Future<List<CloudPluginCatalogItem>> _fetchCloudPluginCatalog() async {
    final payload = await fetchCloudPluginListWithCdnFallback();
    final decoded = const JsonCodec().decode(payload);
    return asJsonList(decoded)
        .map((item) => CloudPluginCatalogItem.fromJson(asJsonMap(item)))
        .where((item) => item.manifest.uuid.trim().isNotEmpty)
        .toList();
  }

  bool _shouldUpdateVersion({
    required String localVersion,
    required String remoteVersion,
  }) {
    return compareVersion(remoteVersion, localVersion) > 0;
  }

  Future<_PluginUpdatePayload> _downloadCloudPluginUpdateWithRetry({
    required String repo,
    required String updateUrl,
    required String expectedUuid,
    required String cloudVersion,
    required String npmName,
    required String sourceLabel,
  }) async {
    return _downloadWithRetry(
      expectedUuid: expectedUuid,
      download: () => _downloadAndVerify(
        expectedUuid: expectedUuid,
        npmName: npmName,
        remoteVersion: cloudVersion,
        updateUrl: updateUrl,
        sourceLabel: sourceLabel,
      ),
    );
  }

  Future<_PluginUpdatePayload> _downloadSelfChannelUpdateWithRetry({
    required String expectedUuid,
    required String npmName,
    required String updateUrl,
    required String remoteVersion,
    required String sourceLabel,
  }) async {
    return _downloadWithRetry(
      expectedUuid: expectedUuid,
      download: () => _downloadAndVerify(
        expectedUuid: expectedUuid,
        npmName: npmName,
        remoteVersion: remoteVersion,
        updateUrl: updateUrl,
        sourceLabel: sourceLabel,
      ),
    );
  }

  Future<_PluginUpdatePayload> _downloadWithRetry({
    required String expectedUuid,
    required Future<_PluginUpdatePayload> Function() download,
  }) async {
    const maxAttempts = 3;
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await download();
      } catch (e, st) {
        lastError = e;
        final isNetworkError = isNetworkRetryableError(e);
        if (!isNetworkError) {
          rethrow;
        }
        if (attempt >= maxAttempts) {
          break;
        }
        logger.w(
          '插件更新网络错误，准备重试($attempt/$maxAttempts): $expectedUuid',
          error: e,
          stackTrace: st,
        );
        await Future.delayed(Duration(milliseconds: 400 * attempt));
      }
    }

    throw StateError('插件更新网络错误，重试次数用尽: $expectedUuid, error: $lastError');
  }

  Future<_PluginUpdatePayload> _downloadAndVerify({
    required String expectedUuid,
    required String npmName,
    required String remoteVersion,
    required String updateUrl,
    required String sourceLabel,
  }) async {
    final script = await downloadPluginFromSelfChannel(
      npmName: npmName,
      updateUrl: updateUrl,
      remoteVersion: remoteVersion,
    );

    final info = await callGetInfoByGlobalQjs(script);
    final resolvedUuid = readUuidFromInfo(info);
    if (resolvedUuid != expectedUuid) {
      throw StateError('更新脚本 uuid 不匹配，期望=$expectedUuid, 实际=$resolvedUuid');
    }
    final resolvedVersion = readVersionFromInfo(info);

    return _PluginUpdatePayload(
      uuid: resolvedUuid,
      version: resolvedVersion.isNotEmpty ? resolvedVersion : remoteVersion,
      script: script,
      sourceLabel: sourceLabel,
      getInfoJson: encodeGetInfoJson(info),
    );
  }

  Future<void> _applyPluginUpdate({
    required PluginRuntimeState local,
    required _PluginUpdatePayload payload,
  }) async {
    final box = objectbox;

    final found = box.pluginInfoBox
        .query(PluginInfo_.uuid.equals(local.uuid))
        .build()
        .findFirst();
    final now = DateTime.now().toUtc();
    final toSave = PluginInfo(
      id: found?.id ?? 0,
      uuid: payload.uuid,
      version: payload.version,
      originScript: payload.script,
      insertedAt: found?.insertedAt ?? local.insertedAt,
      updatedAt: now,
      isEnabled: found?.isEnabled ?? local.isEnabled,
      isDeleted: false,
      deletedAt: null,
      lastLoadSuccess: false,
      lastLoadError: null,
      debug: found?.debug ?? local.debug,
      debugUrl: found?.debugUrl ?? local.debugUrl,
      getInfoJson: payload.getInfoJson.isNotEmpty
          ? payload.getInfoJson
          : (found?.getInfoJson ?? ''),
    );
    await PluginRegistryService.I.upsert(toSave);

    final runtimeName = PluginRegistryService.I.resolveRuntimeName(
      payload.uuid,
    );
    final latest = PluginRegistryService.I.getByUuid(payload.uuid);
    if (latest != null && latest.isEnabled) {
      await PluginRegistryService.I.ensurePluginRuntimeReady(
        latest,
        runtimeName: runtimeName,
      );
      await PluginRegistryService.I.runPluginInitIfNeeded(
        latest,
        runtimeName: runtimeName,
      );
    }

    // 更新后再次刷新 getInfo 缓存（内存 + 持久化）。
    try {
      await PluginRegistryService.I.fetchPluginInfo(
        uuid: payload.uuid,
        runtimeName: runtimeName,
      );
    } catch (e, st) {
      logger.w('插件更新后回填信息失败: ${payload.uuid}', error: e, stackTrace: st);
    }
  }
}

class _SelfUpdateChannel {
  const _SelfUpdateChannel({required this.npmName, required this.updateUrl});

  final String npmName;
  final String updateUrl;
}

class _PluginUpdatePayload {
  const _PluginUpdatePayload({
    required this.uuid,
    required this.version,
    required this.script,
    required this.sourceLabel,
    required this.getInfoJson,
  });

  final String uuid;
  final String version;
  final String script;
  final String sourceLabel;
  final String getInfoJson;
}
