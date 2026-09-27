import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/config/global/global_setting.dart';

void main() {
  group('EInkSettingState', () {
    test('默认关闭时不启用任何墨水屏行为', () {
      const eink = EInkSettingState();

      expect(eink.enabled, isFalse);
      expect(eink.shouldRemoveRouteTransition, isFalse);
      expect(eink.shouldRemoveScrollBounce, isFalse);
      expect(eink.shouldRemoveLoadingSpinner, isFalse);
      expect(eink.canFullRefresh, isFalse);
    });

    test('开启后各开关独立生效', () {
      const eink = EInkSettingState(enabled: true, noRouteTransition: false);

      expect(eink.shouldRemoveRouteTransition, isFalse);
      expect(eink.shouldRemoveScrollBounce, isTrue);
      expect(eink.canFullRefresh, isTrue);
    });

    test('刷新方式为“不刷新”时不允许整屏刷新', () {
      const eink = EInkSettingState(
        enabled: true,
        refreshMode: EinkRefreshMode.none,
      );

      expect(eink.canFullRefresh, isFalse);
    });

    test('autoRefreshTurns 把越界值夹回可用范围', () {
      expect(
        const EInkSettingState(autoRefreshEveryNTurns: -5).autoRefreshTurns,
        0,
      );
      expect(
        const EInkSettingState(autoRefreshEveryNTurns: 9999).autoRefreshTurns,
        50,
      );
      expect(
        const EInkSettingState(autoRefreshEveryNTurns: 7).autoRefreshTurns,
        7,
      );
    });
  });

  group('GlobalSettingState 的墨水屏持久化契约', () {
    test('旧版 JSON 缺少 eInkSetting 时回落默认值', () {
      final restored = GlobalSettingState.fromJson(
        const GlobalSettingState().toJson()..remove('eInkSetting'),
      );

      expect(restored.eInkSetting, const EInkSettingState());
    });

    test('墨水屏设置经 JSON 往返后保持不变', () {
      const state = GlobalSettingState(
        eInkSetting: EInkSettingState(
          enabled: true,
          detectionHandled: true,
          refreshMode: EinkRefreshMode.whiteFlash,
          autoRefreshEveryNTurns: 12,
          showRefreshButton: false,
        ),
      );

      expect(
        GlobalSettingState.fromJson(state.toJson()).eInkSetting,
        state.eInkSetting,
      );
    });
  });
}
