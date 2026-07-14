import 'dart:async';
import 'dart:io';

import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/comic_read/controller/reader_action_controller.dart';
import 'package:zephyr/util/volume_key_handler.dart';

class ReaderVolumeController {
  late ReaderActionController actionController;
  StreamSubscription<String>? _subscription;
  bool _isInterceptionEnabled = false;

  ReaderVolumeController();

  void setActionController(ReaderActionController controller) {
    actionController = controller;
  }

  void listen() {
    if (!Platform.isAndroid) return;
    _subscription?.cancel();
    _subscription = VolumeKeyHandler.volumeKeyEvents.listen(_handleEvent);
  }

  void dispose() {
    if (!Platform.isAndroid) return;
    disableInterception();
    _subscription?.cancel();
  }

  /// 根据设置和菜单状态同步是否拦截音量键。
  void sync(ReadSettingState readSetting, bool isMenuVisible) {
    if (!Platform.isAndroid) return;
    final shouldEnable = readSetting.volumeKeyPageTurn && !isMenuVisible;
    if (shouldEnable) {
      enableInterception();
    } else {
      disableInterception();
    }
  }

  void enableInterception() {
    if (!Platform.isAndroid) return;
    if (!_isInterceptionEnabled) {
      VolumeKeyHandler.enableVolumeKeyInterception();
      _isInterceptionEnabled = true;
    }
  }

  void disableInterception() {
    if (!Platform.isAndroid) return;
    if (_isInterceptionEnabled) {
      VolumeKeyHandler.disableVolumeKeyInterception();
      _isInterceptionEnabled = false;
    }
  }

  void _handleEvent(String event) {
    if (event == 'volume_down') {
      actionController.onVolumeActionNext();
    } else if (event == 'volume_up') {
      actionController.onVolumeActionPrev();
    }
  }
}
