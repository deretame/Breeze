import 'package:flutter/foundation.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/plugin_store/models/cloud_plugin_item.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/plugin/utils/plugin_cloud_download_utils.dart';
import 'package:zephyr/plugin/utils/plugin_update_channel_utils.dart';

const _blockedPluginUuid = kDebugMode
    ? ''
    : '00000000-0000-0000-0000-00000000e001';

class PluginInstallService {
  PluginInstallService._();
  static final PluginInstallService I = PluginInstallService._();

  /// Downloads and installs a plugin from the cloud store.
  ///
  /// Returns a message like '安装成功' or '更新成功' on success, and throws
  /// on failure. The caller is responsible for showing UI feedback.
  Future<String> installFromCloud(
    CloudPluginItem item, {
    String? expectedUuid,
  }) async {
    final pluginUuid = item.manifest.uuid.trim();
    if (pluginUuid == _blockedPluginUuid) {
      throw StateError('请更换插件id');
    }
    if (expectedUuid != null &&
        expectedUuid.trim().isNotEmpty &&
        pluginUuid != expectedUuid.trim()) {
      throw StateError(
        '插件 id 不一致，期望=${expectedUuid.trim()}, 实际=$pluginUuid',
      );
    }
    final updateUrl = item.manifest.updateUrl.trim();
    final npmName = item.manifest.npmName.trim();
    if (updateUrl.isEmpty && npmName.isEmpty) {
      throw StateError('该插件未提供 updateUrl 或 npmName，无法下载');
    }

    final script = await downloadFromJsdelivrOrGitHub(
      npmName: npmName,
      cloudVersion: item.manifest.version.trim(),
      updateUrl: updateUrl,
    );
    return savePluginByScript(
      script,
      sourceLabel: '云端组件: ${item.repo}',
      allowReplaceExisting: true,
      expectedUuid: expectedUuid,
    );
  }

  /// Installs a plugin from local bytes (e.g. picked file).
  Future<String> installFromLocalBytes(
    List<int> bytes, {
    required String fileName,
    String? expectedUuid,
    bool allowReplaceExisting = false,
  }) async {
    final script = await decodePluginScriptFromBytes(
      bytes: bytes,
      shouldUseBrotli: fileName.toLowerCase().endsWith('.br'),
    );
    return savePluginByScript(
      script,
      sourceLabel: '本地文件: $fileName',
      allowReplaceExisting: allowReplaceExisting,
      expectedUuid: expectedUuid,
    );
  }

  /// Installs a plugin from an arbitrary network URL.
  Future<String> installFromNetworkUrl(
    String rawUrl, {
    String? expectedUuid,
    bool allowReplaceExisting = false,
  }) async {
    final resolvedUrl = rawUrl.trim();
    if (resolvedUrl.isEmpty) {
      throw StateError('URL 不能为空');
    }

    final response = await downloadPluginAssetWithFallback(resolvedUrl);
    final script = await decodeDownloadedPluginScript(
      response: response,
      resolvedUrl: resolvedUrl,
    );
    return savePluginByScript(
      script,
      sourceLabel: '网络地址: $resolvedUrl',
      allowReplaceExisting: allowReplaceExisting,
      expectedUuid: expectedUuid,
    );
  }

  /// Parses [script], extracts uuid/version, upserts the plugin and enables it.
  ///
  /// When [allowReplaceExisting] is false and the plugin already exists and is
  /// not deleted, a [StateError] is thrown.
  ///
  /// When [expectedUuid] is set, the script's uuid must match or install fails.
  Future<String> savePluginByScript(
    String script, {
    required String sourceLabel,
    bool allowReplaceExisting = false,
    String? expectedUuid,
  }) async {
    final normalizedScript = script.trim();
    if (normalizedScript.isEmpty) {
      throw StateError('插件脚本内容为空，无法安装（$sourceLabel）');
    }

    final info = await callGetInfoByGlobalQjs(normalizedScript);
    final resolvedUuid = readUuidFromInfo(info);
    if (resolvedUuid.isEmpty) {
      throw StateError('getInfo 返回缺少 uuid');
    }
    if (resolvedUuid == _blockedPluginUuid) {
      throw StateError('请更换插件id');
    }
    final expected = expectedUuid?.trim() ?? '';
    if (expected.isNotEmpty && resolvedUuid != expected) {
      throw StateError('插件 id 不一致，期望=$expected, 实际=$resolvedUuid');
    }
    final version = readVersionFromInfo(info);
    final getInfoJson = encodeGetInfoJson(info);

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
      getInfoJson: getInfoJson,
    );

    await PluginRegistryService.I.upsert(infoToSave);
    await PluginRegistryService.I.setEnabled(resolvedUuid, true);

    // 安装/更新后再次刷新 getInfo（内存 + 持久化）。
    try {
      final runtimeName = PluginRegistryService.I.resolveRuntimeName(
        resolvedUuid,
      );
      await PluginRegistryService.I.fetchPluginInfo(
        uuid: resolvedUuid,
        runtimeName: runtimeName,
      );
    } catch (e, st) {
      logger.w('安装后刷新 getInfo 失败: $resolvedUuid', error: e, stackTrace: st);
    }

    return existing == null ? '安装成功' : '更新成功';
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
