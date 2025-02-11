import '../main.dart';

enum ToastType { info, success, warning, error }

class ToastEvent {
  ToastType type;
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
      type: ToastType.info,
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
      type: ToastType.success,
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
      type: ToastType.warning,
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
      type: ToastType.error,
      title: title,
      message: message,
      duration: duration,
    ),
  );
}
