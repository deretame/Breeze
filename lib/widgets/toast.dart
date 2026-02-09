import 'package:flutter/cupertino.dart';
import 'package:toastification/toastification.dart';

import '../main.dart';

enum ToastType { info, success, warning, error }

void _showToastification({
  required BuildContext context,
  String? title,
  required String message,
  required ToastificationType type,
  required Duration duration,
}) {
  toastification.show(
    context: context,
    title: title == null ? null : Text(title),
    description: Text(message),
    type: type,
    style: ToastificationStyle.flatColored,
    autoCloseDuration: duration,
    showProgressBar: true,
  );
}

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
    _showToastification(
      context: context,
      title: title,
      message: message,
      type: ToastificationType.info,
      duration: duration,
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
    _showToastification(
      context: context,
      title: title,
      message: message,
      type: ToastificationType.success,
      duration: duration,
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
    _showToastification(
      context: context,
      title: title,
      message: message,
      type: ToastificationType.warning,
      duration: duration,
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
    _showToastification(
      context: context,
      title: title,
      message: message,
      type: ToastificationType.error,
      duration: duration,
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
