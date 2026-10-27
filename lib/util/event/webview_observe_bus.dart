import 'dart:async';

import 'package:zephyr/util/event/event.dart';
import 'package:zephyr/main.dart';

class WebViewObserveBus {
  static Stream<WebViewObserveEvent> get stream =>
      eventBus.on<WebViewObserveEvent>();

  static void emit(WebViewObserveEvent event) {
    eventBus.fire(event);
  }
}
