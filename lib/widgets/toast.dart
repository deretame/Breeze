import 'package:flutter/cupertino.dart';
import 'package:toastification/toastification.dart';

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
  BuildContext? context,
}) {
  if (context != null) {
    toastification.show(
      context: context,
      title: title == null ? null : Text(title),
      description: Text(message),
      type: ToastificationType.info,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: duration,
      showProgressBar: true,
    );
    return;
  }

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
  BuildContext? context,
}) {
  if (context != null) {
    toastification.show(
      context: context,
      title: title == null ? null : Text(title),
      description: Text(message),
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: duration,
      showProgressBar: true,
    );
    return;
  }

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
  BuildContext? context,
}) {
  if (context != null) {
    toastification.show(
      context: context,
      title: title == null ? null : Text(title),
      description: Text(message),
      type: ToastificationType.warning,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: duration,
      showProgressBar: true,
    );
    return;
  }

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
  BuildContext? context,
}) {
  if (context != null) {
    toastification.show(
      context: context,
      title: title == null ? null : Text(title),
      description: Text(message),
      type: ToastificationType.error,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: duration,
      showProgressBar: true,
    );
    return;
  }

  eventBus.fire(
    ToastEvent(
      type: ToastType.error,
      title: title,
      message: message,
      duration: duration,
    ),
  );
}
