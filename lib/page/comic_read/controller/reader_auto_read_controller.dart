import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:zephyr/config/global/global_setting.dart';

/// 自动阅读 tick 回调。
///
/// [deltaMs] 仅在平滑滚动模式下提供，表示距上一帧的真实间隔。
typedef AutoReadTickCallback = void Function({double? deltaMs});

/// 自动阅读控制器。
///
/// 把计时器、暂停状态、配置缓存从 [State] 中抽出来，减少 UI 层的职责。
///
/// - 分段模式：`Timer.periodic` 按用户设定间隔跳转
/// - 平滑模式：与 vsync 对齐的帧回调 + 真实 [deltaMs]，避免 Timer 与屏幕刷新不同步造成的抖动
class ReaderAutoReadController {
  Timer? _timer;
  bool _isPaused = false;
  bool _lastEnabled = false;
  int _lastIntervalMs = 0;
  int _lastReadMode = -1;
  bool _lastSmooth = false;
  bool _smoothRunning = false;
  Duration? _lastFrameTimestamp;
  bool Function()? _canTick;
  AutoReadTickCallback? _onTick;

  /// 帧间隔上限；超长帧（切后台/卡顿恢复）按此上限减速滑过，
  /// 既不瞬跳一大段，也不会完全停一拍。
  static const double _maxSmoothDeltaMs = 48;

  bool get isPaused => _isPaused;

  /// 根据当前设置同步自动阅读状态。
  ///
  /// [canTick] 返回 true 时才会真正执行 [onTick]。
  void sync({
    required ReadSettingState readSetting,
    required int readMode,
    required bool Function() canTick,
    required AutoReadTickCallback onTick,
  }) {
    _canTick = canTick;
    _onTick = onTick;

    final enabled = readSetting.autoScroll;
    final smooth = readMode == 0 && readSetting.autoScrollSmooth;
    final intervalMs = _resolveIntervalMs(
      readSetting: readSetting,
      readMode: readMode,
    );
    final wasEnabled = _lastEnabled;
    final configChanged =
        _lastEnabled != enabled ||
        _lastIntervalMs != intervalMs ||
        _lastReadMode != readMode ||
        _lastSmooth != smooth;

    _lastEnabled = enabled;
    _lastIntervalMs = intervalMs;
    _lastReadMode = readMode;
    _lastSmooth = smooth;

    if (!enabled) {
      _stop();
      return;
    }

    if (!wasEnabled) {
      _isPaused = false;
    }

    if (_isPaused) {
      _stop();
      return;
    }

    if (configChanged || !_isActive) {
      _start(smooth: smooth, intervalMs: intervalMs);
    }
  }

  /// 切换暂停/继续，不改动用户设置项本身。
  void togglePaused({
    required ReadSettingState readSetting,
    required int readMode,
    required bool Function() canTick,
    required AutoReadTickCallback onTick,
  }) {
    _canTick = canTick;
    _onTick = onTick;
    _isPaused = !_isPaused;

    if (_isPaused) {
      _stop();
      return;
    }

    final smooth = readMode == 0 && readSetting.autoScrollSmooth;
    final intervalMs = _resolveIntervalMs(
      readSetting: readSetting,
      readMode: readMode,
    );
    _start(smooth: smooth, intervalMs: intervalMs);
  }

  bool get _isActive => (_timer?.isActive ?? false) || _smoothRunning;

  int _resolveIntervalMs({
    required ReadSettingState readSetting,
    required int readMode,
  }) {
    // 上下限与设置页滑块保持一致。
    return readMode == 0
        ? readSetting.autoScrollColumnIntervalMs.clamp(300, 5000)
        : readSetting.autoScrollPageIntervalMs.clamp(800, 10000);
  }

  void _start({required bool smooth, required int intervalMs}) {
    _stop();
    if (smooth) {
      _smoothRunning = true;
      _lastFrameTimestamp = null;
      _scheduleSmoothFrame();
    } else {
      _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
        if (!(_canTick?.call() ?? false)) return;
        _onTick?.call();
      });
    }
  }

  void _scheduleSmoothFrame() {
    if (!_smoothRunning || _isPaused) return;

    SchedulerBinding.instance.scheduleFrameCallback((timestamp) {
      if (!_smoothRunning || _isPaused) return;

      final last = _lastFrameTimestamp;
      _lastFrameTimestamp = timestamp;

      if (last != null && (_canTick?.call() ?? false)) {
        final dtMs = (timestamp - last).inMicroseconds / 1000.0;
        if (dtMs > 0) {
          _onTick?.call(deltaMs: math.min(dtMs, _maxSmoothDeltaMs));
        }
      }

      if (_smoothRunning && !_isPaused) {
        SchedulerBinding.instance.scheduleFrame();
        _scheduleSmoothFrame();
      }
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _smoothRunning = false;
    _lastFrameTimestamp = null;
  }

  void dispose() {
    _stop();
  }
}
