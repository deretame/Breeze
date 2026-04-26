import 'dart:async';

import 'package:zephyr/main.dart';
import 'package:zephyr/util/event/event.dart';

class WebViewObserveBus {
  static Stream<WebViewObserveEvent> get stream =>
      eventBus.on<WebViewObserveEvent>();

  static void emit(WebViewObserveEvent event) {
    eventBus.fire(event);
  }
}
