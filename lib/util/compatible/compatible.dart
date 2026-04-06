import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/object_box.dart';

import 'migration_v1_to_v2.dart';

const _defaultCompatibleVersion = 'v1';
const _latestCompatibleVersion = 'v2';

Future<void> ensureCompatibleMigration(ObjectBox objectbox) async {
  objectbox.dumpAllData();

  try {
    final version = await getCompatibleVersion();
    if (version == 'v1') {
      logger.d('Compatible migration start: v1 -> v2');
      await migrateV1ToV2(objectbox);
      logger.d(
        'Compatible migration db finished, start download files migration',
      );
      await migrateLegacyDownloadFilesToPluginUuidLayout();
      logger.d('Compatible migration download files finished');
      await setCompatibleVersion(_latestCompatibleVersion);
      logger.d('Compatible migration done: version=v2');
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
