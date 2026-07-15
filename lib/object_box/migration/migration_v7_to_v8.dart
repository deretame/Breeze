import 'package:zephyr/main.dart';

/// v7 -> v8: 为 SOCKS5 代理增加开关字段 [socks5ProxyEnabled]。
///
/// - 已配置代理地址：保持开启（并保留原地址）
/// - 未配置代理地址：设为关闭
Future<void> migrateV7ToV8() async {
  final userSetting = objectbox.userSettingBox.get(1);
  if (userSetting == null) {
    throw Exception('Global setting not found');
  }

  final current = userSetting.globalSetting;
  final hasProxy = current.socks5Proxy.trim().isNotEmpty;
  final next = current.copyWith(socks5ProxyEnabled: hasProxy);
  userSetting.globalSetting = next;
  objectbox.userSettingBox.put(userSetting);

  logger.d(
    '[migration_v7_to_v8] socks5ProxyEnabled=$hasProxy '
    '(proxy=${hasProxy ? current.socks5Proxy : "empty"})',
  );
}
