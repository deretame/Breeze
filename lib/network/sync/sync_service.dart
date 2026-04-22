import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';

import 'comic_sync_core.dart';
import 's3_sync_service.dart';
import 'webdav_sync_service.dart';

const String _settingsSyncSchemaVersion = 'v2';
const String _settingsBlockMetaPrefsKey = 'sync.settings.block.meta.v3';

const String _appearanceBlockName = 'appearance';
const String _libraryBlockName = 'library';
const String _readerBlockName = 'reader';
const String _pluginsBlockName = 'plugins';

const List<String> _syncableSettingsBlockNames = <String>[
  _appearanceBlockName,
  _libraryBlockName,
  _readerBlockName,
];

bool isSyncServiceConfigured(GlobalSettingState state) {
  switch (state.syncSetting.syncServiceType) {
    case SyncServiceType.none:
      return false;
    case SyncServiceType.webdav:
      return WebDavSyncService.isConfigured(state);
    case SyncServiceType.s3:
      return S3SyncService.isConfigured(state);
  }
}

ComicSyncRemoteAdapter? createSyncAdapter(GlobalSettingState state) {
  if (!isSyncServiceConfigured(state)) {
    return null;
  }

  switch (state.syncSetting.syncServiceType) {
    case SyncServiceType.none:
      return null;
    case SyncServiceType.webdav:
      return WebDavSyncService(state);
    case SyncServiceType.s3:
      return S3SyncService(state);
  }
}

Future<void> autoSync(
  GlobalSettingState state, {
  GlobalSettingCubit? globalSettingCubit,
}) async {
  final adapter = createSyncAdapter(state);
  if (adapter == null) {
    return;
  }

  await runComicSync(adapter);

  if (!state.syncSetting.syncSettings) {
    logger.d('设置同步未启用，跳过设置同步');
    return;
  }

  await _syncSettings(
    adapter,
    globalSettingCubit: globalSettingCubit,
    currentGlobalSetting: state,
  );
}

Future<void> _syncSettings(
  ComicSyncRemoteAdapter adapter, {
  required GlobalSettingState currentGlobalSetting,
  GlobalSettingCubit? globalSettingCubit,
}) async {
  final localGlobal = globalSettingCubit?.state ?? currentGlobalSetting;
  final localSnapshot = await _buildLocalSettingsSnapshot(localGlobal);
  final localPayload = _buildSettingsPayload(localGlobal, localSnapshot);
  final localBytes = await ComicSyncCore.encodeEncryptedPayload(
    utf8.encode(jsonEncode(localPayload)),
  );
  final localMd5 = ComicSyncCore.calculateMd5(localBytes);

  final allRemote = await adapter.listRemoteDataFiles();
  final legacyFiles = allRemote
      .where(ComicSyncCore.isLegacyRemotePath)
      .toList();
  if (legacyFiles.isNotEmpty) {
    await adapter.deleteRemoteFiles(legacyFiles);
  }
  final syncRootFiles = allRemote.where(ComicSyncCore.isSyncRootPath).toList();

  final remoteMd5 = await _downloadRemoteText(
    adapter,
    _remoteSettingsMd5Path,
    returnEmptyIfMissing: true,
  );

  logger.d(
    '[sync][settings] precheck localTime=${localSnapshot.syncTime} '
    'localMd5=$localMd5 remoteMd5=$remoteMd5 remoteFiles=${syncRootFiles.length}',
  );

  if (remoteMd5.isNotEmpty && remoteMd5 == localMd5) {
    logger.d('[sync][settings] decision=skip reason=md5_equal');
    await _updateLocalSettingsSyncTime(
      localGlobal,
      syncTime: localSnapshot.syncTime,
      globalSettingCubit: globalSettingCubit,
    );
    return;
  }

  final remoteData = await _selectLatestRemoteSettingsData(
    adapter,
    syncRootFiles,
    remoteMd5,
  );

  if (remoteMd5.isEmpty || remoteData == null) {
    logger.d('[sync][settings] decision=upload reason=remote_missing');
    await _uploadSettingsPayload(
      adapter,
      payloadBytes: localBytes,
      payloadMd5: localMd5,
      syncTime: localSnapshot.syncTime,
    );
    await _updateLocalSettingsSyncTime(
      localGlobal,
      syncTime: localSnapshot.syncTime,
      globalSettingCubit: globalSettingCubit,
    );
    await _cleanupRemoteSettingsFiles(adapter);
    return;
  }

  final remoteSnapshot = await _decodeSettingsPayload(
    remoteData.bytes,
    fallbackSyncTime: remoteData.timestamp,
  );
  final mergeResult = await _mergeSettingsSnapshots(
    localGlobal,
    localSnapshot,
    remoteSnapshot,
  );

  logger.d(
    '[sync][settings] compare localTime=${localSnapshot.syncTime} '
    'remoteTime=${remoteSnapshot.syncTime} mergedTime=${mergeResult.syncTime} '
    'localMd5=$localMd5 remoteMd5=$remoteMd5',
  );

  if (mergeResult.shouldApplyLocalState) {
    logger.d('[sync][settings] decision=apply_remote_blocks');
    await _applyMergedGlobalState(
      mergeResult.mergedState,
      globalSettingCubit: globalSettingCubit,
    );
  } else {
    await _updateLocalSettingsSyncTime(
      localGlobal,
      syncTime: mergeResult.syncTime,
      globalSettingCubit: globalSettingCubit,
    );
  }

  if (mergeResult.shouldApplyPluginData) {
    await _applyPluginBlockData(mergeResult.pluginBlockData);
  }

  await _persistLocalSettingsBlockMeta(mergeResult.localBlockMeta);

  final mergedPayload = _buildSettingsPayload(
    mergeResult.mergedState,
    mergeResult.mergedSnapshot,
  );
  final mergedBytes = await ComicSyncCore.encodeEncryptedPayload(
    utf8.encode(jsonEncode(mergedPayload)),
  );
  final mergedMd5 = ComicSyncCore.calculateMd5(mergedBytes);

  if (mergedMd5 != remoteMd5) {
    logger.d('[sync][settings] decision=upload reason=merged_snapshot_changed');
    await _uploadSettingsPayload(
      adapter,
      payloadBytes: mergedBytes,
      payloadMd5: mergedMd5,
      syncTime: mergeResult.syncTime,
    );
  } else {
    logger.d(
      '[sync][settings] decision=skip_upload reason=merged_snapshot_equals_remote',
    );
  }

  await _cleanupRemoteSettingsFiles(adapter);
}

Map<String, dynamic> _buildSettingsPayload(
  GlobalSettingState globalSetting,
  _SettingsSnapshot snapshot,
) {
  final sanitizedGlobal = globalSetting.copyWith(
    syncSetting: globalSetting.syncSetting.copyWith(settingsSyncTime: 0),
  );

  final pluginBlock = snapshot.blocks[_pluginsBlockName];
  final pluginConfigs = pluginBlock == null
      ? <Map<String, dynamic>>[]
      : _toJsonMapList(pluginBlock.data['pluginConfigs']);
  final pluginInfos = pluginBlock == null
      ? <Map<String, dynamic>>[]
      : _toJsonMapList(pluginBlock.data['pluginInfos']);

  return {
    'version': syncDataVersion,
    'schemaVersion': _settingsSyncSchemaVersion,
    'syncTime': snapshot.syncTime,
    'globalSetting': sanitizedGlobal.toJson(),
    'pluginConfigs': pluginConfigs,
    'pluginInfos': pluginInfos,
    'blocks': {
      for (final entry in snapshot.blocks.entries)
        entry.key: entry.value.toJson(),
    },
  };
}

Future<_SettingsSnapshot> _buildLocalSettingsSnapshot(
  GlobalSettingState globalSetting,
) async {
  final existingMeta = await _loadLocalSettingsBlockMeta();
  final nextMeta = Map<String, _LocalSettingsBlockMeta>.from(existingMeta);
  final blockData = _extractSyncableSettingsBlocks(globalSetting);
  final blockPayloads = <String, _SettingsBlockPayload>{};
  final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
  final baseTimestamp = _normalizeTimestamp(
    globalSetting.syncSetting.settingsSyncTime,
    fallback: nowMs,
  );

  for (final entry in blockData.entries) {
    final blockName = entry.key;
    final data = entry.value;
    final hash = _calculateStructuredMd5(data);
    final previous = existingMeta[blockName];
    final updatedAt = previous == null
        ? baseTimestamp
        : previous.hash == hash
        ? _normalizeTimestamp(previous.updatedAt, fallback: baseTimestamp)
        : nowMs;
    final payload = _SettingsBlockPayload(
      name: blockName,
      updatedAt: updatedAt,
      data: data,
    );
    blockPayloads[blockName] = payload;
    nextMeta[blockName] = _LocalSettingsBlockMeta.fromBlock(payload);
  }

  if (globalSetting.syncSetting.syncPlugins) {
    final pluginData = _buildPluginBlockData();
    final hash = _calculateStructuredMd5(pluginData);
    final previous = existingMeta[_pluginsBlockName];
    final pluginBaseTimestamp = _derivePluginBlockTimestamp(
      pluginData,
      fallback: baseTimestamp,
    );
    final updatedAt = previous == null
        ? pluginBaseTimestamp
        : previous.hash == hash
        ? _normalizeTimestamp(previous.updatedAt, fallback: pluginBaseTimestamp)
        : nowMs;
    final pluginBlock = _SettingsBlockPayload(
      name: _pluginsBlockName,
      updatedAt: updatedAt,
      data: pluginData,
    );
    blockPayloads[_pluginsBlockName] = pluginBlock;
    nextMeta[_pluginsBlockName] = _LocalSettingsBlockMeta.fromBlock(
      pluginBlock,
    );
    logger.d(
      '[sync][plugins] local_snapshot '
      'count=${_toJsonMapList(pluginData['pluginInfos']).length} '
      'hash=$hash baseTs=$pluginBaseTimestamp finalTs=$updatedAt '
      'prevTs=${previous?.updatedAt ?? 0}',
    );
  }

  await _persistLocalSettingsBlockMeta(nextMeta);
  return _SettingsSnapshot(blocks: blockPayloads);
}

Future<_SettingsSnapshot> _decodeSettingsPayload(
  List<int> payloadBytes, {
  required int fallbackSyncTime,
}) async {
  final raw = await ComicSyncCore.decodeEncryptedPayload(payloadBytes);
  final payloadRaw = jsonDecode(utf8.decode(raw));
  return _snapshotFromPayload(
    _toJsonMap(payloadRaw),
    fallbackSyncTime: fallbackSyncTime,
  );
}

_SettingsSnapshot _snapshotFromPayload(
  Map<String, dynamic> payload, {
  required int fallbackSyncTime,
}) {
  final blocksJson = _toJsonMap(payload['blocks']);
  final remoteSyncTime = _extractSyncTimeFromPayload(
    payload,
    fallbackFromFileName: fallbackSyncTime,
  );
  final blocks = <String, _SettingsBlockPayload>{};

  for (final entry in blocksJson.entries) {
    final blockJson = _toJsonMap(entry.value);
    final data = _toJsonMap(blockJson['data']);
    if (data.isEmpty) {
      continue;
    }
    blocks[entry.key] = _SettingsBlockPayload(
      name: entry.key,
      updatedAt: _normalizeTimestamp(
        int.tryParse(blockJson['updatedAt']?.toString() ?? ''),
        fallback: remoteSyncTime,
      ),
      data: data,
    );
  }

  if (blocks.isEmpty) {
    final globalSettingJson = _toJsonMap(payload['globalSetting']);
    if (globalSettingJson.isNotEmpty) {
      final remoteGlobal = GlobalSettingState.fromJson(globalSettingJson);
      final legacyBlocks = _extractSyncableSettingsBlocks(remoteGlobal);
      for (final entry in legacyBlocks.entries) {
        blocks[entry.key] = _SettingsBlockPayload(
          name: entry.key,
          updatedAt: remoteSyncTime,
          data: entry.value,
        );
      }
    }
  }

  if (!blocks.containsKey(_pluginsBlockName)) {
    final pluginConfigs = _toJsonMapList(payload['pluginConfigs']);
    final pluginInfos = _toJsonMapList(payload['pluginInfos']);
    if (pluginConfigs.isNotEmpty || pluginInfos.isNotEmpty) {
      blocks[_pluginsBlockName] = _SettingsBlockPayload(
        name: _pluginsBlockName,
        updatedAt: remoteSyncTime,
        data: {'pluginConfigs': pluginConfigs, 'pluginInfos': pluginInfos},
      );
    }
  }

  return _SettingsSnapshot(blocks: blocks);
}

Future<_SettingsMergeResult> _mergeSettingsSnapshots(
  GlobalSettingState localGlobal,
  _SettingsSnapshot localSnapshot,
  _SettingsSnapshot remoteSnapshot,
) async {
  final mergedBlocks = <String, _SettingsBlockPayload>{};
  final localBlockMeta = await _loadLocalSettingsBlockMeta();
  final nextMeta = Map<String, _LocalSettingsBlockMeta>.from(localBlockMeta);
  var shouldApplyLocalState = false;

  for (final blockName in _syncableSettingsBlockNames) {
    final localBlock = localSnapshot.blocks[blockName];
    if (localBlock == null) {
      continue;
    }
    final remoteBlock = remoteSnapshot.blocks[blockName];
    final mergedBlock = _pickPreferredBlock(localBlock, remoteBlock)!;
    mergedBlocks[blockName] = mergedBlock;
    nextMeta[blockName] = _LocalSettingsBlockMeta.fromBlock(mergedBlock);
    if (!_sameBlock(localBlock, mergedBlock)) {
      shouldApplyLocalState = true;
    }
  }

  Map<String, dynamic> pluginBlockData = const <String, dynamic>{};
  var shouldApplyPluginData = false;

  final localPluginBlock = localSnapshot.blocks[_pluginsBlockName];
  final remotePluginBlock = remoteSnapshot.blocks[_pluginsBlockName];

  if (localGlobal.syncSetting.syncPlugins) {
    final mergedPluginBlock = _mergePluginBlocks(
      localPluginBlock,
      remotePluginBlock,
    );
    final decision = mergedPluginBlock == null
        ? 'none'
        : (localPluginBlock != null &&
              mergedPluginBlock.contentMd5 == localPluginBlock.contentMd5)
        ? 'local_or_merged_local'
        : (remotePluginBlock != null &&
              mergedPluginBlock.contentMd5 == remotePluginBlock.contentMd5)
        ? 'remote_or_merged_remote'
        : 'merged_union';
    logger.d(
      '[sync][plugins] merge '
      'localCount=${_pluginBlockCount(localPluginBlock)} '
      'localTs=${localPluginBlock?.updatedAt ?? 0} '
      'localHash=${localPluginBlock?.contentMd5 ?? ''} '
      'remoteCount=${_pluginBlockCount(remotePluginBlock)} '
      'remoteTs=${remotePluginBlock?.updatedAt ?? 0} '
      'remoteHash=${remotePluginBlock?.contentMd5 ?? ''} '
      'decision=$decision',
    );
    if (mergedPluginBlock != null) {
      mergedBlocks[_pluginsBlockName] = mergedPluginBlock;
      nextMeta[_pluginsBlockName] = _LocalSettingsBlockMeta.fromBlock(
        mergedPluginBlock,
      );
      pluginBlockData = mergedPluginBlock.data;
      if (!_sameBlock(localPluginBlock, mergedPluginBlock)) {
        shouldApplyPluginData = true;
      }
    }
  } else if (remotePluginBlock != null) {
    mergedBlocks[_pluginsBlockName] = remotePluginBlock;
    logger.d(
      '[sync][plugins] merge skipped_apply '
      'reason=local_sync_disabled remoteCount=${_pluginBlockCount(remotePluginBlock)} '
      'remoteTs=${remotePluginBlock.updatedAt}',
    );
  }

  final syncTimeBlocks = <String, _SettingsBlockPayload>{
    for (final blockName in _syncableSettingsBlockNames)
      if (mergedBlocks.containsKey(blockName))
        blockName: mergedBlocks[blockName]!,
  };
  if (localGlobal.syncSetting.syncPlugins &&
      mergedBlocks.containsKey(_pluginsBlockName)) {
    syncTimeBlocks[_pluginsBlockName] = mergedBlocks[_pluginsBlockName]!;
  }

  final mergedSyncTime = _computeSnapshotSyncTime(syncTimeBlocks);
  final mergedState = _applySyncableBlocksToState(localGlobal, mergedBlocks)
      .copyWith(
        syncSetting: localGlobal.syncSetting.copyWith(
          settingsSyncTime: mergedSyncTime,
        ),
      );

  return _SettingsMergeResult(
    mergedState: mergedState,
    mergedSnapshot: _SettingsSnapshot(blocks: mergedBlocks),
    syncTime: mergedSyncTime,
    shouldApplyLocalState: shouldApplyLocalState,
    shouldApplyPluginData: shouldApplyPluginData,
    pluginBlockData: pluginBlockData,
    localBlockMeta: nextMeta,
  );
}

Map<String, Map<String, dynamic>> _extractSyncableSettingsBlocks(
  GlobalSettingState state,
) {
  final json = _materializeJsonMap(state.toJson());
  return <String, Map<String, dynamic>>{
    _appearanceBlockName: <String, dynamic>{
      'dynamicColor': json['dynamicColor'],
      'themeMode': json['themeMode'],
      'isAMOLED': json['isAMOLED'],
      'seedColor': json['seedColor'],
      'locale': json['locale'],
      'welcomePageNum': json['welcomePageNum'],
    },
    _libraryBlockName: <String, dynamic>{
      'maskedKeywords': json['maskedKeywords'],
      'comicChoice': json['comicChoice'],
      'disableBika': json['disableBika'],
      'updateAccelerate': json['updateAccelerate'],
      'searchHistory': json['searchHistory'],
    },
    _readerBlockName: _toJsonMap(json['readSetting']),
  };
}

Map<String, dynamic> _buildPluginBlockData() {
  final deletedUuids = objectbox.pluginInfoBox
      .getAll()
      .where((item) => item.isDeleted)
      .map((item) => item.uuid.trim())
      .where((uuid) => uuid.isNotEmpty)
      .toSet();
  final blockedConfigNames = <String>{
    for (final uuid in deletedUuids)
      ..._buildPluginConfigNameCandidatesForSync(uuid),
  };

  final pluginConfigs = objectbox.pluginConfigBox
      .getAll()
      .map((item) {
        final name = item.name.trim();
        if (name.isEmpty || blockedConfigNames.contains(name)) {
          return <String, dynamic>{};
        }
        final json = item.toJson();
        json.remove('id');
        json['name'] = name;
        return json;
      })
      .where((item) => item.isNotEmpty)
      .toList();
  pluginConfigs.sort((a, b) {
    final aName = a['name']?.toString() ?? '';
    final bName = b['name']?.toString() ?? '';
    return aName.compareTo(bName);
  });

  final pluginInfos = objectbox.pluginInfoBox
      .getAll()
      .where((item) => !item.isDeleted)
      .map((item) {
        final json = item.toJson();
        json.remove('id');
        return json;
      })
      .toList();
  pluginInfos.sort((a, b) {
    final aKey = '${a['uuid'] ?? ''}:${a['version'] ?? ''}';
    final bKey = '${b['uuid'] ?? ''}:${b['version'] ?? ''}';
    return aKey.compareTo(bKey);
  });

  return {'pluginConfigs': pluginConfigs, 'pluginInfos': pluginInfos};
}

GlobalSettingState _applySyncableBlocksToState(
  GlobalSettingState localState,
  Map<String, _SettingsBlockPayload> blocks,
) {
  final json = _materializeJsonMap(localState.toJson());

  final appearance = blocks[_appearanceBlockName]?.data;
  if (appearance != null) {
    json.addAll(appearance);
  }

  final library = blocks[_libraryBlockName]?.data;
  if (library != null) {
    json.addAll(library);
  }

  final reader = blocks[_readerBlockName]?.data;
  if (reader != null) {
    json['readSetting'] = reader;
  }

  return GlobalSettingState.fromJson(json);
}

Future<void> _applyMergedGlobalState(
  GlobalSettingState value, {
  required GlobalSettingCubit? globalSettingCubit,
}) async {
  if (globalSettingCubit != null) {
    globalSettingCubit.applySyncedState(value);
    return;
  }

  final user = objectbox.userSettingBox.get(1);
  if (user != null) {
    user.globalSetting = value;
    objectbox.userSettingBox.put(user);
  }
}

Future<void> _applyPluginBlockData(Map<String, dynamic> pluginBlockData) async {
  final previousSnapshot = PluginRegistryService.I.snapshot;
  final pluginConfigJsonList = _toJsonMapList(pluginBlockData['pluginConfigs']);
  final pluginInfoJsonList = _toJsonMapList(pluginBlockData['pluginInfos']);
  logger.d(
    '[sync][plugins] apply_remote '
    'incomingInfos=${pluginInfoJsonList.length} incomingConfigs=${pluginConfigJsonList.length} '
    'previousRegistry=${previousSnapshot.length}',
  );

  final localPluginInfos = objectbox.pluginInfoBox.getAll();
  final localPluginByUuid = <String, PluginInfo>{
    for (final item in localPluginInfos)
      if (item.uuid.trim().isNotEmpty) item.uuid.trim(): item,
  };
  final localDeletedUuids = localPluginByUuid.values
      .where((item) => item.isDeleted)
      .map((item) => item.uuid.trim())
      .where((uuid) => uuid.isNotEmpty)
      .toSet();

  final remotePluginInfos = <PluginInfo>[];
  for (final json in pluginInfoJsonList) {
    try {
      final parsed = PluginInfo.fromJson(json);
      final uuid = parsed.uuid.trim();
      if (uuid.isEmpty || parsed.isDeleted) {
        continue;
      }
      remotePluginInfos.add(
        PluginInfo(
          uuid: uuid,
          version: parsed.version,
          originScript: parsed.originScript,
          insertedAt: parsed.insertedAt.toUtc(),
          updatedAt: parsed.updatedAt.toUtc(),
          isEnabled: parsed.isEnabled,
          isDeleted: false,
          deletedAt: null,
          lastLoadSuccess: parsed.lastLoadSuccess,
          lastLoadError: parsed.lastLoadError,
          debug: parsed.debug,
          debugUrl: parsed.debugUrl,
        ),
      );
    } catch (e) {
      logger.w('[sync][plugins] 忽略无效插件信息: $e');
    }
  }

  final infoUpserts = <PluginInfo>[];
  var skippedDeletedLocal = 0;
  for (final incoming in remotePluginInfos) {
    final uuid = incoming.uuid.trim();
    if (localDeletedUuids.contains(uuid)) {
      skippedDeletedLocal++;
      continue;
    }
    final existing = localPluginByUuid[uuid];
    if (existing != null &&
        !_shouldApplyIncomingPluginInfo(existing, incoming)) {
      continue;
    }
    final upsert = PluginInfo(
      id: existing?.id ?? 0,
      uuid: uuid,
      version: incoming.version,
      originScript: incoming.originScript,
      insertedAt: existing?.insertedAt ?? incoming.insertedAt,
      updatedAt: incoming.updatedAt,
      isEnabled: incoming.isEnabled,
      isDeleted: false,
      deletedAt: null,
      lastLoadSuccess: incoming.lastLoadSuccess,
      lastLoadError: incoming.lastLoadError,
      debug: incoming.debug,
      debugUrl: incoming.debugUrl,
    );
    infoUpserts.add(upsert);
    localPluginByUuid[uuid] = upsert;
  }
  if (infoUpserts.isNotEmpty) {
    objectbox.pluginInfoBox.putMany(infoUpserts);
  }

  final blockedConfigNames = <String>{
    for (final uuid in localDeletedUuids)
      ..._buildPluginConfigNameCandidatesForSync(uuid),
  };
  final blockedConfigIds = <int>[];
  final localConfigByName = <String, PluginConfig>{
    for (final item in objectbox.pluginConfigBox.getAll())
      if (item.name.trim().isNotEmpty &&
          !blockedConfigNames.contains(item.name.trim()))
        item.name.trim(): PluginConfig(
          id: item.id,
          name: item.name.trim(),
          config: item.config,
        ),
  };
  for (final item in objectbox.pluginConfigBox.getAll()) {
    final name = item.name.trim();
    if (name.isNotEmpty && blockedConfigNames.contains(name)) {
      blockedConfigIds.add(item.id);
    }
  }
  if (blockedConfigIds.isNotEmpty) {
    objectbox.pluginConfigBox.removeMany(blockedConfigIds);
  }
  var skippedBlockedConfig = 0;
  for (final json in pluginConfigJsonList) {
    try {
      final parsed = PluginConfig.fromJson(json);
      final name = parsed.name.trim();
      if (name.isEmpty) {
        continue;
      }
      if (blockedConfigNames.contains(name)) {
        skippedBlockedConfig++;
        continue;
      }
      final existing = localConfigByName[name];
      localConfigByName[name] = PluginConfig(
        id: existing?.id ?? 0,
        name: name,
        config: parsed.config,
      );
    } catch (e) {
      logger.w('[sync][plugins] 忽略无效插件配置: $e');
    }
  }
  if (localConfigByName.isNotEmpty) {
    objectbox.pluginConfigBox.putMany(localConfigByName.values.toList());
  }
  logger.d(
    '[sync][plugins] apply_remote_db '
    'upsertInfos=${infoUpserts.length} totalLocalInfos=${localPluginByUuid.length} '
    'savedConfigs=${localConfigByName.length} '
    'skippedDeletedLocal=$skippedDeletedLocal skippedBlockedConfig=$skippedBlockedConfig',
  );

  await PluginRegistryService.I.reconcileAfterExternalSync(
    previousSnapshot: previousSnapshot,
  );
}

Future<Map<String, _LocalSettingsBlockMeta>>
_loadLocalSettingsBlockMeta() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_settingsBlockMetaPrefsKey);
  if (raw == null || raw.trim().isEmpty) {
    return <String, _LocalSettingsBlockMeta>{};
  }

  try {
    final json = _toJsonMap(jsonDecode(raw));
    return json.map(
      (key, value) =>
          MapEntry(key, _LocalSettingsBlockMeta.fromJson(_toJsonMap(value))),
    );
  } catch (e) {
    logger.w('[sync][settings] 本地块元数据读取失败，已忽略: $e');
    return <String, _LocalSettingsBlockMeta>{};
  }
}

Future<void> _persistLocalSettingsBlockMeta(
  Map<String, _LocalSettingsBlockMeta> nextMeta,
) async {
  final prefs = await SharedPreferences.getInstance();
  final payload = {
    for (final entry in nextMeta.entries) entry.key: entry.value.toJson(),
  };
  await prefs.setString(_settingsBlockMetaPrefsKey, jsonEncode(payload));
}

Future<void> _updateLocalSettingsSyncTime(
  GlobalSettingState localGlobal, {
  required int syncTime,
  required GlobalSettingCubit? globalSettingCubit,
}) async {
  final merged = localGlobal.copyWith(
    syncSetting: localGlobal.syncSetting.copyWith(settingsSyncTime: syncTime),
  );
  if (globalSettingCubit != null) {
    globalSettingCubit.applySyncedState(merged);
  } else {
    final user = objectbox.userSettingBox.get(1);
    if (user != null) {
      user.globalSetting = merged;
      objectbox.userSettingBox.put(user);
    }
  }
}

Future<void> _uploadSettingsPayload(
  ComicSyncRemoteAdapter adapter, {
  required List<int> payloadBytes,
  required String payloadMd5,
  required int syncTime,
}) async {
  final fileName = ComicSyncCore.buildSettingsDataFileName(syncTime);
  await adapter.uploadRemoteFile(fileName, payloadBytes);
  await adapter.uploadRemoteFile(
    _remoteSettingsMd5Path,
    utf8.encode(payloadMd5),
    contentType: 'text/plain; charset=utf-8',
  );
  logger.d('[sync][settings] uploaded file=$fileName md5=$payloadMd5');
}

Future<void> _cleanupRemoteSettingsFiles(ComicSyncRemoteAdapter adapter) async {
  final allRemote = await adapter.listRemoteDataFiles();

  final legacyFiles = allRemote
      .where(ComicSyncCore.isLegacyRemotePath)
      .toList();
  if (legacyFiles.isNotEmpty) {
    await adapter.deleteRemoteFiles(legacyFiles);
  }

  final syncRootFiles = allRemote.where(ComicSyncCore.isSyncRootPath).toList();
  final settingsFiles = syncRootFiles.where((path) {
    final fileName = ComicSyncCore.extractFileName(path);
    return ComicSyncCore.isSettingsDataFileName(fileName);
  }).toList();
  final sorted = ComicSyncCore.sortSettingsFilesByTimestampDesc(settingsFiles);

  final keep = <String>{
    '${ComicSyncCore.syncRemoteRootName}/${ComicSyncCore.settingsMd5FileName}',
  };
  for (var i = 0; i < sorted.length; i++) {
    if (i < 3) {
      keep.add(ComicSyncCore.normalizeRemotePathNoLeadingSlash(sorted[i]));
    }
  }

  final stale = settingsFiles.where((path) {
    final normalized = ComicSyncCore.normalizeRemotePathNoLeadingSlash(path);
    return !keep.contains(normalized);
  }).toList();
  if (stale.isNotEmpty) {
    await adapter.deleteRemoteFiles(stale);
  }
}

Future<_RemoteSettingsData?> _selectLatestRemoteSettingsData(
  ComicSyncRemoteAdapter adapter,
  List<String> remotePaths,
  String remoteMd5,
) async {
  final sorted = ComicSyncCore.sortSettingsFilesByTimestampDesc(remotePaths);
  if (sorted.isEmpty || remoteMd5.isEmpty) {
    return null;
  }

  for (final path in sorted) {
    try {
      final bytes = await adapter.downloadRemoteFile(path);
      final md5 = ComicSyncCore.calculateMd5(bytes);
      if (md5 == remoteMd5) {
        return _RemoteSettingsData(
          bytes: bytes,
          timestamp:
              ComicSyncCore.extractSettingsTimestampFromRemotePath(path) ?? 0,
        );
      }
    } catch (e) {
      logger.w('远端设置文件读取失败，尝试更旧版本: $path, error: $e');
    }
  }

  return null;
}

int _extractSyncTimeFromPayload(
  Map<String, dynamic> payload, {
  required int fallbackFromFileName,
}) {
  final syncTime = int.tryParse(payload['syncTime']?.toString() ?? '') ?? 0;
  if (syncTime > 0) {
    return syncTime;
  }
  return fallbackFromFileName;
}

Future<String> _downloadRemoteText(
  ComicSyncRemoteAdapter adapter,
  String remotePath, {
  bool returnEmptyIfMissing = false,
}) async {
  final bytes = await _downloadRemoteBytes(
    adapter,
    remotePath,
    returnEmptyIfMissing: returnEmptyIfMissing,
  );
  if (bytes.isEmpty) {
    return '';
  }
  return utf8.decode(bytes).trim();
}

Future<List<int>> _downloadRemoteBytes(
  ComicSyncRemoteAdapter adapter,
  String remotePath, {
  bool returnEmptyIfMissing = false,
}) async {
  try {
    return await adapter.downloadRemoteFile(remotePath);
  } catch (e) {
    if (returnEmptyIfMissing && _isNotFoundError(e)) {
      return const [];
    }
    rethrow;
  }
}

bool _isNotFoundError(Object error) {
  final message = error.toString();
  final lower = message.toLowerCase();
  return message.contains('404') ||
      message.contains('NoSuchKey') ||
      message.contains('NoSuchObject') ||
      message.contains('NotFound') ||
      lower.contains('does not exist') ||
      lower.contains('specified key') ||
      lower.contains('no such key');
}

Map<String, dynamic> _toJsonMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _toJsonMapList(Object? value) {
  final raw = (value as List? ?? const []);
  return raw
      .map((item) {
        if (item is Map<String, dynamic>) {
          return Map<String, dynamic>.from(item);
        }
        if (item is Map) {
          return item.map((key, val) => MapEntry(key.toString(), val));
        }
        return <String, dynamic>{};
      })
      .where((item) => item.isNotEmpty)
      .toList();
}

Map<String, dynamic> _materializeJsonMap(Map<String, dynamic> value) {
  return _toJsonMap(jsonDecode(jsonEncode(value)));
}

String _calculateStructuredMd5(Map<String, dynamic> data) {
  return ComicSyncCore.calculateMd5(utf8.encode(jsonEncode(data)));
}

int _derivePluginBlockTimestamp(
  Map<String, dynamic> pluginData, {
  required int fallback,
}) {
  final pluginInfos = _toJsonMapList(pluginData['pluginInfos']);
  var latest = 0;

  for (final item in pluginInfos) {
    final updatedAt = DateTime.tryParse(item['updatedAt']?.toString() ?? '');
    final insertedAt = DateTime.tryParse(item['insertedAt']?.toString() ?? '');
    final candidate = [
      updatedAt?.toUtc().millisecondsSinceEpoch ?? 0,
      insertedAt?.toUtc().millisecondsSinceEpoch ?? 0,
    ].fold<int>(0, (current, value) => value > current ? value : current);
    if (candidate > latest) {
      latest = candidate;
    }
  }

  return latest > 0 ? latest : fallback;
}

int _pluginBlockCount(_SettingsBlockPayload? block) {
  if (block == null) {
    return 0;
  }
  return _toJsonMapList(block.data['pluginInfos']).length;
}

_SettingsBlockPayload? _mergePluginBlocks(
  _SettingsBlockPayload? localBlock,
  _SettingsBlockPayload? remoteBlock,
) {
  if (localBlock == null) {
    return remoteBlock;
  }
  if (remoteBlock == null) {
    return localBlock;
  }
  if (_sameBlock(localBlock, remoteBlock)) {
    return localBlock;
  }

  final preferRemoteOnConflict = remoteBlock.updatedAt > localBlock.updatedAt;
  final mergedData = _mergePluginBlockData(
    localBlock.data,
    remoteBlock.data,
    preferRemoteOnConflict: preferRemoteOnConflict,
  );
  final mergedMd5 = _calculateStructuredMd5(mergedData);
  if (mergedMd5 == localBlock.contentMd5) {
    return localBlock;
  }
  if (mergedMd5 == remoteBlock.contentMd5) {
    return remoteBlock;
  }

  return _SettingsBlockPayload(
    name: _pluginsBlockName,
    updatedAt: localBlock.updatedAt >= remoteBlock.updatedAt
        ? localBlock.updatedAt
        : remoteBlock.updatedAt,
    data: mergedData,
  );
}

Map<String, dynamic> _mergePluginBlockData(
  Map<String, dynamic> localData,
  Map<String, dynamic> remoteData, {
  required bool preferRemoteOnConflict,
}) {
  final localInfos = _toJsonMapList(localData['pluginInfos'])
      .where((item) {
        final uuid = item['uuid']?.toString().trim() ?? '';
        return uuid.isNotEmpty && item['isDeleted'] != true;
      })
      .map((item) {
        final next = Map<String, dynamic>.from(item);
        next['uuid'] = item['uuid']?.toString().trim() ?? '';
        return next;
      })
      .toList();
  final remoteInfos = _toJsonMapList(remoteData['pluginInfos'])
      .where((item) {
        final uuid = item['uuid']?.toString().trim() ?? '';
        return uuid.isNotEmpty && item['isDeleted'] != true;
      })
      .map((item) {
        final next = Map<String, dynamic>.from(item);
        next['uuid'] = item['uuid']?.toString().trim() ?? '';
        return next;
      })
      .toList();

  final mergedInfoByUuid = <String, Map<String, dynamic>>{
    for (final item in localInfos) item['uuid'] as String: item,
  };
  for (final remote in remoteInfos) {
    final uuid = remote['uuid'] as String;
    final local = mergedInfoByUuid[uuid];
    if (local == null) {
      mergedInfoByUuid[uuid] = remote;
      continue;
    }
    final remoteUpdatedAt = _pluginInfoUpdatedAtMs(remote);
    final localUpdatedAt = _pluginInfoUpdatedAtMs(local);
    if (remoteUpdatedAt > localUpdatedAt ||
        (preferRemoteOnConflict && remoteUpdatedAt == localUpdatedAt)) {
      mergedInfoByUuid[uuid] = remote;
    }
  }

  final localConfigs = _toJsonMapList(localData['pluginConfigs']);
  final remoteConfigs = _toJsonMapList(remoteData['pluginConfigs']);
  final mergedConfigByName = <String, Map<String, dynamic>>{};

  for (final item in localConfigs) {
    final name = item['name']?.toString().trim() ?? '';
    if (name.isEmpty) {
      continue;
    }
    final next = Map<String, dynamic>.from(item);
    next['name'] = name;
    mergedConfigByName[name] = next;
  }
  for (final item in remoteConfigs) {
    final name = item['name']?.toString().trim() ?? '';
    if (name.isEmpty) {
      continue;
    }
    final next = Map<String, dynamic>.from(item);
    next['name'] = name;
    if (!mergedConfigByName.containsKey(name) || preferRemoteOnConflict) {
      mergedConfigByName[name] = next;
    }
  }

  final mergedInfos = mergedInfoByUuid.values.toList()
    ..sort((a, b) {
      final aKey = '${a['uuid'] ?? ''}:${a['version'] ?? ''}';
      final bKey = '${b['uuid'] ?? ''}:${b['version'] ?? ''}';
      return aKey.compareTo(bKey);
    });
  final mergedConfigs = mergedConfigByName.values.toList()
    ..sort((a, b) {
      final aName = a['name']?.toString() ?? '';
      final bName = b['name']?.toString() ?? '';
      return aName.compareTo(bName);
    });

  return <String, dynamic>{
    'pluginConfigs': mergedConfigs,
    'pluginInfos': mergedInfos,
  };
}

int _pluginInfoUpdatedAtMs(Map<String, dynamic> item) {
  final updatedAt = DateTime.tryParse(item['updatedAt']?.toString() ?? '');
  final insertedAt = DateTime.tryParse(item['insertedAt']?.toString() ?? '');
  final updatedAtMs = updatedAt?.toUtc().millisecondsSinceEpoch ?? 0;
  final insertedAtMs = insertedAt?.toUtc().millisecondsSinceEpoch ?? 0;
  return updatedAtMs > insertedAtMs ? updatedAtMs : insertedAtMs;
}

bool _shouldApplyIncomingPluginInfo(PluginInfo existing, PluginInfo incoming) {
  if (existing.isDeleted) {
    return false;
  }

  final remoteUpdatedAt = incoming.updatedAt.toUtc().millisecondsSinceEpoch;
  final localUpdatedAt = existing.updatedAt.toUtc().millisecondsSinceEpoch;
  if (remoteUpdatedAt > localUpdatedAt) {
    return true;
  }
  if (remoteUpdatedAt < localUpdatedAt) {
    return false;
  }
  return existing.version != incoming.version ||
      existing.originScript != incoming.originScript ||
      existing.isEnabled != incoming.isEnabled ||
      existing.debug != incoming.debug ||
      (existing.debugUrl ?? '') != (incoming.debugUrl ?? '') ||
      existing.lastLoadSuccess != incoming.lastLoadSuccess ||
      (existing.lastLoadError ?? '') != (incoming.lastLoadError ?? '');
}

Set<String> _buildPluginConfigNameCandidatesForSync(String uuid) {
  final candidates = <String>{};
  for (final raw in <String>{uuid.trim()}) {
    for (final normalized in _normalizePluginNameCandidatesForSync(raw)) {
      candidates.add(normalized);
      candidates.add('($normalized)');
      final onceRuntime = 'plugin_info_${normalized.replaceAll('-', '_')}';
      candidates.add(onceRuntime);
      candidates.add('($onceRuntime)');
    }
  }
  return candidates.where((item) => item.trim().isNotEmpty).toSet();
}

Set<String> _normalizePluginNameCandidatesForSync(String raw) {
  final names = <String>{};
  var value = raw.trim();
  if (value.isEmpty) {
    return names;
  }
  names.add(value);

  while (value.length >= 2 && value.startsWith('(') && value.endsWith(')')) {
    value = value.substring(1, value.length - 1).trim();
    if (value.isEmpty) {
      break;
    }
    names.add(value);
  }

  return names;
}

_SettingsBlockPayload? _pickPreferredBlock(
  _SettingsBlockPayload? localBlock,
  _SettingsBlockPayload? remoteBlock,
) {
  if (localBlock == null) {
    return remoteBlock;
  }
  if (remoteBlock == null) {
    return localBlock;
  }

  if (localBlock.updatedAt > remoteBlock.updatedAt) {
    return localBlock;
  }
  if (localBlock.updatedAt < remoteBlock.updatedAt) {
    return remoteBlock;
  }

  if (_sameBlock(localBlock, remoteBlock)) {
    return localBlock;
  }

  return localBlock;
}

bool _sameBlock(_SettingsBlockPayload? a, _SettingsBlockPayload? b) {
  if (a == null || b == null) {
    return a == b;
  }
  return a.contentMd5 == b.contentMd5;
}

int _computeSnapshotSyncTime(Map<String, _SettingsBlockPayload> blocks) {
  var maxSyncTime = 0;
  for (final block in blocks.values) {
    if (block.updatedAt > maxSyncTime) {
      maxSyncTime = block.updatedAt;
    }
  }
  return maxSyncTime;
}

int _normalizeTimestamp(int? timestamp, {required int fallback}) {
  if (timestamp != null && timestamp > 0) {
    return timestamp;
  }
  return fallback;
}

String get _remoteSettingsMd5Path =>
    '${ComicSyncCore.syncRemoteRootName}/${ComicSyncCore.settingsMd5FileName}';

class _SettingsSnapshot {
  const _SettingsSnapshot({required this.blocks});

  final Map<String, _SettingsBlockPayload> blocks;

  int get syncTime => _computeSnapshotSyncTime(blocks);
}

class _SettingsBlockPayload {
  _SettingsBlockPayload({
    required this.name,
    required this.updatedAt,
    required this.data,
  }) : contentMd5 = _calculateStructuredMd5(data);

  final String name;
  final int updatedAt;
  final Map<String, dynamic> data;
  final String contentMd5;

  Map<String, dynamic> toJson() {
    return {'updatedAt': updatedAt, 'data': data};
  }
}

class _LocalSettingsBlockMeta {
  const _LocalSettingsBlockMeta({required this.updatedAt, required this.hash});

  factory _LocalSettingsBlockMeta.fromBlock(_SettingsBlockPayload block) {
    return _LocalSettingsBlockMeta(
      updatedAt: block.updatedAt,
      hash: block.contentMd5,
    );
  }

  factory _LocalSettingsBlockMeta.fromJson(Map<String, dynamic> json) {
    return _LocalSettingsBlockMeta(
      updatedAt: int.tryParse(json['updatedAt']?.toString() ?? '') ?? 0,
      hash: json['hash']?.toString() ?? '',
    );
  }

  final int updatedAt;
  final String hash;

  Map<String, dynamic> toJson() {
    return {'updatedAt': updatedAt, 'hash': hash};
  }
}

class _SettingsMergeResult {
  const _SettingsMergeResult({
    required this.mergedState,
    required this.mergedSnapshot,
    required this.syncTime,
    required this.shouldApplyLocalState,
    required this.shouldApplyPluginData,
    required this.pluginBlockData,
    required this.localBlockMeta,
  });

  final GlobalSettingState mergedState;
  final _SettingsSnapshot mergedSnapshot;
  final int syncTime;
  final bool shouldApplyLocalState;
  final bool shouldApplyPluginData;
  final Map<String, dynamic> pluginBlockData;
  final Map<String, _LocalSettingsBlockMeta> localBlockMeta;
}

class _RemoteSettingsData {
  const _RemoteSettingsData({required this.bytes, required this.timestamp});

  final List<int> bytes;
  final int timestamp;
}
