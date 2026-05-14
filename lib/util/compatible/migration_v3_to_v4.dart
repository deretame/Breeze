import 'package:zephyr/config/global/color_theme_types.dart';
import 'package:zephyr/main.dart';

Future<void> migrateV3ToV4() async {
  final removed = objectbox.downloadTaskBox.removeAll();
  logger.d('[migration_v3_to_v4] removed DownloadTask rows: $removed');

  final userSetting = objectbox.userSettingBox.get(1);
  if (userSetting == null) {
    throw Exception('Global setting not found');
  }

  final nextGlobalSetting = userSetting.globalSetting.copyWith(
    dynamicColor: false,
    seedColor: colorThemeList[6].color,
  );
  userSetting.globalSetting = nextGlobalSetting;
  objectbox.userSettingBox.put(userSetting);

  logger.d(
    '[migration_v3_to_v4] updated global setting: dynamicColor=false, '
    'seedColor=${colorThemeList[6].label}'
    '(${colorThemeList[6].color.toARGB32()})',
  );
}
