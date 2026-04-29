import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/main.dart';

import 'migration_v1_to_v2.dart';
import 'migration_v2_to_v3.dart';

const _defaultCompatibleVersion = 'v1';
const _latestCompatibleVersion = 'v3';

Future<void> ensureCompatibleMigration(BuildContext context) async {
  try {
    var version = await getCompatibleVersion();
    var migrated = false;

    if (version == 'v1' || version == 'v2') {
      if (context.mounted) {
        context.read<StringSelectCubit>().setDate("数据迁移中，请耐心等待");
      }
    }

    if (version == 'v1') {
      await migrateV1ToV2();
      await migrateLegacyDownloadFilesToPluginUuidLayout();
      await setCompatibleVersion('v2');
      version = 'v2';
      migrated = true;
    }

    if (version == 'v2') {
      await migrateV2ToV3();
      await setCompatibleVersion(_latestCompatibleVersion);
      migrated = true;
    }

    if (migrated && context.mounted) {
      context.read<GlobalSettingCubit>().updateALl(
        objectbox.userSettingBox.get(1)!.globalSetting,
      );
    }
  } catch (e, stackTrace) {
    logger.e('Compatible migration failed', error: e, stackTrace: stackTrace);
  }
}

Future<String> getCompatibleVersion() async {
  final setting = objectbox.userSettingBox.get(1);
  if (setting == null) {
    throw Exception('Global setting not found');
  }

  final globalSetting = setting.globalSetting;

  if (globalSetting.compatibleVersion == "") {
    return _defaultCompatibleVersion;
  }

  return globalSetting.compatibleVersion;
}

Future<void> setCompatibleVersion(String version) async {
  final setting = objectbox.userSettingBox.get(1);
  if (setting == null) {
    throw Exception('Global setting not found');
  }

  var globalSetting = setting.globalSetting;
  globalSetting = globalSetting.copyWith(compatibleVersion: version);
  setting.globalSetting = globalSetting;

  objectbox.userSettingBox.put(setting);
}
