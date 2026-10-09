import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';

/// v11 -> v12：单本阅读偏好从 `readMode` 整列迁到 `overridesJson` 稀疏 patch。
///
/// 与全局共用一套 JSON 结构：patch 只存显式改过的键（键名与
/// `ReadSettingState.toJson()` 对齐），没 key = 没设置 = 跟随全局。
/// 只迁移 `deleted=false` 的有效行；墓碑行的 patch 为空，读出来本来
/// 就是跟随全局，跳过不写（墓碑本身靠 LWW 同步，不靠迁移）。
Future<void> migrateV11ToV12() async {
  final box = objectbox.comicReadPreferenceBox;
  final all = box.getAll();
  var migrated = 0;
  for (final item in all) {
    if (item.deleted) continue;
    // ignore: deprecated_member_use_from_same_package
    final mode = item.readMode.clamp(0, 2);
    item.applyChanges(
      const ReadSettingState(),
      const ReadSettingState().copyWith(readMode: mode),
      includeKeys: const {'readMode'},
    );
    box.put(item);
    migrated++;
  }
  logger.i('[migration_v11_to_v12] 已迁移 $migrated 条单本阅读偏好到 overridesJson');
}
