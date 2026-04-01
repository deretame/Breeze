import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/object_box.dart';

import 'migration_v1_to_v2.dart';

const _defaultCompatibleVersion = 'v1';
const _latestCompatibleVersion = 'v2';

Future<void> ensureCompatibleMigration(ObjectBox objectbox) async {
  try {
    final version = await getCompatibleVersion();
    if (version == 'v1') {
      await migrateV1ToV2(objectbox);
      await setCompatibleVersion(_latestCompatibleVersion);
    }
  } catch (e) {
    logger.e('Compatible migration failed: $e');
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
