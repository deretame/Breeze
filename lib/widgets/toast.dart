import 'package:toastification/toastification.dart';

import '../main.dart';

class ToastEvent {
  ToastificationType type;
  String? title;
  String message;
  Duration duration;

  ToastEvent({
    required this.type,
    this.title,
    required this.message,
    required this.duration,
  });
}

void showInfoToast(
  String message, {
  String? title,
  Duration duration = const Duration(seconds: 2),
}) {
  eventBus.fire(
    ToastEvent(
      type: ToastificationType.info,
      title: title,
      message: message,
      duration: duration,
    ),
  );
}

void showSuccessToast(
  String message, {
  String? title,
  Duration duration = const Duration(seconds: 2),
}) {
  eventBus.fire(
    ToastEvent(
      type: ToastificationType.success,
      title: title,
      message: message,
      duration: duration,
    ),
  );
}

void showWarningToast(
  String message, {
  String? title,
  Duration duration = const Duration(seconds: 2),
}) {
  eventBus.fire(
    ToastEvent(
      type: ToastificationType.warning,
      title: title,
      message: message,
      duration: duration,
    ),
  );
}

void showErrorToast(
  String message, {
  String? title,
  Duration duration = const Duration(seconds: 5),
}) {
  eventBus.fire(
    ToastEvent(
      type: ToastificationType.error,
      title: title,
      message: message,
      duration: duration,
    ),
  );
}
