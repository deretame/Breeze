import 'dart:async';
import 'dart:io';

import 'package:zephyr/page/comic_read/controller/reader_action_controller.dart';
import 'package:zephyr/util/volume_key_handler.dart';

class ReaderVolumeController {
  final ReaderActionController actionController;
  StreamSubscription<String>? _subscription;
  bool _isInterceptionEnabled = false;

  ReaderVolumeController({required this.actionController});

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
      actionController.onPageActionNext();
    } else if (event == 'volume_up') {
      actionController.onPageActionPrev();
    }
  }
}
