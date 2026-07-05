import 'dart:async';
import 'dart:convert';

import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/plugin/models/cloud_plugin_manifest_internal.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/plugin/utils/plugin_cloud_download_utils.dart';
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

  Future<void> silentUpdateFromCloud() async {
    final localPlugins = PluginRegistryService.I.snapshot.values
        .where((item) => !item.isDeleted)
        .toList();
    if (localPlugins.isEmpty) {
      return;
    }

    final cloudItems = await _fetchCloudPluginCatalog();
    if (cloudItems.isEmpty) {
      return;
    }

    final cloudByUuid = <String, CloudPluginCatalogItem>{
      for (final item in cloudItems)
        if (item.manifest.uuid.trim().isNotEmpty)
          item.manifest.uuid.trim(): item,
    };

    var updatedCount = 0;
    for (final local in localPlugins) {
      final cloud = cloudByUuid[local.uuid];
      if (cloud == null) {
        continue;
      }
      final updateUrl = cloud.manifest.updateUrl.trim();
      final npmName = cloud.manifest.npmName.trim();
      if (updateUrl.isEmpty && npmName.isEmpty) {
        continue;
      }
      if (!_shouldUpdateVersion(
        localVersion: local.version,
        cloudVersion: cloud.manifest.version,
      )) {
        continue;
      }

      try {
        final payload = await _downloadCloudPluginUpdateWithRetry(
          repo: cloud.repo,
          updateUrl: updateUrl,
          expectedUuid: local.uuid,
          cloudVersion: cloud.manifest.version,
          npmName: npmName,
        );
        await _applyPluginUpdate(local: local, payload: payload);
        updatedCount++;
      } catch (e, st) {
        logger.w('插件静默更新失败: ${local.uuid}', error: e, stackTrace: st);
      }
    }

    if (updatedCount > 0) {
      logger.i('静默更新完成，共更新 $updatedCount 个插件');
    }
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
    required String cloudVersion,
  }) {
    return compareVersion(cloudVersion, localVersion) > 0;
  }

  Future<_PluginUpdatePayload> _downloadCloudPluginUpdateWithRetry({
    required String repo,
    required String updateUrl,
    required String expectedUuid,
    required String cloudVersion,
    required String npmName,
  }) async {
    const maxAttempts = 3;
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await _downloadCloudPluginUpdate(
          repo: repo,
          updateUrl: updateUrl,
          expectedUuid: expectedUuid,
          cloudVersion: cloudVersion,
          npmName: npmName,
        );
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
          '插件静默更新网络错误，准备重试($attempt/$maxAttempts): $expectedUuid',
          error: e,
          stackTrace: st,
        );
        await Future.delayed(Duration(milliseconds: 400 * attempt));
      }
    }

    throw StateError('插件静默更新网络错误，重试次数用尽: $expectedUuid, error: $lastError');
  }

  Future<_PluginUpdatePayload> _downloadCloudPluginUpdate({
    required String repo,
    required String updateUrl,
    required String expectedUuid,
    required String cloudVersion,
    required String npmName,
  }) async {
    final script = await downloadFromJsdelivrOrGitHub(
      npmName: npmName,
      cloudVersion: cloudVersion,
      updateUrl: updateUrl,
    );

    final info = await callGetInfoByGlobalQjs(script);
    final resolvedUuid = readUuidFromInfo(info);
    if (resolvedUuid != expectedUuid) {
      throw StateError('更新脚本 uuid 不匹配，期望=$expectedUuid, 实际=$resolvedUuid');
    }
    final resolvedVersion = readVersionFromInfo(info);

    return _PluginUpdatePayload(
      uuid: resolvedUuid,
      version: resolvedVersion.isNotEmpty ? resolvedVersion : cloudVersion,
      script: script,
      sourceLabel: '静默更新: $repo',
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

    // 静默更新会清理 info cache，主动回填以避免 UI 暂时回退为 uuid。
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

class _PluginUpdatePayload {
  const _PluginUpdatePayload({
    required this.uuid,
    required this.version,
    required this.script,
    required this.sourceLabel,
  });

  final String uuid;
  final String version;
  final String script;
  final String sourceLabel;
}
