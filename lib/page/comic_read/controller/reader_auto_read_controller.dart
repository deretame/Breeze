import 'dart:async';

import 'package:zephyr/config/global/global_setting.dart';

/// 自动阅读控制器。
///
/// 把计时器、暂停状态、配置缓存从 [State] 中抽出来，减少 UI 层的职责。
class ReaderAutoReadController {
  Timer? _timer;
  bool _isPaused = false;
  bool _lastEnabled = false;
  int _lastIntervalMs = 0;
  int _lastReadMode = -1;

  bool get isPaused => _isPaused;

  /// 根据当前设置同步自动阅读状态。
  ///
  /// [canTick] 返回 true 时才会真正执行 [onTick]。
  void sync({
    required ReadSettingState readSetting,
    required int readMode,
    required bool Function() canTick,
    required void Function() onTick,
  }) {
    final enabled = readSetting.autoScroll;
    final intervalMs =
        (readMode == 0
                ? readSetting.autoScrollColumnIntervalMs
                : readSetting.autoScrollPageIntervalMs)
            .clamp(300, 10000);
    final wasEnabled = _lastEnabled;
    final configChanged =
        _lastEnabled != enabled ||
        _lastIntervalMs != intervalMs ||
        _lastReadMode != readMode;

    _lastEnabled = enabled;
    _lastIntervalMs = intervalMs;
    _lastReadMode = readMode;

    if (!enabled) {
      _timer?.cancel();
      return;
    }

    if (!wasEnabled) {
      _isPaused = false;
    }

    if (_isPaused) {
      _timer?.cancel();
      return;
    }

    if (configChanged || _timer == null || !_timer!.isActive) {
      _startTimer(intervalMs, canTick, onTick);
    }
  }

  /// 切换暂停/继续，不改动用户设置项本身。
  void togglePaused({
    required ReadSettingState readSetting,
    required int readMode,
    required bool Function() canTick,
    required void Function() onTick,
  }) {
    _isPaused = !_isPaused;

    if (_isPaused) {
      _timer?.cancel();
      return;
    }

    final intervalMs =
        (readMode == 0
                ? readSetting.autoScrollColumnIntervalMs
                : readSetting.autoScrollPageIntervalMs)
            .clamp(300, 10000);
    _startTimer(intervalMs, canTick, onTick);
  }

  void _startTimer(
    int intervalMs,
    bool Function() canTick,
    void Function() onTick,
  ) {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (!canTick()) return;
      onTick();
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}
