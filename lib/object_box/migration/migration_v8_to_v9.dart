import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';

/// v8 -> v9: 将旧的 SOCKS5 代理开关迁移到通用代理配置 [ProxySettingState]。
///
/// - 旧开关开启且配置了地址：代理类型选择 SOCKS5，并沿用原地址
/// - 旧开关开启但未配置地址：默认使用 HTTP
/// - 旧开关关闭：保持关闭，默认类型 HTTP
Future<void> migrateV8ToV9() async {
  final userSetting = objectbox.userSettingBox.get(1);
  if (userSetting == null) {
    throw Exception('Global setting not found');
  }

  final current = userSetting.globalSetting;
  final hasSocks5 = current.socks5Proxy.trim().isNotEmpty;
  final next = current.copyWith(
    proxySetting: ProxySettingState(
      enabled: current.socks5ProxyEnabled,
      type: hasSocks5 ? ProxyType.socks5 : ProxyType.http,
      address: current.socks5Proxy,
    ),
  );
  userSetting.globalSetting = next;
  objectbox.userSettingBox.put(userSetting);

  logger.d(
    '[migration_v8_to_v9] proxyEnabled=${next.proxySetting.enabled} '
    'proxyType=${next.proxySetting.type.name} '
    '(proxy=${next.proxySetting.address.isEmpty ? "empty" : "set"})',
  );
}
