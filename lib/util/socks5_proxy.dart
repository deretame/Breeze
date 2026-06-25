import 'package:flutter_socks_proxy/socks_proxy.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/src/rust/api/qjs.dart' as qjs;

/// 按 [GlobalSettingState] 即时应用 SOCKS5 代理设置（主 isolate）。
///
/// 开关开启且地址非空时启用代理；否则撤销劫持恢复直连。
/// 启动初始化与设置页运行时切换共用本函数，故切换无需重启。
/// 前台任务 isolate 见 main_task，其 HttpOverrides 为 isolate 局部，不在此处理。
Future<void> applySocks5Proxy(GlobalSettingState state) async {
  if (state.socks5ProxyEnabled && state.socks5Proxy.isNotEmpty) {
    SocksProxy.initProxy(proxy: 'SOCKS5 ${state.socks5Proxy}');
    await qjs.setSocks5Proxy(proxy: state.socks5Proxy);
  } else {
    // null 等价 DIRECT，用于撤销全局 HttpOverrides 劫持（勿传空串）
    SocksProxy.initProxy(proxy: null);
    qjs.disableProxy(); // #[frb(sync)] 同步绑定，返回 void 不可 await
  }
}
