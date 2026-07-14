import 'dart:async';
import 'dart:io';

import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/comic_read/controller/reader_action_controller.dart';
import 'package:zephyr/service/reader/reader_volume_service.dart';

class ReaderVolumeController {
  late ReaderActionController actionController;
  final _service = ReaderVolumeService.instance;
  StreamSubscription<String>? _subscription;

  ReaderVolumeController();

  void setActionController(ReaderActionController controller) {
    actionController = controller;
  }

  void listen() {
    _subscription?.cancel();
    if (!Platform.isAndroid) return;
    _subscription = _service.volumeEvents.listen(_handleEvent);
  }

  void dispose() {
    _service.dispose();
    _subscription?.cancel();
  }

  /// 根据设置和菜单状态同步是否拦截音量键。
  void sync(ReadSettingState readSetting, bool isMenuVisible) {
    final shouldEnable = readSetting.volumeKeyPageTurn && !isMenuVisible;
    if (shouldEnable) {
      enableInterception();
    } else {
      disableInterception();
    }
  }

  void enableInterception() => _service.enableInterception();

  void disableInterception() => _service.disableInterception();

  void _handleEvent(String event) {
    if (event == 'volume_down') {
      actionController.onVolumeActionNext();
    } else if (event == 'volume_up') {
      actionController.onVolumeActionPrev();
    }
  }
}
