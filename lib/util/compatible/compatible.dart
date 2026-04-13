import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/main.dart';

import 'migration_v1_to_v2.dart';

const _defaultCompatibleVersion = 'v1';
const _latestCompatibleVersion = 'v2';

Future<void> ensureCompatibleMigration(BuildContext context) async {
  try {
    final version = await getCompatibleVersion();
    if (version == 'v1') {
      if (context.mounted) {
        context.read<StringSelectCubit>().setDate("数据迁移中，请耐心等待");
      }
      logger.d('Compatible migration start: v1 -> v2');
      await migrateV1ToV2();
      logger.d(
        'Compatible migration db finished, start download files migration',
      );
      await migrateLegacyDownloadFilesToPluginUuidLayout();
      logger.d('Compatible migration download files finished');
      logger.d('Compatible migration done: version=v2');
      await setCompatibleVersion(_latestCompatibleVersion);
      if (context.mounted) {
        context.read<GlobalSettingCubit>().updateALl(
          objectbox.userSettingBox.get(1)!.globalSetting,
        );
      }
      return;
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
